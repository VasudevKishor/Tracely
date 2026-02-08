import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auto_tracing_config_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/module_shell.dart';

class AutoTracingScreen extends StatefulWidget {
  const AutoTracingScreen({Key? key}) : super(key: key);

  @override
  State<AutoTracingScreen> createState() => _AutoTracingScreenState();
}

class _AutoTracingScreenState extends State<AutoTracingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAutoTracingConfigs();
    });
  }

  void _loadAutoTracingConfigs() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final autoTracingProvider = Provider.of<AutoTracingConfigProvider>(context, listen: false);

    if (workspaceProvider.selectedWorkspaceId != null) {
      autoTracingProvider.loadAutoTracingConfigs(workspaceProvider.selectedWorkspaceId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AutoTracingConfigProvider, WorkspaceProvider>(
      builder: (context, autoTracingProvider, workspaceProvider, child) {
        return ModuleShell(
          title: 'Auto Tracing Configuration',
          subtitle: 'Configure automatic HTTP header injection for distributed tracing',
          sidebarItems: const [
            'Service Configs',
            'Header Injection',
            'Sampling Rules',
            'Monitoring',
            'Reports',
          ],
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCreateAutoTracingConfigDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Auto-Trace Config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141414),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          sections: [
            _buildOverviewSection(autoTracingProvider),
            _buildAutoTracingConfigsSection(autoTracingProvider),
            _buildHeaderInjectionSection(),
          ],
        );
      },
    );
  }

  Widget _buildOverviewSection(AutoTracingConfigProvider provider) {
    return SectionBlock(
      title: 'Auto Tracing Overview',
      subtitle: 'Monitor automatic tracing injection across your services',
      children: [
        Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_fix_high, color: Colors.purple.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Auto-Tracing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '${provider.autoTracingConfigs.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF141414),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.track_changes, color: Colors.orange.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Header Injection',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'Active',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF141414),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoTracingConfigsSection(AutoTracingConfigProvider provider) {
    return SectionBlock(
      title: 'Service Auto-Tracing Configurations',
      subtitle: 'Manage automatic tracing injection for individual services',
      children: [
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.autoTracingConfigs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.auto_fix_high, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No auto-tracing configurations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first auto-tracing configuration to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ...provider.autoTracingConfigs.map((config) => _buildAutoTracingConfigCard(config, provider)),
      ],
    );
  }

  Widget _buildAutoTracingConfigCard(Map<String, dynamic> config, AutoTracingConfigProvider provider) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (config['enabled'] ?? false) ? Colors.purple.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_fix_high,
                  color: (config['enabled'] ?? false) ? Colors.purple.shade600 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config['service_name'] ?? 'Unnamed Service',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF141414),
                      ),
                    ),
                    Text(
                      'Sampling: ${(config['sampling_rate'] ?? 1.0) * 100}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: config['enabled'] ?? false,
                onChanged: (value) {
                  // Toggle functionality would be implemented here
                },
                activeColor: Colors.purple.shade600,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditAutoTracingConfigDialog(context, config);
                      break;
                    case 'delete':
                      _showDeleteAutoTracingConfigDialog(context, config, provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInjectionChip('Trace ID', config['inject_trace_id'] ?? true),
              const SizedBox(width: 8),
              _buildInjectionChip('Span ID', config['inject_span_id'] ?? true),
              const SizedBox(width: 8),
              _buildInjectionChip('Parent Span', config['inject_parent_span_id'] ?? true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInjectionSection() {
    return SectionBlock(
      title: 'Header Injection Settings',
      subtitle: 'Configure which tracing headers are automatically injected',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Standard Tracing Headers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 16),
              _buildHeaderInfo('X-Trace-ID', 'Unique identifier for the entire trace'),
              const SizedBox(height: 12),
              _buildHeaderInfo('X-Span-ID', 'Unique identifier for the current span'),
              const SizedBox(height: 12),
              _buildHeaderInfo('X-Parent-Span-ID', 'Identifier of the parent span'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo(String header, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            header,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInjectionChip(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? Colors.purple.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.purple.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: enabled ? Colors.purple.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCreateAutoTracingConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateAutoTracingConfigDialog(),
    );
  }

  void _showEditAutoTracingConfigDialog(BuildContext context, Map<String, dynamic> config) {
    showDialog(
      context: context,
      builder: (context) => EditAutoTracingConfigDialog(config: config),
    );
  }

  void _showDeleteAutoTracingConfigDialog(BuildContext context, Map<String, dynamic> config, AutoTracingConfigProvider provider) {
    showDialog(
      context: context,
      builder: (context) => DeleteAutoTracingConfigDialog(
        config: config,
        provider: provider,
      ),
    );
  }
}

// Dialog classes
class CreateAutoTracingConfigDialog extends StatelessWidget {
  const CreateAutoTracingConfigDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Auto-Tracing Configuration'),
      content: const Text('Auto-tracing configuration creation dialog would go here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class EditAutoTracingConfigDialog extends StatelessWidget {
  final Map<String, dynamic> config;

  const EditAutoTracingConfigDialog({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Auto-Tracing Configuration'),
      content: const Text('Auto-tracing configuration editing dialog would go here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class DeleteAutoTracingConfigDialog extends StatelessWidget {
  final Map<String, dynamic> config;
  final AutoTracingConfigProvider provider;

  const DeleteAutoTracingConfigDialog({
    Key? key,
    required this.config,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Auto-Tracing Configuration'),
      content: Text('Are you sure you want to delete auto-tracing config for "${config['service_name']}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
