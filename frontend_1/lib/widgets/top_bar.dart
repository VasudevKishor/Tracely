import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_provider.dart';

class TopBar extends StatefulWidget {
  final int currentViewIndex;
  final Function(int) onViewChanged;
  final TextEditingController searchController;

  const TopBar({
    Key? key,
    required this.currentViewIndex,
    required this.onViewChanged,
    required this.searchController,
  }) : super(key: key);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WorkspaceProvider>(
      builder: (context, authProvider, workspaceProvider, child) {
        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo/Brand
              Text(
                'Tracely',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(width: 60),

              // Navigation Items
              _buildNavItem('Dashboard', 0),
              _buildNavItem('Request Studio', 1),
              _buildNavItem('Traces', 2),

              const Spacer(),

              // Search Bar
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: widget.searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Quick Actions
              _buildQuickActionButton(
                Icons.add,
                'New Request',
                () => widget.onViewChanged(1),
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                Icons.timeline,
                'Traces',
                () => widget.onViewChanged(2),
              ),

              const SizedBox(width: 20),

              // User Profile
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade900,
                child: Text(
                  authProvider.isAuthenticated ? 'U' : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Profile Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'logout':
                      // Handle logout
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('Profile Settings'),
                  ),
                  const PopupMenuItem(
                    value: 'account',
                    child: Text('Account'),
                  ),
                  const PopupMenuItem(
                    value: 'billing',
                    child: Text('Billing'),
                  ),
                  const PopupMenuItem(
                    value: 'team',
                    child: Text('Team'),
                  ),
                  const PopupMenuItem(
                    value: 'integrations',
                    child: Text('Integrations'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(String text, int index) {
    final isActive = widget.currentViewIndex == index;
    return InkWell(
      onTap: () => widget.onViewChanged(index),
      child: Padding(
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
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String? text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: text != null ? 16 : 0),
        width: text != null ? null : 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            if (text != null) ...[
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
