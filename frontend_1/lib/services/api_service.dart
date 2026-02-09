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

    // Get access token
    String? get accessToken => _accessToken;

    // Get refresh token
    String? get refreshToken => _refreshToken;
  
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
  // Add this public method to ApiService:
  Future<Map<String, String>> getRequestHeaders({bool includeAuth = true}) async {
    return await _getHeaders(includeAuth: includeAuth);
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

  // In your ApiService class, update the createWorkspace method:

  Future<Map<String, dynamic>> createWorkspace(
    String name, {
    String? description,
    // New optional parameters with defaults
    String? type = 'internal',
    bool isPublic = false,
    String? accessType = 'team',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        if (description != null) 'description': description,
        // Add the new fields
        'type': type,
        'is_public': isPublic,
        'access_type': accessType,
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
  
  Future<Map<String, dynamic>> createRequest(
    String workspaceId,
    String collectionId,
    Map<String, dynamic> requestData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/collections/$collectionId/requests'),
      headers: await _getHeaders(),
      body: json.encode(requestData),
    );
    return _handleResponse(response);
  }

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




// ==================== MONITORING ====================

  Future<Map<String, dynamic>> getTopology(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/monitoring/topology'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

// ==================== TRACING ====================

  Future<List<dynamic>> getTraces(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/traces'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['traces'] ?? data['data'] ?? [];

  }

  Future<Map<String, dynamic>> getTraceDetails(
    String workspaceId,
    String traceId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/traces/$traceId'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

// ==================== REPLAY ENGINE ====================

  Future<Map<String, dynamic>> createReplay(
    String workspaceId,
    Map<String, dynamic> replayData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/replays'),
      headers: await _getHeaders(),
      body: json.encode(replayData),
    );
    return _handleResponse(response);
  }

  Future<void> executeReplay(String workspaceId, String replayId) async {
    await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/replays/$replayId/execute'),
      headers: await _getHeaders(),
    );
  }

// ==================== MOCKS ====================

  Future<List<dynamic>> getMocks(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/mocks'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['mocks'] ?? data['data'] ?? [];

  }

  Future<Map<String, dynamic>> generateMockFromTrace(
    String workspaceId,
    String traceId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/mocks/generate'),
      headers: await _getHeaders(),
      body: json.encode({'trace_id': traceId}),
    );
    return _handleResponse(response);
  }

  Future<void> updateMock(
    String workspaceId,
    String mockId,
    Map<String, dynamic> updates,
  ) async {
    await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId/mocks/$mockId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );
  }

  Future<void> deleteMock(String workspaceId, String mockId) async {
    await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/mocks/$mockId'),
      headers: await _getHeaders(),
    );
  }

// ==================== ENVIRONMENT ENDPOINTS ====================

  Future<List<dynamic>> getEnvironments(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['environments'] ?? data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createEnvironment(
    String workspaceId,
    String name,
    String type,
    {String? description, bool isActive = true}
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments'),
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        'type': type,
        if (description != null) 'description': description,
        'is_active': isActive,
      }),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getEnvironmentVariables(String workspaceId, String environmentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments/$environmentId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateEnvironment(
    String workspaceId,
    String environmentId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments/$environmentId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteEnvironment(String workspaceId, String environmentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments/$environmentId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> addEnvironmentVariable(
    String workspaceId,
    String environmentId,
    String key,
    String value,
    String type,
    {String? description}
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments/$environmentId/variables'),
      headers: await _getHeaders(),
      body: json.encode({
        'key': key,
        'value': value,
        'type': type,
        if (description != null) 'description': description,
      }),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateEnvironmentVariable(
    String workspaceId,
    String environmentId,
    String variableId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments/$environmentId/variables/$variableId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteEnvironmentVariable(
    String workspaceId,
    String environmentId,
    String variableId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/environments/$environmentId/variables/$variableId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

// ==================== TRACING CONFIG ENDPOINTS ====================

  Future<List<dynamic>> getTracingConfigs(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['configs'] ?? data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createTracingConfig(
    String workspaceId,
    Map<String, dynamic> configData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs'),
      headers: await _getHeaders(),
      body: json.encode(configData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getTracingConfig(String workspaceId, String configId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs/$configId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateTracingConfig(
    String workspaceId,
    String configId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs/$configId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteTracingConfig(String workspaceId, String configId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs/$configId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> toggleTracingConfig(String workspaceId, String configId, bool enabled) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs/$configId/toggle'),
      headers: await _getHeaders(),
      body: json.encode({'enabled': enabled}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> bulkToggleTracingConfigs(
    String workspaceId,
    List<String> serviceNames,
    bool enabled,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/configs/bulk-toggle'),
      headers: await _getHeaders(),
      body: json.encode({
        'service_names': serviceNames,
        'enabled': enabled,
      }),
    );
    return await _handleResponse(response);
  }

  Future<List<dynamic>> getEnabledTracingServices(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/enabled-services'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['enabled_services'] ?? [];
  }

  Future<List<dynamic>> getDisabledTracingServices(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/disabled-services'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['disabled_services'] ?? [];
  }

  Future<Map<String, dynamic>> checkTracingEnabled(String workspaceId, String serviceName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/check?service_name=$serviceName'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getTracingConfigByService(String workspaceId, String serviceName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/tracing/services/$serviceName'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

// ==================== AUTO TRACING CONFIG ENDPOINTS ====================

  Future<List<dynamic>> getAutoTracingConfigs(String workspaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/configs'),
      headers: await _getHeaders(),
    );
    final data = await _handleResponse(response);
    return data['configs'] ?? data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createAutoTracingConfig(
    String workspaceId,
    Map<String, dynamic> configData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/configs'),
      headers: await _getHeaders(),
      body: json.encode(configData),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAutoTracingConfig(String workspaceId, String configId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/configs/$configId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateAutoTracingConfig(
    String workspaceId,
    String configId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/configs/$configId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );
    return await _handleResponse(response);
  }

  Future<void> deleteAutoTracingConfig(String workspaceId, String configId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/configs/$configId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> checkAutoTracingEnabled(String workspaceId, String serviceName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/check?service_name=$serviceName'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAutoTracingConfigByService(String workspaceId, String serviceName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workspaces/$workspaceId/auto-tracing/services/$serviceName'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }
}
