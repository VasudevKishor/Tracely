import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class EnvironmentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _environments = [];
  Map<String, dynamic>? _selectedEnvironment;
  List<dynamic> _variables = []; // For storing variables of the selected env
  bool _isLoading = false;
  String? _error;

  // Getters
  List<dynamic> get environments => _environments;
  Map<String, dynamic>? get selectedEnvironment => _selectedEnvironment;
  List<dynamic> get variables => _variables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all environments for a specific workspace
  Future<void> loadEnvironments(String workspaceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _environments = await _apiService.getEnvironments(workspaceId);
      
      // Optional: Auto-select the first environment if none is selected
      if (_environments.isNotEmpty && _selectedEnvironment == null) {
        _selectedEnvironment = _environments.first;
      }
    } catch (e) {
      _error = 'Error loading environments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects an environment and fetches its specific variables
  /// Selects an environment and fetches its specific variables
  /// Now requires workspaceId to satisfy the ApiService requirements
  void selectEnvironment(String workspaceId, Map<String, dynamic> environment) {
    _selectedEnvironment = environment;
    
    // When an environment is selected, fetch its variables using both IDs
    if (environment['id'] != null) {
      loadVariables(workspaceId, environment['id'].toString());
    }
    notifyListeners();
  }

  /// Fetches variables belonging to a specific environment
  /// Now correctly accepts both positional arguments
  Future<void> loadVariables(String workspaceId, String environmentId) async {
    try {
      final Map<String, dynamic> response = await _apiService.getEnvironmentVariables(
        workspaceId, 
        environmentId
      );

      // Extract the list from the map response
      // Replace 'variables' with 'data' if that's what your Go backend uses
      _variables = response['variables'] ?? []; 
      
      notifyListeners();
    } catch (e) {
      _error = 'Error loading variables: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Creates a new environment
  Future<bool> createEnvironment({
    required String workspaceId,
    required String name,
    required String type, 
    String? description,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createEnvironment(
        workspaceId, 
        name, 
        type, 
        description: description, 
        isActive: isActive
      );
      
      // Extract the environment object from response
      final newEnv = result['environment'] ?? result;
      _environments.add(newEnv);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new variable to the selected environment
  Future<bool> addVariable({
    required String workspaceId,
    required String environmentId,
    required String key,
    required String value,
    required String type,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.addEnvironmentVariable(
        workspaceId, environmentId, key, value, type: type, description: description
      );
      
      // Extract the variable object (adjust key based on your Go response)
      final newVar = result['variable'] ?? result; 
      _variables.add(newVar);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a variable from the selected environment
  Future<bool> deleteVariable(String workspaceId, String environmentId, String variableId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.deleteEnvironmentVariable(workspaceId, environmentId, variableId);
      _variables.removeWhere((v) => v['id'] == variableId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears data on logout or workspace switch
  void clear() {
    _environments = [];
    _selectedEnvironment = null;
    _variables = [];
    _error = null;
    notifyListeners();
  }
}