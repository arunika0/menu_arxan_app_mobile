import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  ApiService _apiService;
  List<Category> _categories = [];

  CategoryProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  List<Category> get categories => _categories;

  void updateToken(String? token) {
    _apiService = ApiService(token: token);
    loadCategories(); // Reload data when token changes
  }

  Future<void> loadCategories() async {
    try {
      final items = await _apiService.getCategories();
      _categories = items.map((json) => Category.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
      rethrow;
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final json = await _apiService.createCategory(name);
      _categories.add(Category.fromJson(json));
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(int id, String name) async {
    try {
      final json = await _apiService.updateCategory(id, name);
      final index = _categories.indexWhere((cat) => cat.id == id);
      if (index != -1) {
        _categories[index] = Category.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _apiService.deleteCategory(id);
      _categories.removeWhere((cat) => cat.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
