import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/auth_provider.dart';

class WorkspacesScreen extends StatefulWidget {
  const WorkspacesScreen({Key? key}) : super(key: key);

  @override
  State<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends State<WorkspacesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkspaces();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadWorkspaces() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<WorkspaceProvider>(context, listen: false).loadWorkspaces();
    }
  }

  Future<void> _showCreateWorkspaceDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workspace Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
                  const SnackBar(content: Text('Please enter a workspace name')),
                );
                return;
              }

              final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
              final success = await workspaceProvider.createWorkspace(
                _nameController.text,
                description: _descriptionController.text.isEmpty 
                    ? null 
                    : _descriptionController.text,
              );

              if (success) {
                _nameController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workspace created!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(workspaceProvider.errorMessage ?? 'Failed to create workspace'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkspaceProvider, AuthProvider>(
      builder: (context, workspaceProvider, authProvider, child) {
        // Check authentication
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedView();
        }

        // Show loading
        if (workspaceProvider.isLoading) {
          return Container(
            color: const Color(0xFFFAFAFA),
            child: const Center(child: CircularProgressIndicator()),
          );
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
                          Text(
                            'Workspaces',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _showCreateWorkspaceDialog,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create Workspace',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Collaborate with your team on API projects',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Show empty state or workspace grid
                      if (workspaceProvider.workspaces.isEmpty)
                        _buildEmptyState()
                      else
                        _buildWorkspaceGrid(workspaceProvider),

                      const SizedBox(height: 40),

                      // Activity Timeline (static for now - can be made dynamic later)
                      if (workspaceProvider.workspaces.isNotEmpty)
                        _buildActivityTimeline(),
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
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please login to view workspaces',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to AUTH screen to sign in',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspaces_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No workspaces yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first workspace to start collaborating with your team on API projects',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateWorkspaceDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Your First Workspace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceGrid(WorkspaceProvider provider) {
    // Calculate grid count based on number of workspaces
    final workspaceCount = provider.workspaces.length;
    final crossAxisCount = workspaceCount < 3 ? workspaceCount : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.3,
      ),
      itemCount: provider.workspaces.length,
      itemBuilder: (context, index) {
        final workspace = provider.workspaces[index];
        return _buildWorkspaceCard(workspace, provider);
      },
    );
  }

  Widget _buildWorkspaceCard(Map<String, dynamic> workspace, WorkspaceProvider provider) {
    final isSelected = provider.selectedWorkspaceId == workspace['id'];
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
    ];
    final colorIndex = workspace['id'].hashCode % colors.length;
    final color = colors[colorIndex];

    return InkWell(
      onTap: () {
        provider.selectWorkspace(workspace['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected workspace: ${workspace['name']}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspaces, color: color, size: 24),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              workspace['name'] ?? 'Unnamed Workspace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              workspace['description'] ?? 'No description',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Created ${_formatDate(workspace['created_at'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    provider.selectWorkspace(workspace['id']);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Open →',
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline() {
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
            'Recent Workspace Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          _buildTimelineItem(
            'You',
            'created a new workspace',
            'Just now',
          ),
          _buildTimelineItem(
            'System',
            'initialized workspace settings',
            'Just now',
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
          _buildNavItem('Dashboard', false),
          _buildNavItem('Workspaces', true),
          _buildNavItem('Collections', false),
          _buildNavItem('Monitors', false),
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
            child: Text(
              authProvider.user?['name']?[0]?.toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.grey.shade900 : Colors.grey.shade600,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 22),
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String user, String action, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade900,
                    ),
                    children: [
                      TextSpan(
                        text: user,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' $action',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'recently';
    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 30) {
        return '${difference.inDays ~/ 30} months ago';
      } else if (difference.inDays > 7) {
        return '${difference.inDays ~/ 7} weeks ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }
}