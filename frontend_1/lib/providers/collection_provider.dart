import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CollectionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _collections = [];
  Map<String, dynamic>? _selectedCollection;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<dynamic> get collections => _collections;
  Map<String, dynamic>? get selectedCollection => _selectedCollection;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadCollections(String workspaceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _collections = await _apiService.getCollections(workspaceId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void selectCollection(Map<String, dynamic> collection) {
    _selectedCollection = collection;
    notifyListeners();
  }
  
  Future<bool> createCollection(String workspaceId, String name, {String? description}) async {
    try {
      _errorMessage = null;
      final collection = await _apiService.createCollection(
        workspaceId,
        name,
        description: description,
      );
      _collections.add(collection);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCollection(String workspaceId, String collectionId, String name, {String? description}) async {
    try {
      _errorMessage = null;
      final collection = await _apiService.updateCollection(workspaceId, collectionId, name, description: description);
      final index = _collections.indexWhere((c) => c['id'] == collectionId);
      if (index != -1) {
        _collections[index] = collection;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCollection(String workspaceId, String collectionId) async {
    try {
      _errorMessage = null;
      await _apiService.deleteCollection(workspaceId, collectionId);
      _collections.removeWhere((c) => c['id'] == collectionId);
      if (_selectedCollection?['id'] == collectionId) {
        _selectedCollection = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCollectionById(String workspaceId, String collectionId) async {
    try {
      _errorMessage = null;
      final collection = await _apiService.getCollectionById(workspaceId, collectionId);
      return collection;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}