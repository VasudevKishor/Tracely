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
  
  Future<bool> addRequestToCollection(String collectionId, Map<String, dynamic> requestData, String workspaceId) async {
    try {
      _errorMessage = null;
      final newRequest = await _apiService.createRequest(workspaceId, collectionId, requestData);
      
      // Update local state
      final index = _collections.indexWhere((c) => c['id'] == collectionId);
      if (index != -1) {
        if (_collections[index]['requests'] == null) {
          _collections[index]['requests'] = [];
        }
        final List<dynamic> requests = _collections[index]['requests'];
        requests.add(newRequest);
        notifyListeners();
      }
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