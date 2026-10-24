import 'package:flutter/material.dart';
import 'package:task_master/src/models/user.dart';
import 'package:task_master/src/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  
  User? get user => _user;
  ApiService get apiService => _apiService;
  bool get isAuthenticated => _user != null;

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _user = response['user'];
      // The token is now managed internally by ApiService
      notifyListeners();
    } catch (e) {
      // Re-throw the exception to be caught by the UI
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _apiService.register(email, password);
      // No longer automatically signing in.
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _user = null;
    _apiService.clearToken();
    notifyListeners();
  }
}