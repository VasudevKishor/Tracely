import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TraceProvider with ChangeNotifier {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _traces = [];
  
  List<Map<String, dynamic>> get traces => _traces;
  
  Future<void> fetchTraces(String workspaceId) async {
    final response = await _apiService.getTraces(workspaceId);
    _traces = List<Map<String, dynamic>>.from(response);
    notifyListeners();
  }
  
  Future<Map<String, dynamic>> getTraceDetails(String workspaceId, String traceId) async {
    return await _apiService.getTraceDetails(workspaceId, traceId);
  }
}