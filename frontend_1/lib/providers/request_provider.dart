// request_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class RequestProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _lastResponse;
  Map<String, dynamic>? _lastRequest;
  String? _error;
  List<Map<String, dynamic>> _history = [];
  
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get lastResponse => _lastResponse;
  Map<String, dynamic>? get lastRequest => _lastRequest;
  String? get error => _error;
  List<Map<String, dynamic>> get history => _history;
  
  // Execute API request
  Future<Map<String, dynamic>> executeRequest({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    String? workspaceId,
    String? collectionId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Prepare request data
      final requestData = {
        'method': method,
        'url': url,
        'body': body,
        'headers': headers ?? {},
        'query_params': queryParams ?? {},
        'workspace_id': workspaceId,
        'collection_id': collectionId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _lastRequest = requestData;
      
      // Add to history
      _history.insert(0, {
        ...requestData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      // Limit history to 50 items
      if (_history.length > 50) {
        _history = _history.sublist(0, 50);
      }
      
      // Execute the HTTP request
      http.Response response;
      
      // Build the full URL with query parameters
      String finalUrl = url;
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        final queryParameters = Map<String, String>.from(
          queryParams.map((key, value) => MapEntry(key, value.toString()))
        );
        finalUrl = uri.replace(queryParameters: queryParameters).toString();
      }
      
      // Prepare request body
      String? requestBody;
      if (body != null) {
        requestBody = json.encode(body);
      }
      
      // Prepare headers
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };
      
      // Add authorization header if available
      if (_apiService.accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer ${_apiService.accessToken}';
      }
      
      // Execute based on method
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(
            Uri.parse(finalUrl),
            headers: requestHeaders,
          );
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(finalUrl),
            headers: requestHeaders,
            body: requestBody,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(finalUrl),
            headers: requestHeaders,
            body: requestBody,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(finalUrl),
            headers: requestHeaders,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            Uri.parse(finalUrl),
            headers: requestHeaders,
            body: requestBody,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      // Parse response
      Map<String, dynamic> responseData = {};
      
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = {
            'body': response.body,
            'is_raw': true,
          };
        }
      }
      
      final responseInfo = {
        'status': response.statusCode,
        'status_text': _getStatusText(response.statusCode),
        'headers': response.headers,
        'body': responseData,
        'size': response.contentLength ?? response.body.length,
        'time': DateTime.now().toIso8601String(),
      };
      
      _lastResponse = responseInfo;
      
      // Save to backend if workspace and collection are provided
      if (workspaceId != null && collectionId != null) {
        try {
          await _apiService.createRequest(
            workspaceId,
            collectionId,
            {
              'method': method,
              'url': url,
              'body': body,
              'headers': headers ?? {},
              'query_params': queryParams ?? {},
              'response': responseInfo,
              'name': _generateRequestName(url),
            },
          );
        } catch (e) {
          // Log but don't fail the request
          print('Failed to save request to backend: $e');
        }
      }
      
      notifyListeners();
      return responseInfo;
      
    } catch (e) {
      _error = e.toString();
      _lastResponse = {
        'status': 0,
        'status_text': 'Error',
        'error': e.toString(),
        'time': DateTime.now().toIso8601String(),
      };
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  String _getStatusText(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return 'OK';
    if (statusCode >= 300 && statusCode < 400) return 'Redirect';
    if (statusCode >= 400 && statusCode < 500) return 'Client Error';
    if (statusCode >= 500) return 'Server Error';
    return 'Unknown';
  }
  
  String _generateRequestName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.isNotEmpty) {
        final segments = path.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return segments.last;
        }
      }
      return 'Request to ${uri.host}';
    } catch (e) {
      return 'Untitled Request';
    }
  }
  
  // Clear last response
  void clearResponse() {
    _lastResponse = null;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
  
  // Remove from history
  void removeFromHistory(String id) {
    _history.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }
}