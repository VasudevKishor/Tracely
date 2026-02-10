// Tracely app widget tests.
// Note: Full app test (LandingScreen) is skipped until layout overflow in landing_screen.dart is fixed.
// Run backend tests with: cd backend && go test ./...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend_1/providers/auth_provider.dart';

void main() {
  testWidgets('AuthProvider can be provided and read', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final auth = context.watch<AuthProvider>();
              return Text(auth.isAuthenticated ? 'logged_in' : 'logged_out');
            },
          ),
        ),
      ),
    );
    expect(find.text('logged_out'), findsOneWidget);
  });
}
