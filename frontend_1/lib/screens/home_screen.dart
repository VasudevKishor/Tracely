import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workspaceProvider =
        Provider.of<WorkspaceProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    if (workspaceProvider.workspaces.isEmpty) {
      workspaceProvider.loadWorkspaces().then((_) {
        if (workspaceProvider.selectedWorkspaceId != null && mounted) {
          Provider.of<DashboardProvider>(context, listen: false)
              .loadDashboard(workspaceProvider.selectedWorkspaceId!);
        }
      });
    } else if (workspaceProvider.selectedWorkspaceId != null && mounted) {
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboard(workspaceProvider.selectedWorkspaceId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<DashboardProvider, WorkspaceProvider, AuthProvider>(
      builder:
          (context, dashboardProvider, workspaceProvider, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedView();
        }

        if (workspaceProvider.selectedWorkspaceId == null) {
          return _buildNoWorkspaceView();
        }

        return Container(
          color: const Color(0xFFFAFAFA),
          child: Column(
            children: [
              _buildTopBar(authProvider, workspaceProvider),
              Expanded(
                child: dashboardProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Monitor your API health and team activity',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Top Row - Metrics
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'API Uptime',
                                    // Convert to double first, then format
                                    '${(dashboardProvider.uptime ?? 0.0).toDouble().toStringAsFixed(2)}%',
                                    Icons.check_circle_outline,
                                    Colors.green.shade400,
                                    '+0.03% vs last week',
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Error Rate',
                                    '${dashboardProvider.errorRate?.toStringAsFixed(2) ?? '0.00'}%',
                                    Icons.error_outline,
                                    Colors.orange.shade400,
                                    '-0.05% vs last week',
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Avg Latency',
                                    '${dashboardProvider.avgLatency?.toString() ?? '0'}ms',
                                    Icons.speed,
                                    Colors.blue.shade400,
                                    '+12ms vs last week',
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Total Requests',
                                    '${dashboardProvider.totalRequests?.toString() ?? '0'}',
                                    Icons.trending_up,
                                    Colors.purple.shade400,
                                    '+320K this week',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Charts Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildChartCard(
                                    'Request Volume',
                                    'Last 7 days',
                                    350.0,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildRecentActivityCard(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Bottom Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFavoriteCollectionsCard(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildErrorAlertsCard(),
                                ),
                              ],
                            ),
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
              'Please login to view dashboard',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkspaceView() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 64, color: Colors.grey.shade400),
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
      ),
    );
  }

  Widget _buildTopBar(
      AuthProvider authProvider, WorkspaceProvider workspaceProvider) {
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
          const SizedBox(width: 20),
          _buildTopNavItem('Dashboard', true),
          _buildTopNavItem('Workspaces', false),
          _buildTopNavItem('Collections', false),
          _buildTopNavItem('Monitors', false),
          const Spacer(),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
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
                      decoration: InputDecoration(
                        hintText: 'Search APIs, requests, monitors...',
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
          ),
          const SizedBox(width: 20),
          _buildQuickActionButton(Icons.add, 'New Request'),
          const SizedBox(width: 12),
          _buildQuickActionButton(Icons.notifications_outlined, null),
          const SizedBox(width: 12),
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () async {
                await authProvider.logout();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out')),
                  );
                }
              },
              tooltip: 'Logout',
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade900,
            child: Text(
              () {
                final name = authProvider.user?['name']?.toString() ?? "";
                return name.isNotEmpty ? name[0].toUpperCase() : "U";
              }(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavItem(String text, bool isActive) {
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

  Widget _buildQuickActionButton(IconData icon, String? text) {
    return InkWell(
      onTap: () {
        if (text == 'New Request') {
           Provider.of<NavigationProvider>(context, listen: false).navigateTo('STUDIO');
        }
      },
      borderRadius: BorderRadius.circular(18),
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

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.95];
                return Container(
                  width: 40,
                  height: 200 * heights[index],
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      height: 350,
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
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildActivityItem(
                    'API request tested', 'Payment API', '2m ago'),
                _buildActivityItem(
                    'Collection updated', 'Auth Services', '15m ago'),
                _buildActivityItem(
                    'Monitor triggered', 'User Service', '1h ago'),
                _buildActivityItem(
                    'Environment created', 'Production', '3h ago'),
                _buildActivityItem(
                    'New member added', 'Team Workspace', '5h ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String action, String target, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  target,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCollectionsCard() {
    return Container(
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
            'Favorite Collections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          _buildCollectionItem('Payment Gateway API', '24 requests'),
          const SizedBox(height: 12),
          _buildCollectionItem('User Authentication', '18 requests'),
          const SizedBox(height: 12),
          _buildCollectionItem('Analytics Service', '32 requests'),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(String name, String count) {
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
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star, color: Colors.orange.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildErrorAlertsCard() {
    return Container(
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
            'Error Alerts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          _buildErrorItem(
              'High latency detected', 'User Service API', 'Warning'),
          const SizedBox(height: 12),
          _buildErrorItem('Rate limit exceeded', 'Payment API', 'Error'),
          const SizedBox(height: 12),
          _buildErrorItem('SSL certificate expiring', 'Auth Service', 'Info'),
        ],
      ),
    );
  }

  Widget _buildErrorItem(String message, String source, String level) {
    Color levelColor = level == 'Error'
        ? Colors.red.shade400
        : level == 'Warning'
            ? Colors.orange.shade400
            : Colors.blue.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
