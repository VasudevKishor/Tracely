import 'package:flutter/material.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _severityFilter = 'All';

  static final _logs = [
    _LogEntry('INFO', '2024-02-08 10:23:45', 'Request received: GET /api/users'),
    _LogEntry('WARN', '2024-02-08 10:23:44', 'Cache miss for key: user:123'),
    _LogEntry('ERROR', '2024-02-08 10:23:42', 'Database connection timeout'),
    _LogEntry('INFO', '2024-02-08 10:23:40', 'Server started on port 8080'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _severityFilter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'INFO', child: Text('INFO')),
              const PopupMenuItem(value: 'WARN', child: Text('WARN')),
              const PopupMenuItem(value: 'ERROR', child: Text('ERROR')),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final filtered = _logs.where((l) => _severityFilter == 'All' || l.severity == _severityFilter).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _LogItem(entry: filtered[i]),
          );
        },
      ),
    );
  }
}

class _LogEntry {
  final String severity;
  final String timestamp;
  final String message;

  _LogEntry(this.severity, this.timestamp, this.message);
}

class _LogItem extends StatelessWidget {
  final _LogEntry entry;

  const _LogItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (entry.severity) {
      'ERROR' => Colors.red,
      'WARN' => Colors.amber,
      _ => Colors.blue,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entry.severity,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.message, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
