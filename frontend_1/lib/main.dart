import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/workspaces_screen.dart';
import 'screens/request_studio_screen.dart';
import 'screens/collections_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/governance_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const TracelyApp());
}

class TracelyApp extends StatelessWidget {
  const TracelyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracely',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.light(
          primary: Colors.grey.shade900,
          secondary: Colors.grey.shade700,
          surface: Colors.white,
        ),
      ),
      home: const TracelyMainScreen(),
    );
  }
}

class TracelyMainScreen extends StatefulWidget {
  const TracelyMainScreen({Key? key}) : super(key: key);

  @override
  State<TracelyMainScreen> createState() => _TracelyMainScreenState();
}

class _TracelyMainScreenState extends State<TracelyMainScreen> {
  int _currentScreen = 0;

  final List<Widget> _screens = [
    const LandingScreen(),
    const AuthScreen(),
    const HomeScreen(),
    const WorkspacesScreen(),
    const RequestStudioScreen(),
    const CollectionsScreen(),
    const MonitoringScreen(),
    const GovernanceScreen(),
    const SettingsScreen(),
  ];

  final List<String> _screenNames = [
    'LANDING',
    'AUTH',
    'HOME',
    'WORKSPACES',
    'STUDIO',
    'COLLECTIONS',
    'MONITORING',
    'GOVERNANCE',
    'SETTINGS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentScreen],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WIREFRAME NAVIGATION:',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ...List.generate(_screenNames.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _currentScreen = index;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: _currentScreen == index
                              ? Colors.white
                              : Colors.transparent,
                          foregroundColor: _currentScreen == index
                              ? Colors.grey.shade900
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _screenNames[index],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}