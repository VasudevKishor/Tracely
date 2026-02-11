import 'package:flutter/material.dart';
import 'package:tracely/services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _severityFilter = 'All';
  String _serviceFilter = 'All';
  bool _isLoading = true;
  String? _error;
  List<_AlertData> _alerts = [];
  Set<String> _availableServices = {'All'};

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workspaces = await ApiService().getWorkspaces();
      if (!mounted) return;

      if (workspaces.isEmpty) {
        setState(() {
          _isLoading = false;
          _alerts = [];
        });
        return;
      }

      final wsId =
          (workspaces.first as Map<String, dynamic>)['id']?.toString();
      if (wsId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Use monitoring dashboard to derive alerts from error data
      try {
        final dashboard = await ApiService().getMonitoringDashboard(wsId);
        if (!mounted) return;

        final services =
            (dashboard['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final topEndpoints =
            (dashboard['top_endpoints'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

        final alerts = <_AlertData>[];
        final serviceNames = <String>{'All'};

        for (final svc in services) {
          final name = svc['name'] ?? 'Unknown';
          serviceNames.add(name);
          final status = svc['status'] ?? 'healthy';
          if (status != 'healthy') {
            alerts.add(_AlertData(
              status == 'degraded' ? 'Latency' : 'Error',
              name,
              'Now',
              status == 'degraded' ? 'Medium' : 'Critical',
            ));
          }
        }

        final errorRate = (dashboard['error_rate'] ?? 0).toDouble();
        if (errorRate > 5) {
          alerts.insert(
              0,
              _AlertData('Error', 'Platform',
                  'Error rate: ${errorRate.toStringAsFixed(1)}%', 'Critical'));
        } else if (errorRate > 1) {
          alerts.insert(
              0,
              _AlertData('Error', 'Platform',
                  'Error rate: ${errorRate.toStringAsFixed(1)}%', 'High'));
        }

        _alerts = alerts;
        _availableServices = serviceNames;
      } catch (_) {
        // No monitoring data available — show empty
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

  List<_AlertData> get _filteredAlerts {
    return _alerts.where((a) {
      if (_severityFilter != 'All' && a.severity != _severityFilter) {
        return false;
      }
      if (_serviceFilter != 'All' && a.service != _serviceFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Alerts')),
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
                    Text(_error!, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadAlerts,
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _severityFilter,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          items: ['All', 'Critical', 'High', 'Medium', 'Low']
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _severityFilter = v ?? 'All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _serviceFilter,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          items: _availableServices
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _serviceFilter = v ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_filteredAlerts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 48,
                                color: Colors.green.withOpacity(0.7)),
                            const SizedBox(height: 12),
                            Text('All quiet',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('No alerts at this time.',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filteredAlerts.map((a) => _AlertCard(alert: a)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertData {
  final String type;
  final String service;
  final String timestamp;
  final String severity;

  _AlertData(this.type, this.service, this.timestamp, this.severity);
}

class _AlertCard extends StatelessWidget {
  final _AlertData alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = switch (alert.severity) {
      'Critical' => Colors.red,
      'High' => Colors.orange,
      'Medium' => Colors.amber,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(type: alert.type),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.severity,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.service,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alert.timestamp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'Error' => Colors.red,
      'Latency' => Colors.orange,
      'Test Failure' => Colors.purple,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
