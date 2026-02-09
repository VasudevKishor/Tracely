import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'workspace_setup_screen.dart';

class WorkspacesScreen extends StatefulWidget {
  const WorkspacesScreen({Key? key}) : super(key: key);

  @override
  State<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends State<WorkspacesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  String _filterType = 'All';
  String _filterAccess = 'All';

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
    _searchController.dispose();
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
              name: _nameController.text,  // Named parameter
              type: WorkspaceType.internal,  // Default type
              isPublic: false,  // Default to private
              accessType: AccessType.teamOnly,  // Default access
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
                  child: Column(
                    children: [
                      // Header section with title and create button
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(48, 32, 48, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your workspaces',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'A directory of your workspaces.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade600, Colors.orange.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const WorkspaceSetupScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.add, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            const Text(
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
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (workspaceProvider.workspaces.isEmpty)
                        _buildEmptyState()
                      else ...[
                        // Search and filters section
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
                          child: Column(
                            children: [
                              // Search bar
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    hintText: 'Search workspaces...',
                                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Filter buttons
                              Row(
                                children: [
                                  _buildFilterChip('Type', ['All', 'Internal', 'External', 'Team'], _filterType, (value) {
                                    setState(() => _filterType = value);
                                  }),
                                  const SizedBox(width: 12),
                                  _buildFilterChip('Access', ['All', 'Only you', 'Shared'], _filterAccess, (value) {
                                    setState(() => _filterAccess = value);
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Workspaces table
                        _buildWorkspacesTable(workspaceProvider),
                      ],

                      const SizedBox(height: 40),
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

  Widget _buildWorkspacesTable(WorkspaceProvider provider) {
    // Filter workspaces based on search and filters
    final filteredWorkspaces = provider.workspaces.where((ws) {
      final matchesSearch = _searchController.text.isEmpty ||
          ws['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesSearch;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table header
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildHeaderCell('Name'),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildHeaderCell('Created by'),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildHeaderCell('Type'),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildHeaderCell('Access'),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildHeaderCell('Last updated'),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Table rows
            ...List.generate(filteredWorkspaces.length, (index) {
              final workspace = filteredWorkspaces[index];
              final isLast = index == filteredWorkspaces.length - 1;
              return _buildWorkspaceRow(workspace, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildWorkspaceRow(Map<String, dynamic> workspace, bool isLast) {
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkspaceSetupScreen(workspace: workspace),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Name column
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.workspaces, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace['name'] ?? 'Unnamed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workspace['description'] ?? 'No description',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Created by column
              Expanded(
                flex: 2,
                child: Text(
                  workspace['created_by'] ?? 'You',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Type column
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Internal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              // Access column
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Only you',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              // Last updated column
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(workspace['created_at']),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // More options icon
              PopupMenuButton(
                offset: const Offset(-10, 40),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.content_copy, size: 16),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () {},
                  ),
                ],
                child: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, List<String> options, String selected, Function(String) onChanged) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              if (selected == option) const Icon(Icons.check, size: 16, color: Colors.orange),
              if (selected == option) const SizedBox(width: 8),
              Text(option),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more, size: 14, color: Colors.grey.shade600),
          ],
        ),
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
    return InkWell(
      onTap: () {
        final nav = Provider.of<NavigationProvider>(context, listen: false);
        switch (text) {
          case 'Dashboard':
            nav.navigateTo('HOME');
            break;
          case 'Workspaces':
            nav.navigateTo('WORKSPACES');
            break;
          case 'Collections':
            nav.navigateTo('COLLECTIONS');
            break;
          case 'Monitors':
            nav.navigateTo('MONITORING');
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'recently';
    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 365) {
        return '1 year ago';
      } else if (difference.inDays > 30) {
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