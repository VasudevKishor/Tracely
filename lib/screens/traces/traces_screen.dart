import 'package:flutter/material.dart';
import 'package:tracely/screens/traces/trace_details_screen.dart';

class TracesScreen extends StatefulWidget {
  const TracesScreen({super.key});

  @override
  State<TracesScreen> createState() => _TracesScreenState();
}

class _TracesScreenState extends State<TracesScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _durationFilter = 'All';
  int _itemCount = 15;

  final _traces = [
    _TraceItem('GET', '/api/users', 200, 45),
    _TraceItem('POST', '/api/auth/login', 200, 120),
    _TraceItem('GET', '/api/products', 404, 12),
    _TraceItem('DELETE', '/api/sessions/1', 500, 320),
    _TraceItem('PUT', '/api/users/me', 200, 89),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Traces')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search traces...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...['All', '2xx', '4xx', '5xx'].map((o) => FilterChip(
                    label: Text(o),
                    selected: _statusFilter == o,
                    onSelected: (_) => setState(() => _statusFilter = o),
                  )),
                  ...['All', '<100ms', '100-500ms', '>500ms'].map((o) => FilterChip(
                    label: Text(o),
                    selected: _durationFilter == o,
                    onSelected: (_) => setState(() => _durationFilter = o),
                  )),
                ],
              ),
              const SizedBox(height: 20),
              ...List.generate(
                _traces.length * 3,
                (i) => _TraceListItem(
                  trace: _traces[i % _traces.length],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TraceDetailsScreen(trace: _traces[i % _traces.length]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _itemCount += 10),
                  child: const Text('Load more'),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TraceItem {
  final String method;
  final String path;
  final int status;
  final int durationMs;

  _TraceItem(this.method, this.path, this.status, this.durationMs);
}

class _TraceListItem extends StatelessWidget {
  final _TraceItem trace;
  final VoidCallback onTap;

  const _TraceListItem({required this.trace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = trace.status >= 500
        ? Colors.red
        : trace.status >= 400
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _methodColor(trace.method).withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            trace.method,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _methodColor(trace.method),
            ),
          ),
        ),
        title: Text(
          trace.path,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${trace.durationMs}ms'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${trace.status}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ),
    );
  }

  Color _methodColor(String method) {
    return switch (method) {
      'GET' => Colors.green,
      'POST' => Colors.blue,
      'PUT' => Colors.amber,
      'DELETE' => Colors.red,
      _ => Colors.grey,
    };
  }
}
