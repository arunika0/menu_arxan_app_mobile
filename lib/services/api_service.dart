import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://menu.arxan.app/api';
  final String? token;

  ApiService({this.token});

  Future<Map<String, String>> get _headers async {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Menu Items
  Future<List<dynamic>> getMenuItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menu'),
        headers: await _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('API Response: ${response.body}'); // Debug print
        return data;
      }
      throw Exception('Failed to load menu items: ${response.statusCode}');
    } catch (e) {
      print('Error in getMenuItems: $e'); // Debug print
      rethrow;
    }
  }

  Future<dynamic> createMenuItem(Map<String, dynamic> formData, File? imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/menu');
      var request = http.MultipartRequest('POST', uri);
      
      // Add form fields
      request.fields['name'] = formData['name'].toString();
      request.fields['price'] = formData['price'].toString();
      request.fields['description'] = formData['description'].toString();
      request.fields['category_id'] = formData['category_id'].toString();

      // Add image if available
      if (imageFile != null) {
        print('Adding image file: ${imageFile.path}');
        var mime = imageFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
        var file = await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mime),
        );
        request.files.add(file);
        print('File added to request: ${file.filename}');
      }
      
      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('Sending request to: $uri');
      print('Form fields: ${request.fields}');
      print('Files: ${request.files.map((f) => f.filename).toList()}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        // If image is null in response but we uploaded one, add the uploaded image URL
        if (responseData['image'] == null && imageFile != null) {
          responseData['image'] = formData['image']; // Use the uploaded image URL
        }
        print('Final response data: $responseData');
        return responseData;
      }
      throw Exception('Failed to create menu item: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error in createMenuItem: $e');
      rethrow;
    }
  }

  Future<dynamic> updateMenuItem(int id, Map<String, dynamic> formData, File? imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/menu/$id');
      var request = http.MultipartRequest('PUT', uri);
      
      // Add form fields
      request.fields['name'] = formData['name'].toString();
      request.fields['price'] = formData['price'].toString();
      request.fields['description'] = formData['description'].toString();
      request.fields['category_id'] = formData['category_id'].toString();

      // Add image if available
      if (imageFile != null) {
        print('Adding image file: ${imageFile.path}');
        var mime = imageFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mime),
          ),
        );
      }
      
      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('Sending request to: $uri');
      print('Form fields: ${request.fields}');
      print('Files: ${request.files}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed response: $responseData');
        return responseData;
      }
      throw Exception('Failed to update menu item: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error in updateMenuItem: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/$id'),
      headers: await _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete menu item');
    }
  }

  // Categories
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load categories');
  }

  Future<dynamic> createCategory(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers,
      body: json.encode({'name': name}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create category');
  }

  Future<dynamic> updateCategory(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers,
      body: json.encode({'name': name}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update category');
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to login');
  }

  // Image Upload
  Future<String> uploadImage(File imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/upload');
      var request = http.MultipartRequest('POST', uri);
      
      // Add the file with correct mime type
      var mime = imageFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mime),
        ),
      );
      
      // Add headers including token
      if (token != null) {
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
      }

      print('Uploading image to: $uri'); // Debug print
      print('Headers: ${request.headers}'); // Debug print
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Upload response status: ${response.statusCode}'); // Debug print
      print('Upload response body: ${response.body}'); // Debug print

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        if (data['imageUrl'] != null) {
          return data['imageUrl'];
        }
        throw Exception('Invalid response format: missing imageUrl');
      }
      throw Exception('Failed to upload image: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error in uploadImage: $e'); // Debug print
      rethrow;
    }
  }
}
