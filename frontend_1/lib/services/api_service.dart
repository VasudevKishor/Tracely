import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081/api/v1';
  // For Android emulator: 'http://10.0.2.2:8081/api/v1'
  // For iOS simulator: 'http://localhost:8081/api/v1'
  // For real device: 'http://YOUR_IP:8081/api/v1'
  
  String? _accessToken;
  String? _refreshToken;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  
  // Load tokens from storage
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }
  
  // Save tokens to storage
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }
  
  // Clear tokens
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  // Get headers with optional auth
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }
  
  // Generic request handler
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return {'success': true};
    } else if (response.statusCode == 401) {
      await clearTokens();
      throw Exception('Unauthorized - Please login again');
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? error['message'] ?? 'Request failed');
      } catch (_) {
        throw Exception('Request failed: ${response.statusCode}');
      }
    }
  }
  
  // ==================== AUTH ENDPOINTS ====================
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    final data = await _handleResponse(response);
    if (data['access_token'] != null && data['refresh_token'] != null) {
      await saveTokens(data['access_token'], data['refresh_token']);
    }
    return data;
  }
  
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );
    
    return await _handleResponse(response);
  }
  
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );
    } finally {
      await clearTokens();
    }
  }
  
  // ==================== WORKSPACE ENDPOINTS ====================
  
  Future<List<dynamic>> getWorkspaces() async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces'),
      headers: await _getHeaders(),
    );
  
    final data = await _handleResponse(response);
    return data['workspaces'] ?? data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createWorkspace(String name, {String? description}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );
  
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateWorkspace(
    String workspaceId,
    String name,
    {String? description}
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );
  
    return await _handleResponse(response);
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId'),
      headers: await _getHeaders(),
    );
  
    await _handleResponse(response);
  }
  
  // ==================== COLLECTION ENDPOINTS ====================
  
  Future<List<dynamic>> getCollections(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/collections'),
      headers: await _getHeaders(),
    );
    
    final data = await _handleResponse(response);
    return data['collections'] ?? data['data'] ?? [];
  }
  
  Future<Map<String, dynamic>> createCollection(
    String workspaceId, 
    String name, 
    {String? description}
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/collections'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );
    
    return await _handleResponse(response);
  }
  
  // ==================== REQUEST ENDPOINTS ====================
  
  Future<Map<String, dynamic>> executeRequest(
    String workspaceId, 
    String requestId
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/requests/$requestId/execute'),
      headers: await _getHeaders(),
    );
    
    return await _handleResponse(response);
  }
  
  // ==================== MONITORING ENDPOINTS ====================
  
  Future<Map<String, dynamic>> getDashboard(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/monitoring/dashboard'),
      headers: await _getHeaders(),
    );
    
    return await _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getMetrics(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/monitoring/metrics'),
      headers: await _getHeaders(),
    );
    
    return await _handleResponse(response);
  }
  
  // ==================== GOVERNANCE ENDPOINTS ====================
  
  Future<List<dynamic>> getGovernancePolicies(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/governance/policies'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['policies'] ?? data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createGovernancePolicy(
    String workspaceId,
    String name,
    String description,
    String type,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/governance/policies'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        'description': description,
        'type': type,
      }),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateGovernancePolicy(
    String workspaceId,
    String policyId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId/governance/policies/$policyId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteGovernancePolicy(String workspaceId, String policyId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/governance/policies/$policyId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }
  
  // ==================== SETTINGS ENDPOINTS ====================
  
  Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/settings'),
      headers: await _getHeaders(),
    );
    
    return await _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/settings'),
      headers: await _getHeaders(),
      body: json.encode(settings),
    );
    
    return await _handleResponse(response);
  }
}