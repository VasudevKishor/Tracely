import 'package:flutter/foundation.dart';
import 'dart:async';
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

  // Properties for request data
  String _method = 'GET';
  String _url = '';
  Map<String, String> _headers = {};
  String _body = '';

  // Getters for request data
  String get method => _method;
  String get url => _url;
  Map<String, String> get headers => _headers;
  String get body => _body;

  Future<Map<String, dynamic>> executeRequest({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    String? workspaceId,
    String? collectionId,
    String? requestId,
    String? overrideUrl,
    Map<String, String>? overrideHeaders,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestTimestamp = DateTime.now();
      Map<String, dynamic> responseInfo;

      // MODE A: Backend Execution (via Go service)
      if (requestId != null && workspaceId != null) {
        responseInfo = await _apiService.executeRequest(
          workspaceId,
          requestId,
          overrideUrl: overrideUrl,
          overrideHeaders: overrideHeaders,
        );
      } 
      // MODE B: Direct Execution (local HTTP)
      else {
        responseInfo = await _apiService.sendDirectRequest(
          method: method,
          url: overrideUrl ?? url,
          body: body,
          headers: headers,
          queryParams: queryParams,
        );
      }

      _lastResponse = responseInfo;
      _lastRequest = {
        'method': method,
        'url': url,
        'timestamp': requestTimestamp.toIso8601String(),
      };

      _addToHistory(_lastRequest!, responseInfo);

      // Auto-save to backend if it's a new request in a collection
      if (workspaceId != null && collectionId != null && requestId == null) {
        // We don't 'await' this so the UI updates immediately
        _saveRequestToBackend(
          workspaceId: workspaceId,
          collectionId: collectionId,
          method: method,
          url: url,
          body: body,
          headers: headers,
          queryParams: queryParams,
          responseInfo: responseInfo,
        );
      }

      return responseInfo;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addToHistory(Map<String, dynamic> req, Map<String, dynamic> res) {
    _history.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'method': req['method'],
      'url': req['url'],
      'status': res['status'],
      'time': res['time'] ?? DateTime.now().toIso8601String(),
    });
    if (_history.length > 50) _history.removeLast();
  }

  Future<void> _saveRequestToBackend({
    required String workspaceId,
    required String collectionId,
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    required Map<String, dynamic> responseInfo,
  }) async {
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
          'name': url.split('/').last.isEmpty ? 'New Request' : url.split('/').last,
        },
      );
    } catch (e) {
      debugPrint('Silent Background Save Failed: $e');
    }
  }

  // Setter methods for request data
  void setMethod(String method) {
    _method = method;
    notifyListeners();
  }

  void setUrl(String url) {
    _url = url;
    notifyListeners();
  }

  void setHeaders(Map<String, String> headers) {
    _headers = headers;
    notifyListeners();
  }

  void setBody(String body) {
    _body = body;
    notifyListeners();
  }

  // Clear all request data
  void clear() {
    _method = 'GET';
    _url = '';
    _headers = {};
    _body = '';
    notifyListeners();
  }

  // Standard cleanup methods
  void clearResponse() { _lastResponse = null; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
  void clearHistory() { _history.clear(); notifyListeners(); }
}