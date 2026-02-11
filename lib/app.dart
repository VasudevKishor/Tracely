import 'package:flutter/material.dart';
import 'package:tracely/screens/home/home_screen.dart';
import 'package:tracely/screens/alerts/alerts_screen.dart';
import 'package:tracely/screens/traces/traces_screen.dart';
import 'package:tracely/screens/tests/tests_screen.dart';
import 'package:tracely/screens/settings/settings_screen.dart';
import 'package:tracely/core/widgets/main_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:tracely/core/providers/auth_provider.dart';
import 'package:tracely/screens/auth/login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isAuthenticated) {
          return LoginScreen(
            onLoginSuccess: () => auth.setAuthenticated(true),
          );
        }
        return const AppShell();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AlertsScreen(),
    TracesScreen(),
    TestsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: _currentIndex,
      onTabChanged: (index) => setState(() => _currentIndex = index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _screens[_currentIndex],
      ),
    );
  }
}
