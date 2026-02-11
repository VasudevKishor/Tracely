import 'package:flutter/foundation.dart';
import 'package:tracely/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _authenticated = false;
  bool _loaded = false;

  bool get isAuthenticated => _authenticated;
  bool get isLoaded => _loaded;

  Future<void> loadAuth() async {
    await ApiService().loadTokens();
    _authenticated = ApiService().isAuthenticated;
    _loaded = true;
    notifyListeners();
  }

  void setAuthenticated(bool value) {
    _authenticated = value;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService().logout();
    _authenticated = false;
    notifyListeners();
  }
}
