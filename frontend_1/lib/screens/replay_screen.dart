// lib/screens/replay_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/replay_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/common_widgets.dart';

/// Replay Screen - Manage and execute request replays
/// Allows users to replay API requests for load testing
class ReplayScreen extends StatefulWidget {
  const ReplayScreen({Key? key}) : super(key: key);

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReplays();
  }

  Future<void> _loadReplays() async {
    final workspaceProvider = context.read<WorkspaceProvider>();
    final replayProvider = context.read<ReplayProvider>();

    if (workspaceProvider.selectedWorkspace == null) {
      setState(() {
        _error = 'Please select a workspace first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await replayProvider.fetchReplays(
        workspaceProvider.selectedWorkspace!['id'],
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createReplay() {
    showDialog(
      context: context,
      builder: (context) => const CreateReplayDialog(),
    ).then((created) {
      if (created == true) {
        _loadReplays();
      }
    });
  }

  void _executeReplay(Map<String, dynamic> replay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute Replay'),
        content: Text(
          'Execute "${replay['name']}"?\n\n'
          'This will replay ${replay['count'] ?? 1} requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Execute'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final workspaceProvider = context.read<WorkspaceProvider>();
        final replayProvider = context.read<ReplayProvider>();

        await replayProvider.executeReplay(
          workspaceProvider.selectedWorkspace!['id'],
          replay['id'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Replay executed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteReplay(Map<String, dynamic> replay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Replay'),
        content: Text('Delete "${replay['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final workspaceProvider = context.read<WorkspaceProvider>();
        final replayProvider = context.read<ReplayProvider>();

        await replayProvider.deleteReplay(
          workspaceProvider.selectedWorkspace!['id'],
          replay['id'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Replay deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Replays'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReplays,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReplay,
        icon: const Icon(Icons.add),
        label: const Text('New Replay'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadReplays);
    }

    return Consumer<ReplayProvider>(
      builder: (context, replayProvider, child) {
        if (replayProvider.replays.isEmpty) {
          return const EmptyState(
            icon: Icons.replay,
            message: 'No replays yet',
            description: 'Create a replay to load test your APIs',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: replayProvider.replays.length,
          itemBuilder: (context, index) {
            return _buildReplayCard(replayProvider.replays[index]);
          },
        );
      },
    );
  }

  Widget _buildReplayCard(Map<String, dynamic> replay) {
    final name = replay['name'] ?? 'Unnamed Replay';
    final count = replay['count'] ?? 1;
    final status = replay['status'] ?? 'pending';
    final targetEnv = replay['target_environment'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count requests • $targetEnv',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'execute',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 8),
                          Text('Execute'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'results',
                      child: Row(
                        children: [
                          Icon(Icons.assessment, size: 20),
                          SizedBox(width: 8),
                          Text('View Results'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'execute':
                        _executeReplay(replay);
                        break;
                      case 'results':
                        _viewResults(replay);
                        break;
                      case 'delete':
                        _deleteReplay(replay);
                        break;
                    }
                  },
                ),
              ],
            ),
            if (replay['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                replay['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'running':
        icon = Icons.play_circle;
        color = Colors.blue;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.pending;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 24);
  }

  void _viewResults(Map<String, dynamic> replay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplayResultsScreen(replay: replay),
      ),
    );
  }
}

/// Create Replay Dialog
class CreateReplayDialog extends StatefulWidget {
  const CreateReplayDialog({Key? key}) : super(key: key);

  @override
  State<CreateReplayDialog> createState() => _CreateReplayDialogState();
}

class _CreateReplayDialogState extends State<CreateReplayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countController = TextEditingController(text: '10');
  String _targetEnvironment = 'staging';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _createReplay() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final workspaceProvider = context.read<WorkspaceProvider>();
      final replayProvider = context.read<ReplayProvider>();

      await replayProvider.createReplay(
        workspaceProvider.selectedWorkspace!['id'],
        {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'count': int.parse(_countController.text),
          'target_environment': _targetEnvironment,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Replay created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Replay'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countController,
                decoration: const InputDecoration(
                  labelText: 'Number of Requests',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a count';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count < 1) {
                    return 'Count must be at least 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _targetEnvironment,
                decoration: const InputDecoration(
                  labelText: 'Target Environment',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'staging', child: Text('Staging')),
                  DropdownMenuItem(value: 'production', child: Text('Production')),
                  DropdownMenuItem(value: 'testing', child: Text('Testing')),
                ],
                onChanged: (value) {
                  setState(() {
                    _targetEnvironment = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createReplay,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Replay Results Screen
class ReplayResultsScreen extends StatelessWidget {
  final Map<String, dynamic> replay;

  const ReplayResultsScreen({Key? key, required this.replay}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Requests', '${replay['count'] ?? 0}'),
            _buildSummaryRow('Successful', '${replay['successful'] ?? 0}'),
            _buildSummaryRow('Failed', '${replay['failed'] ?? 0}'),
            _buildSummaryRow('Avg Response Time', '${replay['avg_time'] ?? 0}ms'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Results',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Results will be displayed here after execution'),
      ],
    );
  }
}