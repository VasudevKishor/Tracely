import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentScreen = 0;

  int get currentScreen => _currentScreen;

  void setScreen(int index) {
    if (_currentScreen != index) {
      _currentScreen = index;
      notifyListeners();
    }
  }

  void navigateTo(String screenName) {
    switch (screenName) {
      case 'LANDING':
        setScreen(0);
        break;
      case 'AUTH':
        setScreen(1);
        break;
      case 'HOME':
        setScreen(2);
        break;
      case 'WORKSPACES':
        setScreen(3);
        break;
      case 'STUDIO':
        setScreen(4);
        break;
      case 'COLLECTIONS':
        setScreen(5);
        break;
      case 'MONITORING':
        setScreen(6);
        break;
      case 'REPLAY':
        setScreen(7);
        break;
      case 'TRACING':
        setScreen(8);
        break;
      case 'GOVERNANCE':
        setScreen(9);
        break;
      case 'SETTINGS':
        setScreen(10);
        break;
    }
  }
}
