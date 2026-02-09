import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class EnvironmentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _environments = [];
  Map<String, dynamic>? _selectedEnvironment;
  List<Map<String, dynamic>> _variables = [];
  List<Map<String, dynamic>> _secrets = [];
  
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get environments => _environments;
  Map<String, dynamic>? get selectedEnvironment => _selectedEnvironment;
  List<Map<String, dynamic>> get variables => _variables;
  List<Map<String, dynamic>> get secrets => _secrets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load environments for a workspace
  Future<void> loadEnvironments(String workspaceId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_apiService.accessToken != null)
          'Authorization': 'Bearer ${_apiService.accessToken}',
      };

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/workspaces/$workspaceId/environments'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _environments = List<Map<String, dynamic>>.from(data['environments'] ?? []);
        _error = null;
      } else {
        _error = 'Failed to load environments: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading environments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create environment
  Future<bool> createEnvironment({
    required String workspaceId,
    required String name,
    String type = 'development',
    String? description,
    bool isActive = true,
  }) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_apiService.accessToken != null)
          'Authorization': 'Bearer ${_apiService.accessToken}',
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/workspaces/$workspaceId/environments'),
        headers: headers,
        body: json.encode({
          'name': name,
          'type': type,
          'description': description ?? '',
          'is_active': isActive,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _environments.add(data['environment']);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create environment: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error creating environment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load variables for an environment
  Future<void> loadVariables(String workspaceId, String environmentId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_apiService.accessToken != null)
          'Authorization': 'Bearer ${_apiService.accessToken}',
      };

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/workspaces/$workspaceId/environments/$environmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _variables = List<Map<String, dynamic>>.from(data['variables'] ?? []);
        _secrets = List<Map<String, dynamic>>.from(data['secrets'] ?? []);
        
        // Find and set the selected environment
        _selectedEnvironment = _environments.firstWhere(
          (env) => env['id'] == environmentId,
          orElse: () => {},
        );
        
        _error = null;
      } else {
        _error = 'Failed to load variables: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading variables: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add variable to environment
  Future<bool> addVariable({
    required String workspaceId,
    required String environmentId,
    required String key,
    required String value,
    String type = 'string',
    String? description,
  }) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_apiService.accessToken != null)
          'Authorization': 'Bearer ${_apiService.accessToken}',
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/workspaces/$workspaceId/environments/$environmentId/variables'),
        headers: headers,
        body: json.encode({
          'key': key,
          'value': value,
          'type': type,
          'description': description ?? '',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _variables.add(data['variable']);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to add variable: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error adding variable: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update environment
  Future<bool> updateEnvironment({
    required String workspaceId,
    required String environmentId,
    String? name,
    String? type,
    String? description,
    bool? isActive,
  }) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_apiService.accessToken != null)
          'Authorization': 'Bearer ${_apiService.accessToken}',
      };

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/workspaces/$workspaceId/environments/$environmentId'),
        headers: headers,
        body: json.encode({
          if (name != null) 'name': name,
          if (type != null) 'type': type,
          if (description != null) 'description': description,
          if (isActive != null) 'is_active': isActive,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Update in local list
        final index = _environments.indexWhere((env) => env['id'] == environmentId);
        if (index != -1) {
          _environments[index] = data['environment'];
        }
        
        // Update selected environment if it's the one being updated
        if (_selectedEnvironment != null && _selectedEnvironment!['id'] == environmentId) {
          _selectedEnvironment = data['environment'];
        }
        
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update environment: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating environment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete environment
  Future<bool> deleteEnvironment(String workspaceId, String environmentId) async {
    if (!_apiService.isAuthenticated) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_apiService.accessToken != null)
          'Authorization': 'Bearer ${_apiService.accessToken}',
      };

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/workspaces/$workspaceId/environments/$environmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _environments.removeWhere((env) => env['id'] == environmentId);
        
        if (_selectedEnvironment != null && _selectedEnvironment!['id'] == environmentId) {
          _selectedEnvironment = null;
          _variables.clear();
          _secrets.clear();
        }
        
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete environment: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error deleting environment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Select environment
  Future<void> selectEnvironment(String workspaceId, Map<String, dynamic> environment) async {
    _selectedEnvironment = environment;
    await loadVariables(workspaceId, environment['id']);
    notifyListeners();
  }

  // Clear selected environment
  void clearSelectedEnvironment() {
    _selectedEnvironment = null;
    _variables.clear();
    _secrets.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get environment variable value by key
  String? getVariableValue(String key) {
    final variable = _variables.firstWhere(
      (v) => v['key'] == key,
      orElse: () => {},
    );
    return variable.isNotEmpty ? variable['value'] : null;
  }

  // Get all variables as map
  Map<String, String> getVariablesMap() {
    final Map<String, String> map = {};
    for (var variable in _variables) {
      map[variable['key']] = variable['value'];
    }
    return map;
  }

  // Get all variables including secrets as map
  Map<String, String> getAllVariablesMap() {
    final Map<String, String> map = {};
    
    // Add regular variables
    for (var variable in _variables) {
      map[variable['key']] = variable['value'];
    }
    
    // Add secrets (you might want to handle secrets differently)
    for (var secret in _secrets) {
      map[secret['key']] = secret['value'];
    }
    
    return map;
  }

  // Check if a variable exists
  bool hasVariable(String key) {
    return _variables.any((v) => v['key'] == key);
  }

  // Update variable locally (useful for real-time editing)
  void updateVariableLocally(String key, String value) {
    final index = _variables.indexWhere((v) => v['key'] == key);
    if (index != -1) {
      _variables[index]['value'] = value;
      notifyListeners();
    }
  }

  // Add variable locally (useful for real-time editing)
  void addVariableLocally(String key, String value, {String type = 'string', String description = ''}) {
    _variables.add({
      'key': key,
      'value': value,
      'type': type,
      'description': description,
    });
    notifyListeners();
  }

  // Remove variable locally
  void removeVariableLocally(String key) {
    _variables.removeWhere((v) => v['key'] == key);
    notifyListeners();
  }

  // Reset all data
  void reset() {
    _environments.clear();
    _selectedEnvironment = null;
    _variables.clear();
    _secrets.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}