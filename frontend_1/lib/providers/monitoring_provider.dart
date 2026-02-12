import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MonitoringProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _metrics;
  Map<String, dynamic>? _topology;

  bool _isDashboardLoading = false;
  bool _isMetricsLoading = false;
  bool _isTopologyLoading = false;
  
  String? _error;

  // Getters
  Map<String, dynamic>? get dashboard => _dashboard;
  Map<String, dynamic>? get metrics => _metrics;
  Map<String, dynamic>? get topology => _topology;
  String? get error => _error;

  bool get isDashboardLoading => _isDashboardLoading;
  bool get isMetricsLoading => _isMetricsLoading;
  bool get isTopologyLoading => _isTopologyLoading;
  bool get isLoading => _isDashboardLoading || _isMetricsLoading || _isTopologyLoading;

  Future<void> loadDashboard(String workspaceId) async {
    _isDashboardLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _apiService.getDashboard(workspaceId);
    } catch (e) {
      _error = "Dashboard failed: ${e.toString()}";
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMetrics(String workspaceId) async {
    _isMetricsLoading = true; // FIXED: Changed from _isDashboardLoading
    _error = null;
    notifyListeners();

    try {
      _metrics = await _apiService.getMetrics(workspaceId);
    } catch (e) {
      _error = "Metrics failed: ${e.toString()}";
    } finally {
      _isMetricsLoading = false; // FIXED: Changed from _isDashboardLoading
      notifyListeners();
    }
  }

  Future<void> loadTopology(String workspaceId) async {
    _isTopologyLoading = true; // FIXED: Changed from _isDashboardLoading
    _error = null;
    notifyListeners();

    try {
      _topology = await _apiService.getTopology(workspaceId);
    } catch (e) {
      _error = "Topology failed: ${e.toString()}";
    } finally {
      _isTopologyLoading = false; // FIXED: Changed from _isDashboardLoading
      notifyListeners();
    }
  }

  void reset() {
    _dashboard = null;
    _metrics = null;
    _topology = null;
    _error = null;
    _isDashboardLoading = false;
    _isMetricsLoading = false;
    _isTopologyLoading = false;
    notifyListeners();
  }
}