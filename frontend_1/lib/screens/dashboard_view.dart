import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return Material(
          child: SingleChildScrollView(
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
                        '${((dashboardProvider.uptime ?? 0.0) is int
                            ? (dashboardProvider.uptime as int).toDouble()
                            : (dashboardProvider.uptime ?? 0.0)).toStringAsFixed(2)}%',
                        Icons.check_circle_outline,
                        Colors.green.shade400,
                        _calculateUptimeChange(dashboardProvider),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildMetricCard(
                        'Error Rate',
                        '${dashboardProvider.errorRate?.toStringAsFixed(2) ?? '0.00'}%',
                        Icons.error_outline,
                        Colors.orange.shade400,
                        _calculateErrorRateChange(dashboardProvider),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildMetricCard(
                        'Avg Latency',
                        '${dashboardProvider.avgLatency?.toString() ?? '0'}ms',
                        Icons.speed,
                        Colors.blue.shade400,
                        _calculateLatencyChange(dashboardProvider),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Requests',
                        '${dashboardProvider.totalRequests?.toString() ?? '0'}',
                        Icons.trending_up,
                        Colors.purple.shade400,
                        _calculateRequestsChange(dashboardProvider),
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
                      child: _buildRecentActivityCard(dashboardProvider),
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
        );
      },
    );
  }

  String _calculateUptimeChange(DashboardProvider provider) {
    // Calculate vs last week based on provider data
    // For now, return a placeholder - implement based on actual data structure
    return '+0.03% vs last week';
  }

  String _calculateErrorRateChange(DashboardProvider provider) {
    // Calculate vs last week based on provider data
    return '-0.05% vs last week';
  }

  String _calculateLatencyChange(DashboardProvider provider) {
    // Calculate vs last week based on provider data
    return '+12ms vs last week';
  }

  String _calculateRequestsChange(DashboardProvider provider) {
    // Calculate vs last week based on provider data
    return '+320K this week';
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

  Widget _buildRecentActivityCard(DashboardProvider dashboardProvider) {
    // For now, use mock data since recentActivities isn't implemented in provider
    final activities = [
      {'action': 'API request tested', 'target': 'Payment API', 'time': '2m ago'},
      {'action': 'Collection updated', 'target': 'Auth Services', 'time': '15m ago'},
      {'action': 'Monitor triggered', 'target': 'User Service', 'time': '1h ago'},
      {'action': 'Environment created', 'target': 'Production', 'time': '3h ago'},
      {'action': 'New member added', 'target': 'Team Workspace', 'time': '5h ago'},
    ];

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
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(
                  activity['action'] ?? 'Unknown action',
                  activity['target'] ?? 'Unknown target',
                  activity['time'] ?? 'Unknown time',
                );
              },
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
