import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class GovernanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _policies = [];
  Map<String, dynamic>? _complianceData;
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get policies => _policies;
  Map<String, dynamic>? get complianceData => _complianceData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPolicies(String workspaceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _policies = await _apiService.getGovernancePolicies(workspaceId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPolicy(String workspaceId, String name, String description, String type) async {
    try {
      _errorMessage = null;
      final policy = await _apiService.createGovernancePolicy(workspaceId, name, description, type);
      _policies.add(policy);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePolicy(String workspaceId, String policyId, Map<String, dynamic> updates) async {
    try {
      _errorMessage = null;
      final policy = await _apiService.updateGovernancePolicy(workspaceId, policyId, updates);
      final index = _policies.indexWhere((p) => p['id'] == policyId);
      if (index != -1) {
        _policies[index] = policy;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePolicy(String workspaceId, String policyId) async {
    try {
      _errorMessage = null;
      await _apiService.deleteGovernancePolicy(workspaceId, policyId);
      _policies.removeWhere((p) => p['id'] == policyId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _policies.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
