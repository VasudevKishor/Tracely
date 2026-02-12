import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Add these enums at the top of the file
enum WorkspaceType { internal, partner }
enum AccessType { teamOnly, inviteOnly }

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
        _selectedWorkspaceId = _workspaces[0]['id'].toString();
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

  void setSelectedWorkspace(Map<String, dynamic> workspace) {
    _selectedWorkspaceId = workspace['id'];
    notifyListeners();
  }
  
  // Enhanced createWorkspace method for multi-step form
  Future<bool> createWorkspace({
    required String name,
    required WorkspaceType type,
    required bool isPublic,
    required AccessType accessType,
    String? description,
  }) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();
      
      // Convert enums to string values
      final typeString = type == WorkspaceType.internal ? 'internal' : 'partner';
      final accessString = accessType == AccessType.teamOnly ? 'team' : 'invite';
      
      // Call the updated API method
      final workspace = await _apiService.createWorkspace(
        name,
        description: description,
        type: typeString,
        isPublic: isPublic,
        accessType: accessString,
      );
      
      // Add to workspaces list
      _workspaces.add(workspace);
      
      // Auto-select the newly created workspace
      _selectedWorkspaceId = workspace['id'].toString();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Keep the simple version for backward compatibility
  Future<bool> createSimpleWorkspace(String name, {String? description}) async {
    return await createWorkspace(
      name: name,
      type: WorkspaceType.internal,
      isPublic: false,
      accessType: AccessType.teamOnly,
      description: description,
    );
  }
  
  Future<bool> updateWorkspace(String workspaceId, String name, {String? description}) async {
    try {
      _errorMessage = null;
      _isLoading = true;
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
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteWorkspace(String workspaceId) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();
      
      await _apiService.deleteWorkspace(workspaceId);
      
      // Remove from local list
      _workspaces.removeWhere((w) => w['id'].toString() == workspaceId.toString());
      
      // If deleted workspace was selected, select first available or null
      if (_selectedWorkspaceId == workspaceId) {
        _selectedWorkspaceId = _workspaces.isNotEmpty ? _workspaces[0]['id'].toString() : null;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize workspace with template defaults
  Future<bool> initializeWorkspace({
    required int templateId,
    required String name,
    String? description,
  }) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      // Use the new initializeWorkspace API method
      final workspace = await _apiService.initializeWorkspace(
        name,
        description: description,
        templateId: templateId,
      );

      // Add to workspaces list and set as selected
      _workspaces.add(workspace);
      _selectedWorkspaceId = workspace['id'].toString();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
