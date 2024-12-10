// lib/providers/menu_provider.dart
import 'package:flutter/material.dart';
import 'dart:io'; // Add this import
import '../models/menu_item.dart';
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  ApiService _apiService;
  List<MenuItem> _menuItems = [];

  MenuProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  List<MenuItem> get menuItems => _menuItems;

  Future<void> loadMenuItems() async {
    try {
      final items = await _apiService.getMenuItems();
      _menuItems = items.map((json) {
        try {
          return MenuItem.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing menu item: $e');
          print('Problematic JSON: $json');
          return null;
        }
      }).whereType<MenuItem>().toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading menu items: $e');
      _menuItems = []; // Set empty list on error
      notifyListeners();
    }
  }

  void updateToken(String? token) {
    _apiService = ApiService(token: token);
    loadMenuItems(); // Reload data when token changes
  }

  Future<void> addMenuItem(Map<String, dynamic> formData, File? imageFile) async {
    try {
      final json = await _apiService.createMenuItem(formData, imageFile);
      _menuItems.add(MenuItem.fromJson(json));
      notifyListeners();
    } catch (e) {
      print('Error adding menu item: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(int id, Map<String, dynamic> formData, File? imageFile) async {
    try {
      final json = await _apiService.updateMenuItem(id, formData, imageFile);
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = MenuItem.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(int id) async {
    try {
      await _apiService.deleteMenuItem(id);
      _menuItems.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting menu item: $e');
      rethrow;
    }
  }
}
