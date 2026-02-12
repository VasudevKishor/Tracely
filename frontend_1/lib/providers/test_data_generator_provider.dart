import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TestDataGeneratorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _generatedData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get generatedData => _generatedData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> generateTestData(String workspaceId, Map<String, dynamic> generationConfig) async {
    // 1. Reset state before starting new request
    _isLoading = true;
    _error = null;
    _generatedData = null; 
    notifyListeners();

    try {
      // 2. Await the response from your Go backend
      final result = await _apiService.generateTestData(workspaceId, generationConfig);
      _generatedData = result;
      return true;
    } catch (e) {
      // 3. Capture errors (e.g., timeout or invalid schema)
      _error = e.toString();
      return false;
    } finally {
      // 4. Always stop loading, even on failure
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _generatedData = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _generatedData = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}