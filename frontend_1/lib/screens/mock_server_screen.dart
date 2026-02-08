import 'package:flutter/material.dart';
import '../widgets/module_shell.dart';

class MockServerScreen extends StatelessWidget {
  const MockServerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ModuleShell(
      title: 'Mock Server',
      subtitle: 'Create and manage mock servers for API testing',
      sidebarItems: const [
        'Server Management',
        'Mock Endpoints',
        'Response Templates',
        'Traffic Simulation',
        'Analytics',
      ],
      actions: [
        // Actions would be added here
      ],
      sections: [
        // Mock server sections would be implemented here
      ],
    );
  }
}
