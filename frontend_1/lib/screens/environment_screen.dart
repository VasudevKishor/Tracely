import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/module_shell.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({Key? key}) : super(key: key);

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnvironments();
    });
  }

  void _loadEnvironments() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final environmentProvider = Provider.of<EnvironmentProvider>(context, listen: false);

    if (workspaceProvider.selectedWorkspaceId != null) {
      environmentProvider.loadEnvironments(workspaceProvider.selectedWorkspaceId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EnvironmentProvider, WorkspaceProvider>(
      builder: (context, environmentProvider, workspaceProvider, child) {
        return ModuleShell(
          title: 'Environment Management',
          subtitle: 'Manage variables and secrets across different environments',
          sidebarItems: const [
            'Overview',
            'Variables',
            'Secrets',
            'Templates',
            'Access Control',
          ],
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCreateEnvironmentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Environment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141414),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          sections: [
            _buildOverviewSection(environmentProvider),
            _buildEnvironmentsSection(environmentProvider),
            _buildVariablesSection(environmentProvider),
          ],
        );
      },
    );
  }

  Widget _buildOverviewSection(EnvironmentProvider provider) {
    return SectionBlock(
      title: 'Environment Overview',
      subtitle: 'Manage your API environments and their configurations',
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
                    child: Icon(Icons.public, color: Colors.blue.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Environments',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '${provider.environments.length}',
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
                    child: Icon(Icons.vpn_key, color: Colors.green.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Variables',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '${provider.variables.length}',
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
      ],
    );
  }

  Widget _buildEnvironmentsSection(EnvironmentProvider provider) {
    return SectionBlock(
      title: 'Environments',
      subtitle: 'Configure different environments for your API testing',
      children: [
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.environments.isEmpty)
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
                Icon(Icons.public_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No environments yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first environment to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ...provider.environments.map((env) => _buildEnvironmentCard(env, provider)),
      ],
    );
  }

  Widget _buildEnvironmentCard(Map<String, dynamic> env, EnvironmentProvider provider) {
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
                  color: _getEnvironmentColor(env['type'] ?? 'development'),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getEnvironmentIcon(env['type'] ?? 'development'),
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      env['name'] ?? 'Unnamed',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF141414),
                      ),
                    ),
                    Text(
                      env['type'] ?? 'development',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditEnvironmentDialog(context, env);
                      break;
                    case 'delete':
                      _showDeleteEnvironmentDialog(context, env, provider);
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
              _buildStatChip('Active', env['is_active'] == true ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              _buildStatChip('Variables', provider.variables.length),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesSection(EnvironmentProvider provider) {
    return SectionBlock(
      title: 'Environment Variables',
      subtitle: 'Manage variables for the selected environment',
      children: [
        if (provider.selectedEnvironment == null)
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
                Icon(Icons.select_all, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Select an environment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an environment to view and manage its variables',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ...[
            ElevatedButton.icon(
              onPressed: () => _showAddVariableDialog(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('Add Variable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141414),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...provider.variables.map((variable) => _buildVariableCard(variable, provider)),
          ],
      ],
    );
  }

  Widget _buildVariableCard(Map<String, dynamic> variable, EnvironmentProvider provider) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.label, color: Colors.blue.shade600, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variable['key'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF141414),
                  ),
                ),
                Text(
                  variable['type'] ?? 'string',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '••••••••',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditVariableDialog(context, variable, provider);
                  break;
                case 'delete':
                  _showDeleteVariableDialog(context, variable, provider);
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
    );
  }

  Widget _buildStatChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value is int ? '$label: $value' : label,
        style: TextStyle(
          fontSize: 11,
          color: value is int ? Colors.grey.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getEnvironmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'production':
        return Colors.red.shade600;
      case 'staging':
        return Colors.orange.shade600;
      case 'development':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getEnvironmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'production':
        return Icons.public;
      case 'staging':
        return Icons.build;
      case 'development':
        return Icons.code;
      default:
        return Icons.settings;
    }
  }

  void _showCreateEnvironmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateEnvironmentDialog(),
    );
  }

  void _showEditEnvironmentDialog(BuildContext context, Map<String, dynamic> env) {
    showDialog(
      context: context,
      builder: (context) => EditEnvironmentDialog(environment: env),
    );
  }

  void _showDeleteEnvironmentDialog(BuildContext context, Map<String, dynamic> env, EnvironmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => DeleteEnvironmentDialog(
        environment: env,
        provider: provider,
      ),
    );
  }

  void _showAddVariableDialog(BuildContext context, EnvironmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AddVariableDialog(provider: provider),
    );
  }

  void _showEditVariableDialog(BuildContext context, Map<String, dynamic> variable, EnvironmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => EditVariableDialog(
        variable: variable,
        provider: provider,
      ),
    );
  }

  void _showDeleteVariableDialog(BuildContext context, Map<String, dynamic> variable, EnvironmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => DeleteVariableDialog(
        variable: variable,
        provider: provider,
      ),
    );
  }
}

// Dialog classes would go here - keeping the main screen focused
class CreateEnvironmentDialog extends StatelessWidget {
  const CreateEnvironmentDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Environment'),
      content: const Text('Environment creation dialog would go here'),
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

class EditEnvironmentDialog extends StatelessWidget {
  final Map<String, dynamic> environment;

  const EditEnvironmentDialog({Key? key, required this.environment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Environment'),
      content: const Text('Environment editing dialog would go here'),
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

class DeleteEnvironmentDialog extends StatelessWidget {
  final Map<String, dynamic> environment;
  final EnvironmentProvider provider;

  const DeleteEnvironmentDialog({
    Key? key,
    required this.environment,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Environment'),
      content: Text('Are you sure you want to delete "${environment['name']}"?'),
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

class AddVariableDialog extends StatelessWidget {
  final EnvironmentProvider provider;

  const AddVariableDialog({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Variable'),
      content: const Text('Variable creation dialog would go here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class EditVariableDialog extends StatelessWidget {
  final Map<String, dynamic> variable;
  final EnvironmentProvider provider;

  const EditVariableDialog({
    Key? key,
    required this.variable,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Variable'),
      content: const Text('Variable editing dialog would go here'),
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

class DeleteVariableDialog extends StatelessWidget {
  final Map<String, dynamic> variable;
  final EnvironmentProvider provider;

  const DeleteVariableDialog({
    Key? key,
    required this.variable,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Variable'),
      content: Text('Are you sure you want to delete "${variable['key']}"?'),
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
