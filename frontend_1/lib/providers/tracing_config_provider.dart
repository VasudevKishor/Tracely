import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TracingConfigProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _tracingConfigs = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get tracingConfigs => _tracingConfigs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load tracing configs for a workspace
  Future<void> loadTracingConfigs(String workspaceId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final configs = await _apiService.getTracingConfigs(workspaceId);
      _tracingConfigs = configs.cast<Map<String, dynamic>>();
      _error = null;
    } catch (e) {
      _error = 'Error loading tracing configs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create tracing config
  Future<bool> createTracingConfig(String workspaceId, Map<String, dynamic> configData) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createTracingConfig(workspaceId, configData);
      _tracingConfigs.add(result);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error creating tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update tracing config
  Future<bool> updateTracingConfig(String workspaceId, String configId, Map<String, dynamic> updates) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateTracingConfig(workspaceId, configId, updates);
      final index = _tracingConfigs.indexWhere((config) => config['id'] == configId);
      if (index != -1) {
        _tracingConfigs[index] = result;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete tracing config
  Future<bool> deleteTracingConfig(String workspaceId, String configId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteTracingConfig(workspaceId, configId);
      _tracingConfigs.removeWhere((config) => config['id'] == configId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error deleting tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle tracing config
  Future<bool> toggleTracingConfig(String workspaceId, String configId, bool enabled) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.toggleTracingConfig(workspaceId, configId, enabled);
      final index = _tracingConfigs.indexWhere((config) => config['id'] == configId);
      if (index != -1) {
        _tracingConfigs[index] = result;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error toggling tracing config: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Bulk toggle tracing configs
  Future<bool> bulkToggleTracingConfigs(String workspaceId, List<String> serviceNames, bool enabled) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.bulkToggleTracingConfigs(workspaceId, serviceNames, enabled);
      // Reload configs to reflect changes
      await loadTracingConfigs(workspaceId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error bulk toggling tracing configs: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get enabled services
  Future<List<dynamic>> getEnabledTracingServices(String workspaceId) async {
    try {
      return await _apiService.getEnabledTracingServices(workspaceId);
    } catch (e) {
      _error = 'Error getting enabled services: $e';
      notifyListeners();
      return [];
    }
  }

  // Get disabled services
  Future<List<dynamic>> getDisabledTracingServices(String workspaceId) async {
    try {
      return await _apiService.getDisabledTracingServices(workspaceId);
    } catch (e) {
      _error = 'Error getting disabled services: $e';
      notifyListeners();
      return [];
    }
  }

  // Check tracing enabled
  Future<Map<String, dynamic>> checkTracingEnabled(String workspaceId, String serviceName) async {
    try {
      return await _apiService.checkTracingEnabled(workspaceId, serviceName);
    } catch (e) {
      _error = 'Error checking tracing enabled: $e';
      notifyListeners();
      return {};
    }
  }

  // Get tracing config by service
  Future<Map<String, dynamic>> getTracingConfigByService(String workspaceId, String serviceName) async {
    try {
      return await _apiService.getTracingConfigByService(workspaceId, serviceName);
    } catch (e) {
      _error = 'Error getting tracing config by service: $e';
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
    _tracingConfigs.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
