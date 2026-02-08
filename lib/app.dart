import 'package:flutter/material.dart';
import 'package:tracely/screens/home/home_screen.dart';
import 'package:tracely/screens/alerts/alerts_screen.dart';
import 'package:tracely/screens/traces/traces_screen.dart';
import 'package:tracely/screens/tests/tests_screen.dart';
import 'package:tracely/screens/settings/settings_screen.dart';
import 'package:tracely/core/widgets/main_scaffold.dart';

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
