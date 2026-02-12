import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSearch;
  final Function(String)? onSearchChanged;

  const CommonHeader({
    Key? key,
    required this.title,
    this.actions,
    this.showSearch = false,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

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
          _buildNavItem('Dashboard', false, () {
            Navigator.of(context).pushReplacementNamed('/home');
          }),
          _buildNavItem('Workspaces', false, () {
            Navigator.of(context).pushNamed('/workspaces');
          }),
          _buildNavItem('Collections', false, () {
            Navigator.of(context).pushNamed('/collections');
          }),
          _buildNavItem('Monitoring', false, () {
            Navigator.of(context).pushNamed('/monitoring');
          }),
          _buildNavItem('Settings', false, () {
            Navigator.of(context).pushNamed('/settings');
          }),

          const Spacer(),

          // Search Bar
          if (showSearch) ...[
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
                  Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],

          // Quick Actions
          _buildQuickActionButton(Icons.add, 'New Request', () {
            Navigator.of(context).pushNamed('/request-studio');
          }),
          const SizedBox(width: 12),
          _buildQuickActionButton(Icons.notifications_outlined, null, () {
            // Handle notifications
          }),
          const SizedBox(width: 12),

          // User Profile
          if (apiService.isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () async {
                await apiService.logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              },
              tooltip: 'Logout',
            ),
            const SizedBox(width: 12),
          ],

          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade900,
            child: Text(
              apiService.isAuthenticated ? 'U' : '?',
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

  Widget _buildNavItem(String text, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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
