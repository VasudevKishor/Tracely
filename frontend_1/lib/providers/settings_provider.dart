import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _settings;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _apiService.getSettings();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    _isLoading = true; // Add this
    _error = null;
    notifyListeners(); // Notify UI to show "Saving..." state

    try {
      _settings = await _apiService.updateSettings(newSettings);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false; 
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _settings = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
