// lib/screens/traces_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trace_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/request_provider.dart';
import '../screens/request_studio_screen.dart';
import '../widgets/common_widgets.dart';


/// Traces Screen - Displays distributed traces for debugging
/// Shows trace timeline, spans, and allows filtering and replay
class TracesScreen extends StatefulWidget {
  final VoidCallback? onReplayToRequest;
  const TracesScreen({Key? key, this.onReplayToRequest}) : super(key: key);

  @override
  State<TracesScreen> createState() => _TracesScreenState();
}

class _TracesScreenState extends State<TracesScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  
  // Filter states
  bool _showErrorsOnly = false;
  bool _showSlowRequestsOnly = false;
  int _slowRequestThreshold = 500; // Configurable threshold
  
  // Debouncing
  Timer? _debounceTimer;
  
  // Track last workspace ID to prevent redundant fetches
  String? _lastWorkspaceId;
  
  // Real-time updates
  Timer? _pollingTimer;
  static const int _pollingIntervalSeconds = 30;
  bool _isPollingEnabled = true;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreTraces = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _startPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final currentWorkspaceId = workspaceProvider.selectedWorkspace?['id'];

    // Only fetch if workspace ID changed or no traces loaded
    if (currentWorkspaceId != null &&
        (currentWorkspaceId != _lastWorkspaceId ||
         context.read<TraceProvider>().traces.isEmpty)) {
      _lastWorkspaceId = currentWorkspaceId;
      _resetPagination();
      // FIX: Wrap the call so it triggers AFTER the build is done
      Future.microtask(() => _loadTraces(reset: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manage polling based on app lifecycle
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _loadTraces(reset: true);
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  /// Start real-time polling for traces
  void _startPolling() {
    if (!_isPollingEnabled) return;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollingIntervalSeconds),
      (timer) {
        if (mounted && _isPollingEnabled) {
          _loadTraces(reset: true, showLoading: false);
        }
      },
    );
  }

  /// Stop real-time polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Reset pagination state
  void _resetPagination() {
    _currentPage = 1;
    _hasMoreTraces = true;
  }

  /// Handle scroll for pagination
  void _onScroll() {
    if (!_hasMoreTraces || _isLoadingMore || _isLoading) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTraces();
    }
  }

  /// Get color for HTTP method
  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.amber;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Load traces from backend with pagination support
  Future<void> _loadTraces({bool reset = false, bool showLoading = true}) async {
    final workspaceProvider = context.read<WorkspaceProvider>();
    final traceProvider = context.read<TraceProvider>();

    if (workspaceProvider.selectedWorkspace == null) {
      setState(() {
        _error = 'Please select a workspace first';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final success = await traceProvider.fetchTraces(
        workspaceProvider.selectedWorkspace!['id'],
        page: reset ? 1 : _currentPage,
        limit: 50, // Pagination limit
      );

      if (success && mounted) {
        setState(() {
          if (reset) {
            _currentPage = 1;
          }
          _hasMoreTraces = traceProvider.hasMoreTraces;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Load more traces for pagination
  Future<void> _loadMoreTraces() async {
    if (_isLoadingMore || !_hasMoreTraces) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadTraces(reset: false, showLoading: false);
  }

  /// Replay a trace with improved context safety
  Future<void> _replayTrace(BuildContext context, Map<String, dynamic> trace) async {
    // Capture navigator state before async gap
    final navigator = Navigator.of(context);
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get full trace details if needed
      Map<String, dynamic> fullTrace = trace;
      if (!trace.containsKey('spans') || trace['spans'] == null) {
        final traceProvider = context.read<TraceProvider>();
        final workspaceProvider = context.read<WorkspaceProvider>();
        final details = await traceProvider.getTraceDetails(
          workspaceProvider.selectedWorkspace!['id'],
          trace['id']
        );
        if (details != null) {
          fullTrace = details;
        }
      }

      // Extract request information from the trace with improved logic
      final requestData = await _extractRequestFromTrace(fullTrace);
      
      // Close loading dialog
      if (navigator.mounted) {
        navigator.pop();
      }

      // Navigate to Request Studio with the extracted request data
      if (navigator.mounted) {
        final requestProvider = context.read<RequestProvider>();
        
        // Set the request data in the provider
        requestProvider.setMethod(requestData['method'] ?? 'GET');
        requestProvider.setUrl(requestData['url'] ?? '');
        requestProvider.setHeaders(requestData['headers'] ?? {});
        requestProvider.setBody(requestData['body'] ?? '');
        
        // Navigate to Request Studio
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const RequestStudioScreen(),
          ),
        ).then((_) {
          // Clear the request data when returning (optional)
          requestProvider.clear();
        });
      }
    } catch (e) {
      // Close loading dialog if error occurs
      if (navigator.mounted) {
        navigator.pop();
      }
      
      // Show error message
      if (navigator.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to replay trace: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Extract HTTP request details from trace spans with improved protocol handling
  Future<Map<String, dynamic>> _extractRequestFromTrace(Map<String, dynamic> trace) async {
    // Default values
    String method = 'GET';
    String url = '';
    Map<String, String> headers = {};
    String body = '';
    String protocol = 'https'; // Default protocol
    
    // Try to find the root span or HTTP client span
    final spans = trace['spans'] as List? ?? [];
    
    // First, try to find protocol information from environment or tags
    for (var span in spans) {
      final tags = span['tags'] ?? span['attributes'] ?? {};
      
      // Check for protocol in tags
      if (tags['http.scheme'] != null) {
        protocol = tags['http.scheme'];
        break;
      }
      
      // Check for URL scheme
      final urlStr = tags['http.url'] ?? tags['url'] ?? '';
      if (urlStr.toString().startsWith('http://')) {
        protocol = 'http';
        break;
      }
    }
    
    // Look for HTTP-related spans
    for (var span in spans) {
      final spanName = (span['name'] ?? '').toString().toLowerCase();
      final tags = span['tags'] ?? span['attributes'] ?? {};
      
      // Check if this span contains HTTP request info
      if (spanName.contains('http') || 
          spanName.contains('request') || 
          spanName.contains('api') ||
          tags.containsKey('http.method') ||
          tags.containsKey('http.url')) {
        
        // Extract method
        method = tags['http.method'] ?? 
                tags['method'] ?? 
                tags['http.request.method'] ?? 
                method;
        
        // Extract URL with proper protocol handling
        String rawUrl = tags['http.url'] ?? 
                       tags['url'] ?? 
                       tags['http.target'] ?? 
                       tags['http.request.uri'] ?? 
                       '';
        
        if (rawUrl.isNotEmpty) {
          // If URL doesn't have protocol, add the detected protocol
          if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
            // Check if it's a full hostname or just a path
            if (rawUrl.startsWith('//')) {
              url = '$protocol:$rawUrl';
            } else if (rawUrl.startsWith('/')) {
              // Need to construct from service name
              final service = span['service'] ?? trace['service'] ?? '';
              if (service.isNotEmpty) {
                url = '$protocol://$service$rawUrl';
              } else {
                url = '$protocol://unknown$rawUrl';
              }
            } else {
              url = '$protocol://$rawUrl';
            }
          } else {
            url = rawUrl;
          }
        }
        
        // Extract headers
        if (tags['http.request.headers'] != null) {
          headers = Map<String, String>.from(tags['http.request.headers']);
        } else if (tags['headers'] != null) {
          headers = Map<String, String>.from(tags['headers']);
        }
        
        // Extract request body
        body = tags['http.request.body'] ?? 
               tags['request.body'] ?? 
               tags['body'] ?? 
               tags['http.request.body.text'] ??
               '';
        
        // If we found a valid URL, break
        if (url.isNotEmpty && url != '$protocol://unknown/') {
          break;
        }
      }
    }
    
    // If no URL found, try to construct from trace info with better defaults
    if (url.isEmpty || url == '$protocol://unknown/') {
      final service = trace['service'] ?? '';
      final path = trace['path'] ?? '';
      final host = trace['host'] ?? trace['hostname'] ?? '';
      
      method = trace['method'] ?? method;
      
      if (service.isNotEmpty) {
        if (path.isNotEmpty) {
          url = '$protocol://$service$path';
        } else {
          url = '$protocol://$service/';
        }
      } else if (host.isNotEmpty) {
        url = '$protocol://$host/';
      }
    }
    
    return {
      'method': method.toUpperCase(),
      'url': url,
      'headers': headers,
      'body': body,
    };
  }

  /// View trace details
  void _viewTraceDetails(Map<String, dynamic> trace) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TraceDetailScreen(
          trace: trace,
          onReplay: () => _replayTrace(context, trace),
          slowRequestThreshold: _slowRequestThreshold,
        ),
      ),
    );
  }

  /// Debounced search
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
        // Reset pagination when searching
        _resetPagination();
        _loadTraces(reset: true, showLoading: false);
      }
    });
  }

  /// Toggle real-time polling
  void _togglePolling() {
    setState(() {
      _isPollingEnabled = !_isPollingEnabled;
      if (_isPollingEnabled) {
        _startPolling();
      } else {
        _stopPolling();
      }
    });
  }

  /// Show threshold settings dialog
  void _showThresholdDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Slow Request Threshold'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set the threshold for slow requests (in milliseconds)',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThresholdOption(
                      context,
                      '200ms',
                      200,
                      _slowRequestThreshold,
                      (value) => setDialogState(() => _slowRequestThreshold = value),
                    ),
                    _buildThresholdOption(
                      context,
                      '500ms',
                      500,
                      _slowRequestThreshold,
                      (value) => setDialogState(() => _slowRequestThreshold = value),
                    ),
                    _buildThresholdOption(
                      context,
                      '1000ms',
                      1000,
                      _slowRequestThreshold,
                      (value) => setDialogState(() => _slowRequestThreshold = value),
                    ),
                    _buildThresholdOption(
                      context,
                      '2000ms',
                      2000,
                      _slowRequestThreshold,
                      (value) => setDialogState(() => _slowRequestThreshold = value),
                    ),
                  ],
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
                  setState(() {}); // Apply new threshold
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThresholdOption(
    BuildContext context,
    String label,
    int value,
    int currentValue,
    Function(int) onTap,
  ) {
    final isSelected = currentValue == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distributed Traces'),
        actions: [
          // Real-time indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isPollingEnabled ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isPollingEnabled ? 'Live' : 'Paused',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isPollingEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isPollingEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePolling,
            tooltip: _isPollingEnabled ? 'Pause updates' : 'Resume updates',
          ),
          // Threshold settings
          IconButton(
            icon: const Icon(Icons.speed),
            onPressed: _showThresholdDialog,
            tooltip: 'Slow request threshold',
          ),
          // Filter indicator badge
          if (_showErrorsOnly || _showSlowRequestsOnly || _searchQuery.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTraces(reset: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && context.read<TraceProvider>().traces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorDisplay(
        message: _error!,
        onRetry: () => _loadTraces(reset: true),
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search traces by ID, service, method or path...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  /// List of traces with pagination
  Widget _buildTracesList() {
    return Consumer<TraceProvider>(
      builder: (context, traceProvider, child) {
        final traces = traceProvider.traces.where((trace) {
          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            final traceId = trace['id']?.toString().toLowerCase() ?? '';
            final service = trace['service']?.toString().toLowerCase() ?? '';
            final method = trace['method']?.toString().toLowerCase() ?? '';
            final path = trace['path']?.toString().toLowerCase() ?? '';
            final matchesSearch = traceId.contains(_searchQuery) ||
                service.contains(_searchQuery) ||
                method.contains(_searchQuery) ||
                path.contains(_searchQuery);
            if (!matchesSearch) return false;
          }

          // Apply errors only filter
          if (_showErrorsOnly) {
            final status = trace['status']?.toString().toLowerCase() ?? '';
            if (status != 'error') return false;
          }

          // Apply slow requests filter with configurable threshold
          if (_showSlowRequestsOnly) {
            final duration = trace['duration'] ?? 0;
            if (duration < _slowRequestThreshold) return false;
          }

          return true;
        }).toList();

        if (traces.isEmpty && !_isLoading) {
        return EmptyState(
            icon: Icons.timeline,
            message: _getEmptyStateMessage(),
            description: _getEmptyStateDescription(),
            actionButton: (!_showErrorsOnly && !_showSlowRequestsOnly && _searchQuery.isEmpty) ? ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestStudioScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Create Request'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ) : null,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: traces.length + (_hasMoreTraces ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == traces.length) {
              return _buildLoadingMoreIndicator();
            }
            return _buildTraceCard(traces[index]);
          },
        );
      },
    );
  }

  /// Loading indicator for pagination
  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const CircularProgressIndicator()
          : const SizedBox(),
    );
  }

  /// Get empty state message based on active filters
  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'No matching traces found';
    }
    if (_showErrorsOnly || _showSlowRequestsOnly) {
      return 'No traces match your filters';
    }
    return 'No traces found';
  }

  /// Get empty state description based on active filters
  String _getEmptyStateDescription() {
    if (_searchQuery.isNotEmpty) {
      return 'Try adjusting your search query';
    }
    if (_showErrorsOnly || _showSlowRequestsOnly) {
      return 'Try clearing some filters to see more traces';
    }
    return 'Execute some API requests to see traces here';
  }

  /// Get empty state action button
  Widget? _getEmptyStateAction() {
    if (!_showErrorsOnly && !_showSlowRequestsOnly && _searchQuery.isEmpty) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RequestStudioScreen(),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Create Request'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    return null;
  }

  /// Individual trace card - Enhanced with Pro styling
  Widget _buildTraceCard(Map<String, dynamic> trace) {
    final duration = trace['duration'] ?? 0;
    final spanCount = trace['span_count'] ?? 0;
    final service = trace['service'] ?? 'Unknown';
    final status = trace['status'] ?? 'success';
    final timestamp = trace['timestamp'] ?? DateTime.now().toString();

    // Enhanced trace data
    final method = trace['method'] ?? 'GET';
    final path = trace['path'] ?? '/api/v1/resource';
    final isError = status.toLowerCase() == 'error';
    final isSlow = duration >= _slowRequestThreshold;
    final hasReplayData = _hasReplayData(trace);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError ? Colors.red.shade100 : 
                 isSlow ? Colors.orange.shade100 : 
                 Colors.grey.shade200,
          width: isError || isSlow ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewTraceDetails(trace),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Service + Status + Duration + Replay button
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
                        const SizedBox(height: 2),
                        Text(
                          'Trace: ${_truncateTraceId(trace['id'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasReplayData)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          Icons.play_circle_filled,
                          color: Colors.blue.shade600,
                          size: 28,
                        ),
                        onPressed: () {
                          _replayTrace(context, trace);
                        },
                        tooltip: 'Replay this trace',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  _buildDurationChip(duration, isSlow),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // HTTP Method and Path - Professional API styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getMethodColor(method).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        method,
                        style: TextStyle(
                          color: _getMethodColor(method),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        path,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Bottom row: Spans + Timestamp
              Row(
                children: [
                  _buildInfoChip(
                    Icons.account_tree,
                    '$spanCount ${spanCount == 1 ? 'span' : 'spans'}',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.access_time,
                    _formatTimestamp(timestamp),
                  ),
                  if (isError) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isSlow && !isError) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Slow',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if trace has replayable data
  bool _hasReplayData(Map<String, dynamic> trace) {
    return trace['method'] != null || 
           trace['path'] != null || 
           (trace['spans'] != null && (trace['spans'] as List).isNotEmpty);
  }

  /// Truncate trace ID for display
  String _truncateTraceId(String? id) {
    if (id == null) return 'N/A';
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 6)}';
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

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// Duration chip with slow request highlighting
  Widget _buildDurationChip(int duration, bool isSlow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDurationColor(duration).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getDurationColor(duration).withOpacity(0.3),
        ),
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

  /// Get color based on duration and threshold
  Color _getDurationColor(int duration) {
    if (duration < _slowRequestThreshold ~/ 2) return Colors.green.shade600;
    if (duration < _slowRequestThreshold) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  /// Info chip
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
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
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return timestamp;
    }
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Traces'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Show errors only'),
                  subtitle: const Text('Display only failed requests'),
                  value: _showErrorsOnly,
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setDialogState(() {
                      _showErrorsOnly = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Show slow requests'),
                  subtitle: Text('Requests taking >${_slowRequestThreshold}ms'),
                  value: _showSlowRequestsOnly,
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    setDialogState(() {
                      _showSlowRequestsOnly = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                const Divider(height: 32),
                if (_showErrorsOnly || _showSlowRequestsOnly || _searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        _showErrorsOnly = false;
                        _showSlowRequestsOnly = false;
                      });
                      setState(() {
                        _searchQuery = '';
                      });
                      _searchController.clear();
                      _resetPagination();
                      _loadTraces(reset: true, showLoading: false);
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear all filters'),
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
                  setState(() {}); // Trigger rebuild with new filters
                  _resetPagination();
                  _loadTraces(reset: true, showLoading: false);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Trace Detail Screen - Shows detailed trace information with Gantt chart and replay
class TraceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trace;
  final VoidCallback? onReplay;
  final int slowRequestThreshold;

  const TraceDetailScreen({
    Key? key, 
    required this.trace,
    this.onReplay,
    this.slowRequestThreshold = 500,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSlow = (trace['duration'] ?? 0) >= slowRequestThreshold;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace Details'),
        actions: [
          // Slow request indicator
          if (isSlow)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Slow',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          // Replay button
          if (onReplay != null)
            IconButton(
              icon: const Icon(Icons.play_circle_filled),
              onPressed: onReplay,
              tooltip: 'Replay this trace',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareTrace(context);
            },
            tooltip: 'Share trace',
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
            _buildTimelineVisualization(),
            const SizedBox(height: 24),
            _buildSpansList(),
          ],
        ),
      ),
    );
  }

  void _shareTrace(BuildContext context) {
    // Implement sharing logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTraceInfo() {
    final method = trace['method'] ?? 'GET';
    final path = trace['path'] ?? '/api/v1/resource';
    final status = trace['status'] ?? 'success';
    final isError = status.toLowerCase() == 'error';
    final duration = trace['duration'] ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMethodColor(method).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    method,
                    style: TextStyle(
                      color: _getMethodColor(method),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    path,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _buildInfoRow('Trace ID', trace['id'] ?? 'N/A', isMonospace: true),
            _buildInfoRow('Service', trace['service'] ?? 'N/A'),
            _buildInfoRow('Duration', '$duration ms',
              color: _getDurationColor(duration, slowRequestThreshold),
            ),
            _buildInfoRow('Status', status,
              color: isError ? Colors.red : Colors.green,
            ),
            _buildInfoRow('Timestamp', _formatDetailedTimestamp(trace['timestamp'])),
            if (trace['error_message'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trace['error_message'],
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.amber;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getDurationColor(int duration, int threshold) {
    if (duration < threshold ~/ 2) return Colors.green;
    if (duration < threshold) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInfoRow(String label, String value,
      {Color? color, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? Colors.grey.shade900,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gantt chart style timeline visualization
  Widget _buildTimelineVisualization() {
    final spans = trace['spans'] as List? ?? [];
    if (spans.isEmpty) return const SizedBox();

    final totalDuration = trace['duration'] ?? 1;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Timeline header with time scale
            Row(
              children: [
                const SizedBox(width: 120), // Span name column
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 2,
                            color: Colors.grey.shade300,
                          ),
                          // Time markers
                          ...List.generate(5, (i) {
                            final position = (constraints.maxWidth * (i / 4));
                            return Positioned(
                              left: position,
                              top: -4,
                              child: Container(
                                width: 2,
                                height: 10,
                                color: Colors.grey.shade400,
                              ),
                            );
                          }),
                          // Time labels
                          ...List.generate(5, (i) {
                            final position = (constraints.maxWidth * (i / 4)) - 20;
                            final timeMs = (totalDuration * (i / 4)).round();
                            return Positioned(
                              left: position,
                              top: 10,
                              child: Text(
                                '${timeMs}ms',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Spans timeline
            ...spans.mapIndexed((index, span) {
              final spanStart = span['start_time'] ?? 0;
              final spanDuration = span['duration'] ?? 0;
              final startPercent = (spanStart / totalDuration).clamp(0.0, 1.0);
              final widthPercent = (spanDuration / totalDuration).clamp(0.0, 1.0);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getSpanColor(span['name']),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              span['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 32,
                                width: double.infinity,
                                color: Colors.grey.shade50,
                              ),
                              Positioned(
                                left: constraints.maxWidth * startPercent,
                                child: Container(
                                  width: (constraints.maxWidth * widthPercent).clamp(40.0, constraints.maxWidth),
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: span['error'] == true 
                                        ? Colors.red.shade300.withOpacity(0.5)
                                        : _getSpanColor(span['name']),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: span['error'] == true 
                                          ? Colors.red.shade600
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${spanDuration}ms',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getSpanColor(String? spanName) {
    // Generate consistent colors based on span name
    if (spanName == null) return Colors.blue.shade300;
    final hash = spanName.hashCode;
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildSpansList() {
    final spans = trace['spans'] as List? ?? [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${spans.length} ${spans.length == 1 ? 'span' : 'spans'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (spans.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No spans available'),
                ),
              )
            else
              ...spans.map((span) => _buildSpanCard(span)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpanCard(dynamic span) {
    final isError = span['error'] == true;
    final duration = span['duration'] ?? 0;
    final service = span['service'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isError ? Icons.error : Icons.timeline,
            color: isError ? Colors.red : Colors.grey.shade700,
            size: 20,
          ),
        ),
        title: Text(
          span['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDurationColor(duration, slowRequestThreshold).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${duration}ms',
                    style: TextStyle(
                      fontSize: 11,
                      color: _getDurationColor(duration, slowRequestThreshold),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (service.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (span['tags'] != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTags(span['tags']),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: isError
            ? Icon(Icons.warning, color: Colors.red.shade700, size: 20)
            : Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
      ),
    );
  }

  String _formatTags(dynamic tags) {
    if (tags == null) return '';
    if (tags is Map) {
      final entries = tags.entries.take(3).map((e) => '${e.key}: ${e.value}').join(', ');
      return entries;
    }
    return tags.toString();
  }

  String _formatDetailedTimestamp(String? timestamp) {
    try {
      if (timestamp == null) return 'N/A';
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp ?? 'N/A';
    }
  }
}

// Extension method for indexed mapping
extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}