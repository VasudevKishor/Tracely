import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TraceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _traces = [];
  Map<String, dynamic>? _selectedTrace;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreTraces = true;

  // Getters
  List<Map<String, dynamic>> get traces => _traces;
  Map<String, dynamic>? get selectedTrace => _selectedTrace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreTraces => _hasMoreTraces;

  Future<bool> fetchTraces(String workspaceId, {int page = 1, int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTraces(workspaceId, page: page, limit: limit);
      // Correctly cast the dynamic list to List<Map<String, dynamic>>
      final newTraces = List<Map<String, dynamic>>.from(response['traces'] ?? []);
      // Parse duration to int if it's a string
      for (var trace in newTraces) {
        if (trace['duration'] is String) {
          trace['duration'] = int.tryParse(trace['duration']) ?? 0;
        }
      }
      if (page == 1) {
        _traces = newTraces;
      } else {
        _traces.addAll(newTraces);
      }
      _hasMoreTraces = newTraces.length >= limit;
      return true;
    } catch (e) {
      _error = "Failed to load traces: ${e.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getTraceDetails(String workspaceId, String traceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTrace = await _apiService.getTraceDetails(workspaceId, traceId);
      return _selectedTrace;
    } catch (e) {
      _error = "Failed to load trace details: ${e.toString()}";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _traces = [];
    _selectedTrace = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
