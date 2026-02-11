import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracely/core/config/env_config.dart';

class ApiService {
  static String get baseUrl => EnvConfig.baseUrl;

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // ─── Token Management ──────────────────────────────────────

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    debugPrint('[ApiService] Tokens loaded. Has access: ${_accessToken != null}');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    debugPrint('[ApiService] Tokens saved.');
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    debugPrint('[ApiService] Tokens cleared.');
  }

  // ─── Token Refresh ─────────────────────────────────────────

  /// Try to get a new access token using the stored refresh token.
  /// Returns true if the refresh was successful; false if we must re-login.
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;

    _isRefreshing = true;
    try {
      debugPrint('[ApiService] Attempting token refresh...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': _refreshToken}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        final newAccess = data['access_token'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          _accessToken = newAccess;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', newAccess);
          debugPrint('[ApiService] Token refreshed successfully.');
          return true;
        }
      }
      debugPrint('[ApiService] Token refresh failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('[ApiService] Token refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ─── Generic Helpers ───────────────────────────────────────

  Map<String, String> _headers({bool auth = true}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth && _accessToken != null) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    return h;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) return decoded;
          return {'data': decoded};
        } catch (_) {
          return {'raw': response.body};
        }
      }
      return {'success': true};
    }
    // For non-401 errors, parse and throw immediately
    try {
      final error = json.decode(response.body);
      throw Exception(
          error['error'] ?? error['message'] ?? 'Request failed (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Request failed: ${response.statusCode}');
    }
  }

  /// Execute an HTTP request with automatic 401 retry after token refresh.
  Future<http.Response> _executeWithRetry(
      Future<http.Response> Function() makeRequest) async {
    final response = await makeRequest();
    if (response.statusCode == 401) {
      // Attempt token refresh, then retry once
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return makeRequest(); // retry with new token
      }
      // Refresh failed — force re-login
      await clearTokens();
      throw Exception('Session expired – please sign in again');
    }
    return response;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _executeWithRetry(
      () => http.get(Uri.parse('$baseUrl$path'), headers: _headers()),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    request() => http.post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(auth: auth),
          body: body != null ? json.encode(body) : null,
        );
    final response = auth
        ? await _executeWithRetry(request)
        : await request();
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(String path,
      {Map<String, dynamic>? body}) async {
    final response = await _executeWithRetry(
      () => http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: body != null ? json.encode(body) : null,
      ),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await _executeWithRetry(
      () => http.delete(Uri.parse('$baseUrl$path'), headers: _headers()),
    );
    return _handleResponse(response);
  }

  // ─── Authentication ────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access != null && refresh != null) {
      await saveTokens(access, refresh);
    } else {
      // Fallback: some backends return just "token"
      final fallback = data['token'] as String?;
      if (fallback != null) {
        await saveTokens(fallback, fallback);
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    final data = await _post(
      '/auth/register',
      body: {'email': email, 'password': password, 'name': name},
      auth: false,
    );
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access != null && refresh != null) {
      await saveTokens(access, refresh);
    } else {
      final fallback = data['token'] as String?;
      if (fallback != null) {
        await saveTokens(fallback, fallback);
      }
    }
    return data;
  }

  Future<void> logout() async {
    try {
      await _post('/auth/logout');
    } finally {
      await clearTokens();
    }
  }

  // ─── Workspaces ────────────────────────────────────────────

  Future<List<dynamic>> getWorkspaces() async {
    final data = await _get('/workspaces');
    return (data['workspaces'] ?? data['data'] ?? []) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createWorkspace(
      String name, String description) async {
    return _post('/workspaces', body: {
      'name': name,
      'description': description,
    });
  }

  Future<Map<String, dynamic>> getWorkspace(String workspaceId) async {
    return _get('/workspaces/$workspaceId');
  }

  Future<Map<String, dynamic>> updateWorkspace(
      String workspaceId, String name, String description) async {
    return _put('/workspaces/$workspaceId', body: {
      'name': name,
      'description': description,
    });
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    await _delete('/workspaces/$workspaceId');
  }

  // ─── Collections ───────────────────────────────────────────

  Future<List<dynamic>> getCollections(String workspaceId) async {
    final data = await _get('/workspaces/$workspaceId/collections');
    return (data['collections'] ?? data['data'] ?? []) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCollection(
      String workspaceId, String name, String description) async {
    return _post('/workspaces/$workspaceId/collections', body: {
      'name': name,
      'description': description,
    });
  }

  Future<Map<String, dynamic>> getCollection(
      String workspaceId, String collectionId) async {
    return _get('/workspaces/$workspaceId/collections/$collectionId');
  }

  // ─── Requests ──────────────────────────────────────────────

  Future<Map<String, dynamic>> createRequest(
      String workspaceId,
      String collectionId,
      Map<String, dynamic> requestData) async {
    return _post(
      '/workspaces/$workspaceId/collections/$collectionId/requests',
      body: requestData,
    );
  }

  Future<Map<String, dynamic>> executeRequest(
      String workspaceId, String requestId,
      {String? traceId}) async {
    return _post(
      '/workspaces/$workspaceId/requests/$requestId/execute',
      body: traceId != null ? {'trace_id': traceId} : {},
    );
  }

  Future<Map<String, dynamic>> getRequestHistory(
      String workspaceId, String requestId,
      {int limit = 50, int offset = 0}) async {
    return _get(
      '/workspaces/$workspaceId/requests/$requestId/history?limit=$limit&offset=$offset',
    );
  }

  // ─── Traces ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTraces(String workspaceId,
      {String? serviceName, int limit = 50, int offset = 0}) async {
    var path = '/workspaces/$workspaceId/traces?limit=$limit&offset=$offset';
    if (serviceName != null) path += '&service_name=$serviceName';
    return _get(path);
  }

  Future<Map<String, dynamic>> getTraceDetails(
      String workspaceId, String traceId) async {
    return _get('/workspaces/$workspaceId/traces/$traceId');
  }

  // ─── Monitoring ────────────────────────────────────────────

  Future<Map<String, dynamic>> getMonitoringDashboard(String workspaceId,
      {String timeRange = 'last_hour'}) async {
    return _get(
      '/workspaces/$workspaceId/monitoring/dashboard?time_range=$timeRange',
    );
  }

  // ─── Governance ────────────────────────────────────────────

  Future<Map<String, dynamic>> getGovernancePolicies(
      String workspaceId) async {
    return _get('/workspaces/$workspaceId/governance/policies');
  }

  // ─── User Settings ────────────────────────────────────────

  Future<Map<String, dynamic>> getUserSettings() async {
    return _get('/users/settings');
  }

  Future<Map<String, dynamic>> updateUserSettings(
      Map<String, dynamic> settings) async {
    return _put('/users/settings', body: settings);
  }
}
