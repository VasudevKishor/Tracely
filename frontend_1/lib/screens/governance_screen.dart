import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/governance_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/auth_provider.dart';

class GovernanceScreen extends StatefulWidget {
  const GovernanceScreen({Key? key}) : super(key: key);

  @override
  State<GovernanceScreen> createState() => _GovernanceScreenState();
}

class _GovernanceScreenState extends State<GovernanceScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'security';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGovernanceData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadGovernanceData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) return;

    if (workspaceProvider.workspaces.isEmpty) {
      workspaceProvider.loadWorkspaces().then((_) {
        if (workspaceProvider.selectedWorkspaceId != null) {
          Provider.of<GovernanceProvider>(context, listen: false)
              .loadPolicies(workspaceProvider.selectedWorkspaceId!);
        }
      });
    } else if (workspaceProvider.selectedWorkspaceId != null) {
      Provider.of<GovernanceProvider>(context, listen: false)
          .loadPolicies(workspaceProvider.selectedWorkspaceId!);
    }
  }

  Future<void> _showCreatePolicyDialog() async {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    
    if (workspaceProvider.selectedWorkspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a workspace first')),
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Policy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Policy Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Policy Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'security', child: Text('Security')),
                DropdownMenuItem(value: 'performance', child: Text('Performance')),
                DropdownMenuItem(value: 'documentation', child: Text('Documentation')),
                DropdownMenuItem(value: 'standards', child: Text('API Standards')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a policy name')),
                );
                return;
              }

              final governanceProvider = Provider.of<GovernanceProvider>(context, listen: false);
              final success = await governanceProvider.createPolicy(
                workspaceProvider.selectedWorkspaceId!,
                _nameController.text,
                _descriptionController.text,
                _selectedType,
              );

              if (success) {
                _nameController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Policy created!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(governanceProvider.errorMessage ?? 'Failed to create policy'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<GovernanceProvider, WorkspaceProvider, AuthProvider>(
      builder: (context, governanceProvider, workspaceProvider, authProvider, child) {
        // Check authentication
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedView();
        }

        // Check workspace
        if (workspaceProvider.selectedWorkspaceId == null) {
          return _buildNoWorkspaceView();
        }

        // Show loading
        if (governanceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          color: const Color(0xFFFAFAFA),
          child: Column(
            children: [
              _buildTopBar(authProvider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Governance Dashboard',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enforce standards and compliance across your APIs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _showCreatePolicyDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Policy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Compliance Scorecards
                      _buildComplianceCards(governanceProvider),

                      const SizedBox(height: 24),

                      // Active Policies
                      _buildPoliciesSection(governanceProvider, workspaceProvider),

                      const SizedBox(height: 24),

                      // Security Checks (static for now)
                      _buildSecurityChecksSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Please login to view governance',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkspaceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Please select a workspace first',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCards(GovernanceProvider provider) {
    final compliance = provider.complianceData ?? {
      'api_standards': 85,
      'security': 92,
      'documentation': 78,
      'performance': 95,
    };

    return Row(
      children: [
        Expanded(
          child: _buildComplianceCard(
            'API Standards',
            compliance['api_standards'] ?? 0,
            Colors.blue,
            '${((compliance['api_standards'] ?? 0) * 0.15).round()}/15 rules passed',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildComplianceCard(
            'Security',
            compliance['security'] ?? 0,
            Colors.green,
            '${((compliance['security'] ?? 0) * 0.25).round()}/25 checks passed',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildComplianceCard(
            'Documentation',
            compliance['documentation'] ?? 0,
            Colors.orange,
            '${((compliance['documentation'] ?? 0) * 0.22).round()}/22 items complete',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildComplianceCard(
            'Performance',
            compliance['performance'] ?? 0,
            Colors.purple,
            '${((compliance['performance'] ?? 0) * 0.20).round()}/20 metrics met',
          ),
        ),
      ],
    );
  }

  Widget _buildPoliciesSection(
    GovernanceProvider governanceProvider,
    WorkspaceProvider workspaceProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
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
              Text(
                'Active Policies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const Spacer(),
              Text(
                '${governanceProvider.policies.length} total',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (governanceProvider.policies.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.policy_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No policies yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first governance policy',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ...governanceProvider.policies.map((policy) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPolicyItem(
                  policy,
                  governanceProvider,
                  workspaceProvider,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(
    Map<String, dynamic> policy,
    GovernanceProvider governanceProvider,
    WorkspaceProvider workspaceProvider,
  ) {
    final isEnabled = policy['enabled'] ?? true;
    final type = policy['type'] ?? 'security';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.green.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEnabled ? Icons.check_circle : Icons.cancel,
              color: isEnabled ? Colors.green.shade600 : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy['name'] ?? 'Unnamed Policy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  policy['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPolicyTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getPolicyTypeColor(type),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Policy'),
                  content: const Text('Are you sure you want to delete this policy?'),
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

              if (confirmed == true && workspaceProvider.selectedWorkspaceId != null) {
                final success = await governanceProvider.deletePolicy(
                  workspaceProvider.selectedWorkspaceId!,
                  policy['id'],
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Policy deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getPolicyTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'security':
        return Colors.red;
      case 'performance':
        return Colors.purple;
      case 'documentation':
        return Colors.orange;
      case 'standards':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSecurityChecksSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Checks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          _buildSecurityCheck(
            'SSL/TLS Enforcement',
            'Passed',
            Colors.green,
            'All endpoints use HTTPS',
          ),
          const SizedBox(height: 12),
          _buildSecurityCheck(
            'API Key Rotation',
            'Passed',
            Colors.green,
            'Keys rotated every 90 days',
          ),
          const SizedBox(height: 12),
          _buildSecurityCheck(
            'Rate Limiting',
            'Warning',
            Colors.orange,
            '4 endpoints exceed recommended limits',
          ),
          const SizedBox(height: 12),
          _buildSecurityCheck(
            'Input Validation',
            'Passed',
            Colors.green,
            'All inputs properly sanitized',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AuthProvider authProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            'Tracely',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(width: 60),
          Text(
            'Governance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const Spacer(),
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () async {
                await authProvider.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              },
              tooltip: 'Logout',
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade900,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(
      String title, int score, Color color, String details) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        (color is MaterialColor) ? color.shade400 : color),
                  ),
                ),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            details,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCheck(
      String title, String status, Color color, String details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
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
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}