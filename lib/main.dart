import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:tracely/app.dart';
import 'package:tracely/core/theme/app_theme.dart';
import 'package:tracely/core/providers/app_providers.dart';
import 'package:tracely/core/providers/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables – wrapped in try/catch so the app
  // still launches even if the file is missing or malformed.
  try {
    await dotenv.load(fileName: 'assets/env.default');
  } catch (e) {
    debugPrint('⚠️ Could not load env.default: $e  (using defaults)');
  }

  runApp(const TracelyApp());
}

class TracelyApp extends StatelessWidget {
  const TracelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: Consumer<ThemeModeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Tracely',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
