import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracely/app.dart';
import 'package:tracely/core/theme/app_theme.dart';
import 'package:tracely/core/providers/app_providers.dart';
import 'package:tracely/core/providers/theme_mode_provider.dart';

void main() {
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
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
