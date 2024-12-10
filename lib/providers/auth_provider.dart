import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import './menu_provider.dart';
import './category_provider.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  int? _restaurantId;
  String? _username;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get role => _role;
  int? get restaurantId => _restaurantId;
  String? get username => _username;

  Future<void> login(String username, String password) async {
    try {
      final ApiService apiService = ApiService();
      final response = await apiService.login(username, password);
      
      _token = response['token'];
      _role = response['role'];
      _restaurantId = response['restaurant_id'];
      _username = username;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('username', username);
      await prefs.setString('role', _role!);
      if (_restaurantId != null) {
        await prefs.setInt('restaurant_id', _restaurantId!);
      }

      // Update token in other providers if navigator context is available
      if (navigatorKey.currentContext != null) {
        Provider.of<MenuProvider>(navigatorKey.currentContext!, listen: false)
            .updateToken(_token);
        Provider.of<CategoryProvider>(navigatorKey.currentContext!, listen: false)
            .updateToken(_token);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _restaurantId = null;
    _username = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return false;

    _token = prefs.getString('token');
    _username = prefs.getString('username');
    _role = prefs.getString('role');
    _restaurantId = prefs.getInt('restaurant_id');

    notifyListeners();
    return true;
  }
}