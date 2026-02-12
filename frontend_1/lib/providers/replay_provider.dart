import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ReplayProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Initialize as empty
  List<Map<String, dynamic>> _replays = [];
  Map<String, dynamic>? _selectedReplay;
  Map<String, dynamic>? _replayResults;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get replays => _replays;
  Map<String, dynamic>? get selectedReplay => _selectedReplay;
  Map<String, dynamic>? get replayResults => _replayResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReplays(String workspaceId) async {
  _setLoading(true);
  try {
    final data = await _apiService.getReplays(workspaceId);
    _replays = List<Map<String, dynamic>>.from(data); 
    _errorMessage = null;
  } catch (e) {
    _errorMessage = "Failed to load replays: ${e.toString()}";
  } finally {
    _setLoading(false);
  }
}

  Future<void> createReplay(String workspaceId, Map<String, dynamic> replayData) async {
    _setLoading(true);
    try {
      await _apiService.createReplay(workspaceId, replayData);
      await fetchReplays(workspaceId); // Refresh list
    } catch (e) {
      _errorMessage = "Creation failed: ${e.toString()}";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> executeReplay(String workspaceId, String replayId) async {
    _setLoading(true);
    try {
      final results = await _apiService.executeReplay(workspaceId, replayId);
      _replayResults = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Execution failed: ${e.toString()}";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteReplay(String workspaceId, String replayId) async {
    try {
      
      _replays.removeWhere((r) => r['id'] == replayId);
      if (_selectedReplay?['id'] == replayId) {
        _selectedReplay = null;
        _replayResults = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = "Delete failed: ${e.toString()}";
      notifyListeners();
    }
  }

  // Helper to reduce boilerplate notifyListeners()
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void selectReplay(Map<String, dynamic> replay) {
    _selectedReplay = replay;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}