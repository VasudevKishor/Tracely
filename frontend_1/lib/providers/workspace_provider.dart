import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WorkspaceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _workspaces = [];
  String? _selectedWorkspaceId;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<dynamic> get workspaces => _workspaces;
  String? get selectedWorkspaceId => _selectedWorkspaceId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  dynamic get selectedWorkspace {
    if (_selectedWorkspaceId == null) return null;
    try {
      return _workspaces.firstWhere((w) => w['id'] == _selectedWorkspaceId);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> loadWorkspaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _workspaces = await _apiService.getWorkspaces();
      if (_workspaces.isNotEmpty && _selectedWorkspaceId == null) {
        _selectedWorkspaceId = _workspaces[0]['id'];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _workspaces = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void selectWorkspace(String workspaceId) {
    _selectedWorkspaceId = workspaceId;
    notifyListeners();
  }
  
  Future<bool> createWorkspace(String name, {String? description}) async {
    try {
      _errorMessage = null;
      notifyListeners();
      
      final workspace = await _apiService.createWorkspace(name, description: description);
      _workspaces.add(workspace);
      
      // Auto-select the newly created workspace
      _selectedWorkspaceId = workspace['id'];
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateWorkspace(String workspaceId, String name, {String? description}) async {
    try {
      _errorMessage = null;
      notifyListeners();
      
      await _apiService.updateWorkspace(workspaceId, name, description: description);
      
      // Update local workspace
      final index = _workspaces.indexWhere((w) => w['id'] == workspaceId);
      if (index != -1) {
        _workspaces[index] = {
          ..._workspaces[index],
          'name': name,
          if (description != null) 'description': description,
        };
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteWorkspace(String workspaceId) async {
    try {
      _errorMessage = null;
      notifyListeners();
      
      await _apiService.deleteWorkspace(workspaceId);
      
      // Remove from local list
      _workspaces.removeWhere((w) => w['id'] == workspaceId);
      
      // If deleted workspace was selected, select first available or null
      if (_selectedWorkspaceId == workspaceId) {
        _selectedWorkspaceId = _workspaces.isNotEmpty ? _workspaces[0]['id'] : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}