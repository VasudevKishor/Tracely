import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({Key? key}) : super(key: key);

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Map<String, bool> _expandedCollections = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollections();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCollections() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      return;
    }

    // Load workspaces if not loaded
    if (workspaceProvider.workspaces.isEmpty) {
      workspaceProvider.loadWorkspaces().then((_) {
        if (workspaceProvider.selectedWorkspaceId != null) {
          Provider.of<CollectionProvider>(context, listen: false)
              .loadCollections(workspaceProvider.selectedWorkspaceId!);
        }
      });
    } else if (workspaceProvider.selectedWorkspaceId != null) {
      Provider.of<CollectionProvider>(context, listen: false)
          .loadCollections(workspaceProvider.selectedWorkspaceId!);
    }
  }

  Future<void> _showCreateCollectionDialog() async {
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
        title: const Text('Create Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
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
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              final collectionProvider = Provider.of<CollectionProvider>(context, listen: false);
              final success = await collectionProvider.createCollection(
                workspaceProvider.selectedWorkspaceId!,
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
                    content: Text('Collection created!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(collectionProvider.errorMessage ?? 'Failed to create collection'),
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
    return Consumer3<CollectionProvider, WorkspaceProvider, AuthProvider>(
      builder: (context, collectionProvider, workspaceProvider, authProvider, child) {
        // Check authentication
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedView();
        }

        // Check workspace selection
        if (workspaceProvider.selectedWorkspaceId == null) {
          return _buildNoWorkspaceView();
        }

        // Show loading
        if (collectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          color: const Color(0xFFFAFAFA),
          child: Column(
            children: [
              _buildTopBar(authProvider),
              Expanded(
                child: Row(
                  children: [
                    // Left Panel - Tree View
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(right: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Collections',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: _showCreateCollectionDialog,
                                  color: Colors.grey.shade700,
                                  tooltip: 'Create Collection',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: collectionProvider.collections.isEmpty
                                ? _buildEmptyCollections()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: collectionProvider.collections.length,
                                    itemBuilder: (context, index) {
                                      final collection = collectionProvider.collections[index];
                                      return _buildCollectionTreeItem(
                                        collection,
                                        collectionProvider,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Right Panel - Documentation
                    Expanded(
                      child: collectionProvider.selectedCollection != null
                          ? _buildCollectionDetails(collectionProvider.selectedCollection!)
                          : _buildNoSelectionView(),
                    ),
                  ],
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
            'Please login to view collections',
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
          const SizedBox(height: 8),
          Text(
            'Go to Workspaces screen to select or create one',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCollections() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined, 
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No collections yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the + button to create your first collection',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Select a collection to view details',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
          _buildNavItem('Workspaces', false),
          _buildNavItem('Collections', true),
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
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTreeItem(
    Map<String, dynamic> collection,
    CollectionProvider provider,
  ) {
    final collectionId = collection['id'] ?? '';
    final isExpanded = _expandedCollections[collectionId] ?? false;
    final isSelected = provider.selectedCollection?['id'] == collectionId;

    return Column(
      children: [
        InkWell(
          onTap: () {
            provider.selectCollection(collection);
            setState(() {
              _expandedCollections[collectionId] = !isExpanded;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : 
                     isExpanded ? Colors.grey.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: Colors.blue.shade200) : null,
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.folder_open : Icons.folder,
                  size: 18,
                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    collection['name'] ?? 'Unnamed Collection',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.blue.shade900 : Colors.grey.shade900,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && collection['requests'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: (collection['requests'] as List).map((request) {
                return _buildRequestItem(
                  request['name'] ?? 'Unnamed Request',
                  request['method'] ?? 'GET',
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRequestItem(String name, String method) {
    Color methodColor = method == 'GET'
        ? Colors.blue.shade600
        : method == 'POST'
            ? Colors.green.shade600
            : method == 'PUT'
                ? Colors.orange.shade600
                : method == 'DELETE'
                    ? Colors.red.shade600
                    : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: methodColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionDetails(Map<String, dynamic> collection) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.folder_open,
                    color: Colors.blue.shade400, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection['name'] ?? 'Unnamed Collection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      '${collection['request_count'] ?? 0} requests • Created ${_formatDate(collection['created_at'])}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDocButton('Export', Icons.download),
              const SizedBox(width: 12),
              _buildDocButton('Share', Icons.share),
            ],
          ),
          const SizedBox(height: 32),

          // Description
          if (collection['description'] != null && collection['description'].toString().isNotEmpty)
            Container(
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
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    collection['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocButton(String text, IconData icon) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text feature coming soon!')),
        );
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
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
      
      if (difference.inDays > 7) {
        return '${difference.inDays ~/ 7} weeks ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else {
        return 'recently';
      }
    } catch (e) {
      return 'recently';
    }
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
}