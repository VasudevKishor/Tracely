import 'package:flutter/material.dart';
import 'package:tracely/screens/traces/trace_timeline_screen.dart';
import 'package:tracely/screens/traces/request_response_viewer.dart';

class TraceDetailsScreen extends StatelessWidget {
  final dynamic trace;

  const TraceDetailsScreen({super.key, required this.trace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = trace.method;
    final path = trace.path;
    final status = trace.status;
    final duration = trace.durationMs;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trace Details'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Timeline'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: Column(
          children: [
            _MetadataSection(
              method: method,
              path: path,
              status: status,
              duration: duration,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  TraceTimelineScreen(trace: trace),
                  RequestResponseViewer(data: _sampleRequest),
                  RequestResponseViewer(data: _sampleResponse),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickActionChip(icon: Icons.replay, label: 'Replay'),
                _QuickActionChip(icon: Icons.smart_toy, label: 'Replay with mocks'),
                _QuickActionChip(icon: Icons.code, label: 'Copy as cURL'),
                _QuickActionChip(icon: Icons.share, label: 'Share trace link'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _sampleRequest = '''
{
  "method": "GET",
  "url": "/api/users",
  "headers": {
    "Authorization": "Bearer ***",
    "Content-Type": "application/json"
  },
  "body": null
}
''';

  static const _sampleResponse = '''
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "users": [
      {"id": 1, "name": "John"},
      {"id": 2, "name": "Jane"}
    ]
  }
}
''';
}

class _MetadataSection extends StatelessWidget {
  final String method;
  final String path;
  final int status;
  final int duration;

  const _MetadataSection({
    required this.method,
    required this.path,
    required this.status,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = status >= 500 ? Colors.red : status >= 400 ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(text: method, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(path, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Badge(text: '$status', color: statusColor),
              const SizedBox(width: 8),
              Text('${duration}ms', style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      onPressed: () {},
    );
  }
}
