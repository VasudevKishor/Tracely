import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'screens/landing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/workspaces_screen.dart';
import 'screens/request_studio_screen.dart';
import 'screens/collections_screen.dart';
import 'screens/governance_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trace_screen.dart';
import 'screens/replay_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/governance_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/trace_provider.dart';
import 'providers/environment_provider.dart';
import 'providers/replay_provider.dart';
import 'providers/request_provider.dart';
import 'services/api_service.dart';
import 'providers/monitoring_provider.dart';
import 'providers/schema_validator_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/test_data_generator_provider.dart';


void main() async { 
  
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService();
  await apiService.loadTokens();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => GovernanceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TraceProvider()),
        ChangeNotifierProvider(create: (_) => ReplayProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => EnvironmentProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringProvider()),
        ChangeNotifierProvider(create: (_) => SchemaValidatorProvider()),
        ChangeNotifierProvider(create: (_) => TestDataGeneratorProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
    const ReplayScreen(),
    const TracesScreen(),
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
    'REPLAY',
    'TRACING',
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
              child: FloatingActionButton(
                backgroundColor: Colors.green,
                child: const Icon(Icons.cloud_done),
                tooltip: 'Check Backend',
                onPressed: () async {
                // Use the Singleton instance we initialized in main()
                  final apiService = ApiService();

                  // 1. Check if the service has a valid token stored
                  if (!apiService.isAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ You need to login first'),
                        backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                try {
                  // 2. Automatically get headers with the Bearer token
                  final headers = await apiService.getRequestHeaders();

                  // 3. Hit the workspaces endpoint as a health check
                  final response = await http.get(
                    Uri.parse('${ApiService.baseUrl}/workspaces'),
                    headers: headers,
                  );

                  String message;
                  if (response.statusCode == 200) {
                    message = '✅ Backend is reachable & Session is active!';
                  } else if (response.statusCode == 401) {
                    message = '⚠️ Session expired or invalid. Please re-login.';
                  } else {
                    message = '⚠️ Backend error: Status ${response.statusCode}';
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Connection failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            )),

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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: PopupMenuButton<int>(
                        tooltip: 'Open navigation',
                        icon: Icon(Icons.menu, color: Colors.grey.shade300),
                        onSelected: (index) {
                          setState(() {
                            _currentScreen = index;
                          });
                        },
                        itemBuilder: (context) {
                          return List.generate(_screenNames.length, (index) {
                            return PopupMenuItem<int>(
                              value: index,
                              child: Text(_screenNames[index]),
                            );
                          });
                        },
                      ),
                    ),
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
