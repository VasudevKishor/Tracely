import 'package:flutter/material.dart';
import 'package:tracely/core/widgets/empty_state.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _severityFilter = 'All';
  String _serviceFilter = 'All';
  final _alerts = [
    _AlertData('Error', 'Auth Service', '2 min ago', 'Critical'),
    _AlertData('Latency', 'Payment API', '15 min ago', 'High'),
    _AlertData('Test Failure', 'User Service', '1 hr ago', 'Medium'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Alerts')),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: ['All', 'Critical', 'High', 'Medium', 'Low']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _severityFilter = v ?? 'All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _serviceFilter,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: ['All', 'Auth Service', 'Payment API', 'User Service']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _serviceFilter = v ?? 'All'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._alerts.map((a) => _AlertCard(alert: a)),
            ]),
          ),
        ),
      ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
