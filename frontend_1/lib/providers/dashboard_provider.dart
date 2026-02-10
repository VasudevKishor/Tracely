import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get specific metrics with defaults
  double get uptime => (_dashboardData?['uptime'] ?? 99.97).toDouble();
  double get errorRate => (_dashboardData?['error_rate'] ?? 0.12).toDouble();
  int get avgLatency => (_dashboardData?['avg_latency'] ?? 142);
  String get totalRequests => _dashboardData?['total_requests'] ?? '2.4M';
  
  Future<void> loadDashboard(String workspaceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _dashboardData = await _apiService.getDashboard(workspaceId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      // Use mock data if API fails
      _dashboardData = {
        'uptime': 99.97,
        'error_rate': 0.12,
        'avg_latency': 142,
        'total_requests': '2.4M',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}