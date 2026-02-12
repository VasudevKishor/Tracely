import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SchemaValidatorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _validationResult;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get validationResult => _validationResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper to manage loading state and notification
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> validateSchema(String workspaceId, Map<String, dynamic> schemaData) async {
    _error = null;
    _validationResult = null; // Clear stale results before starting
    _setLoading(true);

    try {
      // Ensure ApiService returns Map<String, dynamic>
      final result = await _apiService.validateSchema(workspaceId, schemaData);
      _validationResult = result;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false); // Ensures loading stops even if an error occurs
    }
  }

  void reset() {
    _validationResult = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
  
  // Clear specific states if needed
  void clearResult() {
    _validationResult = null;
    notifyListeners();
  }
}