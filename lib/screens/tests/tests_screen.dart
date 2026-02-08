import 'package:flutter/material.dart';
import 'package:tracely/screens/tests/test_details_screen.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  final _runs = [
    _TestRun('API Smoke Tests', true, '2.3s'),
    _TestRun('Auth Flow', false, '1.8s'),
    _TestRun('Payment Gateway', true, '5.1s'),
    _TestRun('User CRUD', true, '3.2s'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Test Runs')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final run = _runs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TestDetailsScreen(run: run),
                      ),
                    ),
                    leading: Icon(
                      run.passed ? Icons.check_circle : Icons.cancel,
                      color: run.passed ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    title: Text(run.name),
                    subtitle: Text(run.duration),
                    trailing: Chip(
                      label: Text(
                        run.passed ? 'Passed' : 'Failed',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: run.passed
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                    ),
                  ),
                );
              },
              childCount: _runs.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _TestRun {
  final String name;
  final bool passed;
  final String duration;

  _TestRun(this.name, this.passed, this.duration);
}
