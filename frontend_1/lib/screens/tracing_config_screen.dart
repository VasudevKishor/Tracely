import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tracing_config_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/module_shell.dart';

class TracingConfigScreen extends StatefulWidget {
  const TracingConfigScreen({Key? key}) : super(key: key);

  @override
  State<TracingConfigScreen> createState() => _TracingConfigScreenState();
}

class _TracingConfigScreenState extends State<TracingConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTracingConfigs();
    });
  }

  void _loadTracingConfigs() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final tracingConfigProvider = Provider.of<TracingConfigProvider>(context, listen: false);

    if (workspaceProvider.selectedWorkspaceId != null) {
      tracingConfigProvider.loadTracingConfigs(workspaceProvider.selectedWorkspaceId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TracingConfigProvider, WorkspaceProvider>(
      builder: (context, tracingConfigProvider, workspaceProvider, child) {
        return ModuleShell(
          title: 'Tracing Configuration',
          subtitle: 'Configure tracing settings for your services',
          sidebarItems: const [
            'Service Configs',
            'Bulk Operations',
            'Monitoring',
            'Reports',
          ],
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCreateTracingConfigDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141414),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showBulkOperationsDialog(context, tracingConfigProvider),
              icon: const Icon(Icons.settings),
              label: const Text('Bulk Actions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF141414),
                side: const BorderSide(color: Color(0xFF141414)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          sections: [
            _buildOverviewSection(tracingConfigProvider),
            _buildTracingConfigsSection(tracingConfigProvider),
            _buildServiceStatusSection(tracingConfigProvider),
          ],
        );
      },
    );
  }

  Widget _buildOverviewSection(TracingConfigProvider provider) {
    return SectionBlock(
      title: 'Tracing Overview',
      subtitle: 'Monitor and manage tracing configurations across your services',
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.track_changes, color: Colors.blue.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Configurations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '${provider.tracingConfigs.length}',
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enabled Services',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        FutureBuilder<List<dynamic>>(
                          future: provider.getEnabledTracingServices(''),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.hasData ? '${snapshot.data!.length}' : '0',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF141414),
                              ),
                            );
                          },
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

  Widget _buildTracingConfigsSection(TracingConfigProvider provider) {
    return SectionBlock(
      title: 'Service Configurations',
      subtitle: 'Manage tracing settings for individual services',
      children: [
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.tracingConfigs.isEmpty)
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
                Icon(Icons.track_changes, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No tracing configurations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first tracing configuration to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ...provider.tracingConfigs.map((config) => _buildTracingConfigCard(config, provider)),
      ],
    );
  }

  Widget _buildTracingConfigCard(Map<String, dynamic> config, TracingConfigProvider provider) {
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
                  color: (config['enabled'] ?? false) ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: (config['enabled'] ?? false) ? Colors.green.shade600 : Colors.grey.shade600,
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
                  provider.toggleTracingConfig('', config['id'], value);
                },
                activeColor: Colors.green.shade600,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditTracingConfigDialog(context, config);
                      break;
                    case 'delete':
                      _showDeleteTracingConfigDialog(context, config, provider);
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
              _buildConfigChip('Headers', config['log_trace_headers'] ?? true),
              const SizedBox(width: 8),
              _buildConfigChip('Context', config['propagate_context'] ?? true),
              const SizedBox(width: 8),
              _buildConfigChip('Body', config['capture_request_body'] ?? false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatusSection(TracingConfigProvider provider) {
    return SectionBlock(
      title: 'Service Status',
      subtitle: 'Quick overview of tracing status across services',
      children: [
        FutureBuilder<List<dynamic>>(
          future: provider.getEnabledTracingServices(''),
          builder: (context, enabledSnapshot) {
            return FutureBuilder<List<dynamic>>(
              future: provider.getDisabledTracingServices(''),
              builder: (context, disabledSnapshot) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'Enabled Services',
                        enabledSnapshot.data?.length ?? 0,
                        Colors.green.shade600,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatusCard(
                        'Disabled Services',
                        disabledSnapshot.data?.length ?? 0,
                        Colors.grey.shade600,
                        Icons.cancel,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  '$count',
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
    );
  }

  Widget _buildConfigChip(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: enabled ? Colors.blue.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCreateTracingConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTracingConfigDialog(),
    );
  }

  void _showEditTracingConfigDialog(BuildContext context, Map<String, dynamic> config) {
    showDialog(
      context: context,
      builder: (context) => EditTracingConfigDialog(config: config),
    );
  }

  void _showDeleteTracingConfigDialog(BuildContext context, Map<String, dynamic> config, TracingConfigProvider provider) {
    showDialog(
      context: context,
      builder: (context) => DeleteTracingConfigDialog(
        config: config,
        provider: provider,
      ),
    );
  }

  void _showBulkOperationsDialog(BuildContext context, TracingConfigProvider provider) {
    showDialog(
      context: context,
      builder: (context) => BulkOperationsDialog(provider: provider),
    );
  }
}

// Dialog classes
class CreateTracingConfigDialog extends StatelessWidget {
  const CreateTracingConfigDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Tracing Configuration'),
      content: const Text('Tracing configuration creation dialog would go here'),
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

class EditTracingConfigDialog extends StatelessWidget {
  final Map<String, dynamic> config;

  const EditTracingConfigDialog({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Tracing Configuration'),
      content: const Text('Tracing configuration editing dialog would go here'),
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

class DeleteTracingConfigDialog extends StatelessWidget {
  final Map<String, dynamic> config;
  final TracingConfigProvider provider;

  const DeleteTracingConfigDialog({
    Key? key,
    required this.config,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Tracing Configuration'),
      content: Text('Are you sure you want to delete configuration for "${config['service_name']}"?'),
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

class BulkOperationsDialog extends StatelessWidget {
  final TracingConfigProvider provider;

  const BulkOperationsDialog({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Operations'),
      content: const Text('Bulk operations dialog would go here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
