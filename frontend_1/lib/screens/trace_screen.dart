// lib/screens/traces_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trace_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/common_widgets.dart';

/// Traces Screen - Displays distributed traces for debugging
/// Shows trace timeline, spans, and allows filtering
class TracesScreen extends StatefulWidget {
  const TracesScreen({Key? key}) : super(key: key);

  @override
  State<TracesScreen> createState() => _TracesScreenState();
}

class _TracesScreenState extends State<TracesScreen> {
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTraces();
  }

  /// Load traces from backend
  Future<void> _loadTraces() async {
    final workspaceProvider = context.read<WorkspaceProvider>();
    final traceProvider = context.read<TraceProvider>();

    if (workspaceProvider.selectedWorkspace == null) {
      setState(() {
        _error = 'Please select a workspace first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await traceProvider.fetchTraces(
        workspaceProvider.selectedWorkspace!['id'],
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// View trace details
  void _viewTraceDetails(Map<String, dynamic> trace) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TraceDetailScreen(trace: trace),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distributed Traces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTraces,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorDisplay(
        message: _error!,
        onRetry: _loadTraces,
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildTracesList()),
      ],
    );
  }

  /// Search bar for filtering traces
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search traces...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  /// List of traces
  Widget _buildTracesList() {
    return Consumer<TraceProvider>(
      builder: (context, traceProvider, child) {
        final traces = traceProvider.traces.where((trace) {
          if (_searchQuery.isEmpty) return true;
          final traceId = trace['id']?.toString().toLowerCase() ?? '';
          final service = trace['service']?.toString().toLowerCase() ?? '';
          return traceId.contains(_searchQuery) ||
              service.contains(_searchQuery);
        }).toList();

        if (traces.isEmpty) {
          return const EmptyState(
            icon: Icons.timeline,
            message: 'No traces found',
            description: 'Execute some API requests to see traces here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: traces.length,
          itemBuilder: (context, index) {
            return _buildTraceCard(traces[index]);
          },
        );
      },
    );
  }

  /// Individual trace card
  Widget _buildTraceCard(Map<String, dynamic> trace) {
    final duration = trace['duration'] ?? 0;
    final spanCount = trace['span_count'] ?? 0;
    final service = trace['service'] ?? 'Unknown';
    final status = trace['status'] ?? 'success';
    final timestamp = trace['timestamp'] ?? DateTime.now().toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewTraceDetails(trace),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIcon(status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Trace ID: ${trace['id']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDurationChip(duration),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.account_tree,
                    '$spanCount spans',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.access_time,
                    _formatTimestamp(timestamp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Status icon based on trace status
  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'error':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.warning;
        color = Colors.orange;
    }

    return Icon(icon, color: color, size: 24);
  }

  /// Duration chip
  Widget _buildDurationChip(int duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDurationColor(duration).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${duration}ms',
        style: TextStyle(
          color: _getDurationColor(duration),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Get color based on duration
  Color _getDurationColor(int duration) {
    if (duration < 100) return Colors.green;
    if (duration < 500) return Colors.orange;
    return Colors.red;
  }

  /// Info chip
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timestamp;
    }
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Traces'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show errors only'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Show slow requests (>500ms)'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadTraces();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

/// Trace Detail Screen - Shows detailed trace information
class TraceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trace;

  const TraceDetailScreen({Key? key, required this.trace}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share trace
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTraceInfo(),
            const SizedBox(height: 24),
            _buildSpansList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trace Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Trace ID', trace['id'] ?? 'N/A'),
            _buildInfoRow('Service', trace['service'] ?? 'N/A'),
            _buildInfoRow('Duration', '${trace['duration'] ?? 0}ms'),
            _buildInfoRow('Status', trace['status'] ?? 'N/A'),
            _buildInfoRow('Timestamp', trace['timestamp'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpansList() {
    final spans = trace['spans'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (spans.isEmpty)
          const Text('No spans available')
        else
          ...spans.map((span) => _buildSpanCard(span)).toList(),
      ],
    );
  }

  Widget _buildSpanCard(dynamic span) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.timeline),
        title: Text(span['name'] ?? 'Unknown'),
        subtitle: Text('${span['duration'] ?? 0}ms'),
        trailing: Icon(
          span['error'] == true ? Icons.error : Icons.check_circle,
          color: span['error'] == true ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}