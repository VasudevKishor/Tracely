import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _errorMessage;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    await _apiService.loadTokens();
    _isAuthenticated = _apiService.isAuthenticated;
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      final data = await _apiService.login(email, password);
      _user = {
      'id': data['user_id'],
      'name': data['name'],
      'email': data['email'],
      'token': data['token'], // <-- add token here
    };
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String email, String password, String name) async {
    try {
      _errorMessage = null;
      await _apiService.register(email, password, name);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}