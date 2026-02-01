import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/workspaces_screen.dart';
import 'screens/request_studio_screen.dart';
import 'screens/collections_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/governance_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/governance_provider.dart';
import 'package:http/http.dart' as http;
import 'providers/dashboard_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => GovernanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const TracelyApp(),
    ),
  );
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

          // Add this Floating button at bottom right for backend test
    Positioned(
      bottom: 80,
      right: 16,
      child:  FloatingActionButton(
  backgroundColor: Colors.green,
  child: const Icon(Icons.cloud_done),
  tooltip: 'Check Backend',
  onPressed: () async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ You need to login first')),
      );
      return;
    }

    try {
      final token = authProvider.user!['token']; // get JWT

      final response = await http.get(
        Uri.parse('http://localhost:8081/api/v1/workspaces'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      String message;
      if (response.statusCode == 200) {
        message = '✅ Backend is reachable!';
      } else if (response.statusCode == 401) {
        message = '⚠️ Unauthorized. Please login again.';
      } else {
        message = '⚠️ Backend returned status: ${response.statusCode}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error connecting: $e')),
        );
      }
    }
  },
)

    ),

          // Development navigation bar
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        'WIREFRAME NAV:',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
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
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}