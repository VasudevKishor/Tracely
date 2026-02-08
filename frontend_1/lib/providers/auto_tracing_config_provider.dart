import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AutoTracingConfigProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _autoTracingConfigs = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get autoTracingConfigs => _autoTracingConfigs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load auto-tracing configs for a workspace
  Future<void> loadAutoTracingConfigs(String workspaceId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final configs = await _apiService.getAutoTracingConfigs(workspaceId);
      _autoTracingConfigs = List<Map<String, dynamic>>.from(configs);
      _error = null;
    } catch (e) {
      _error = 'Error loading auto-tracing configs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create auto-tracing config
  Future<bool> createAutoTracingConfig(String workspaceId, Map<String, dynamic> configData) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createAutoTracingConfig(workspaceId, configData);
      _autoTracingConfigs.add(result);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error creating auto-tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update auto-tracing config
  Future<bool> updateAutoTracingConfig(String workspaceId, String configId, Map<String, dynamic> updates) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateAutoTracingConfig(workspaceId, configId, updates);
      final index = _autoTracingConfigs.indexWhere((config) => config['id'] == configId);
      if (index != -1) {
        _autoTracingConfigs[index] = result;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating auto-tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete auto-tracing config
  Future<bool> deleteAutoTracingConfig(String workspaceId, String configId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteAutoTracingConfig(workspaceId, configId);
      _autoTracingConfigs.removeWhere((config) => config['id'] == configId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error deleting auto-tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check auto-tracing enabled
  Future<Map<String, dynamic>> checkAutoTracingEnabled(String workspaceId, String serviceName) async {
    try {
      return await _apiService.checkAutoTracingEnabled(workspaceId, serviceName);
    } catch (e) {
      _error = 'Error checking auto-tracing enabled: $e';
      notifyListeners();
      return {};
    }
  }

  // Get auto-tracing config by service
  Future<Map<String, dynamic>> getAutoTracingConfigByService(String workspaceId, String serviceName) async {
    try {
      return await _apiService.getAutoTracingConfigByService(workspaceId, serviceName);
    } catch (e) {
      _error = 'Error getting auto-tracing config by service: $e';
      notifyListeners();
      return {};
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset
  void reset() {
    _autoTracingConfigs.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
