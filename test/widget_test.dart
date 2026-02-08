import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracely/main.dart';

void main() {
  testWidgets('App loads', (tester) async {
    await tester.pumpWidget(const TracelyApp());
    await tester.pumpAndSettle();
    expect(find.text('Tracely'), findsOneWidget);
  });
}
