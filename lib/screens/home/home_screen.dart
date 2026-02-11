import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tracely/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _environment = 'Production';
  bool _isLoading = true;
  String? _error;

  // Live data from backend
  int _totalRequests = 0;
  double _errorRate = 0;
  int _avgLatency = 0;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _workspaces = [];
  String? _activeWorkspaceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, load workspaces
      final workspaces = await ApiService().getWorkspaces();
      if (!mounted) return;

      _workspaces = workspaces.cast<Map<String, dynamic>>();

      if (_workspaces.isNotEmpty) {
        _activeWorkspaceId = _workspaces.first['id']?.toString();

        // Then load the monitoring dashboard for the active workspace
        if (_activeWorkspaceId != null) {
          try {
            final dashboard = await ApiService()
                .getMonitoringDashboard(_activeWorkspaceId!);
            if (!mounted) return;
            debugPrint('[HomeScreen] Dashboard response: $dashboard');
            _totalRequests = (dashboard['total_requests'] as num?)?.toInt() ?? 0;
            _errorRate = (dashboard['error_rate'] as num?)?.toDouble() ?? 0;
            _avgLatency = (dashboard['avg_response_time_ms'] as num?)?.toDouble().toInt() ?? 0;
            _services = (dashboard['services'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
          } catch (e) {
            debugPrint('[HomeScreen] Dashboard error (non-fatal): $e');
            // Dashboard may not have data yet — that's OK
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Tracely'),
            actions: [
              PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_rounded,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(_environment,
                        style: const TextStyle(fontSize: 14)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onSelected: (v) => setState(() => _environment = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'Production', child: Text('Production')),
                  const PopupMenuItem(
                      value: 'Staging', child: Text('Staging')),
                  const PopupMenuItem(
                      value: 'Development', child: Text('Development')),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Could not reach server',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_error!,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_workspaces.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.workspaces_outlined,
                                size: 48,
                                color: theme.colorScheme.primary
                                    .withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text('No workspaces yet',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Create a workspace from the backend to get started.',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildSummaryCards(context),
                    const SizedBox(height: 24),
                    Text(
                      'Service Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildServiceList(context),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final theme = Theme.of(context);

    final cards = [
      _SummaryCard(
        title: 'Total Requests',
        value: _formatNumber(_totalRequests),
        icon: Icons.analytics_rounded,
        color: theme.colorScheme.primary,
      ),
      _SummaryCard(
        title: 'Error Rate',
        value: '${_errorRate.toStringAsFixed(1)}%',
        icon: Icons.error_outline_rounded,
        color: Colors.orange,
      ),
      _SummaryCard(
        title: 'Avg Latency',
        value: '${_avgLatency}ms',
        icon: Icons.speed_rounded,
        color: Colors.teal,
      ),
    ];

    return Column(
      children: cards
          .asMap()
          .entries
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: e.value
                    .animate()
                    .fadeIn(delay: (e.key * 80).ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms),
              ))
          .toList(),
    );
  }

  Widget _buildServiceList(BuildContext context) {
    if (_services.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No services reporting yet.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return Column(
      children: _services.map((s) {
        final name = s['name'] ?? 'Unknown';
        final status = s['status'] ?? 'unknown';
        final statusCode =
            status == 'healthy' ? 0 : (status == 'degraded' ? 1 : 2);
        return _ServiceItem(name: name, status: statusCode);
      }).toList(),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String name;
  final int status; // 0=green, 1=yellow, 2=red

  const _ServiceItem({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.green, Colors.amber, Colors.red];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors[status],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors[status].withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        title: Text(name),
      ),
    );
  }
}
