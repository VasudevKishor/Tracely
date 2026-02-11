import 'package:flutter/material.dart';
import 'package:tracely/services/api_service.dart';
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

  bool _isLoading = true;
  String? _error;
  List<_TraceItem> _traces = [];
  String? _workspaceId;

  @override
  void initState() {
    super.initState();
    _loadTraces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTraces() async {
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
          _traces = [];
        });
        return;
      }

      _workspaceId =
          (workspaces.first as Map<String, dynamic>)['id']?.toString();
      if (_workspaceId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await ApiService().getTraces(_workspaceId!);
      if (!mounted) return;

      final rawTraces =
          (data['traces'] ?? data['data'] ?? []) as List<dynamic>;
      _traces = rawTraces.map((t) {
        final m = t as Map<String, dynamic>;
        return _TraceItem(
          method: m['method'] ?? m['operation_name'] ?? 'GET',
          path: m['service_name'] ?? m['endpoint'] ?? '/unknown',
          status: m['status_code'] ?? (m['status'] == 'success' ? 200 : 500),
          durationMs: m['total_duration_ms'] ?? m['duration_ms'] ?? 0,
          traceId: m['trace_id'] ?? m['id'] ?? '',
        );
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<_TraceItem> get _filteredTraces {
    var result = _traces;
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      result =
          result.where((t) => t.path.toLowerCase().contains(query)).toList();
    }
    if (_statusFilter != 'All') {
      result = result.where((t) {
        if (_statusFilter == '2xx') return t.status >= 200 && t.status < 300;
        if (_statusFilter == '4xx') return t.status >= 400 && t.status < 500;
        if (_statusFilter == '5xx') return t.status >= 500;
        return true;
      }).toList();
    }
    if (_durationFilter != 'All') {
      result = result.where((t) {
        if (_durationFilter == '<100ms') return t.durationMs < 100;
        if (_durationFilter == '100-500ms') {
          return t.durationMs >= 100 && t.durationMs <= 500;
        }
        if (_durationFilter == '>500ms') return t.durationMs > 500;
        return true;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadTraces,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Traces')),
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
                      onPressed: _loadTraces,
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search traces...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
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
                            onSelected: (_) =>
                                setState(() => _statusFilter = o),
                          )),
                      ...['All', '<100ms', '100-500ms', '>500ms']
                          .map((o) => FilterChip(
                                label: Text(o),
                                selected: _durationFilter == o,
                                onSelected: (_) =>
                                    setState(() => _durationFilter = o),
                              )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_filteredTraces.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                            child: Text('No traces found',
                                style: theme.textTheme.bodyMedium)),
                      ),
                    )
                  else
                    ..._filteredTraces.map(
                      (trace) => _TraceListItem(
                        trace: trace,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TraceDetailsScreen(trace: trace),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _TraceItem {
  final String method;
  final String path;
  final int status;
  final int durationMs;
  final String traceId;

  _TraceItem({
    required this.method,
    required this.path,
    required this.status,
    required this.durationMs,
    this.traceId = '',
  });
}

class _TraceListItem extends StatelessWidget {
  final _TraceItem trace;
  final VoidCallback onTap;

  const _TraceListItem({required this.trace, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
