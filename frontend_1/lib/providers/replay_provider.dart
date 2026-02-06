import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ReplayProvider with ChangeNotifier {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _replays = [];
  
  List<Map<String, dynamic>> get replays => _replays;
  
  Future<void> fetchReplays(String workspaceId) async {
    _replays = [];
    notifyListeners();
  }
  
  Future<Map<String, dynamic>> createReplay(
    String workspaceId,
    Map<String, dynamic> replayData,
  ) async {
    final response = await _apiService.createReplay(workspaceId, replayData);
    await fetchReplays(workspaceId);
    return response;
  }
  
  Future<void> executeReplay(String workspaceId, String replayId) async {
    await _apiService.executeReplay(workspaceId, replayId);
    notifyListeners();
  }
  
  Future<void> deleteReplay(String workspaceId, String replayId) async {
    _replays.removeWhere((r) => r['id'] == replayId);
    notifyListeners();
  }
}