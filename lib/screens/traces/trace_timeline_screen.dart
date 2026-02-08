import 'package:flutter/material.dart';

class TraceTimelineScreen extends StatefulWidget {
  final dynamic trace;

  const TraceTimelineScreen({super.key, required this.trace});

  @override
  State<TraceTimelineScreen> createState() => _TraceTimelineScreenState();
}

class _TraceTimelineScreenState extends State<TraceTimelineScreen> {
  int? _expandedIndex;

  final _spans = [
    _SpanData('Auth Service', 'validate_token', 12, false),
    _SpanData('User Service', 'get_user', 45, true),
    _SpanData('Database', 'query', 28, false),
    _SpanData('Cache', 'get', 3, false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDuration = _spans.map((s) => s.durationMs).reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _spans.length,
      itemBuilder: (context, i) {
        final span = _spans[i];
        final isExpanded = _expandedIndex == i;
        final isSlowest = span.durationMs == maxDuration;

        return _TimelineSpan(
          span: span,
          isExpanded: isExpanded,
          isSlowest: isSlowest,
          maxDuration: maxDuration,
          onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
        );
      },
    );
  }
}

class _SpanData {
  final String service;
  final String operation;
  final int durationMs;
  final bool isSlowest;

  _SpanData(this.service, this.operation, this.durationMs, this.isSlowest);
}

class _TimelineSpan extends StatelessWidget {
  final _SpanData span;
  final bool isExpanded;
  final bool isSlowest;
  final int maxDuration;
  final VoidCallback onTap;

  const _TimelineSpan({
    required this.span,
    required this.isExpanded,
    required this.isSlowest,
    required this.maxDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barWidth = (span.durationMs / maxDuration).clamp(0.1, 1.0);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isSlowest ? Colors.orange : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (isExpanded)
                  Container(
                    width: 2,
                    height: 40,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              span.service,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isSlowest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Slowest',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          span.operation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: barWidth,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            color: isSlowest ? Colors.orange : theme.colorScheme.primary,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${span.durationMs}ms',
                          style: theme.textTheme.labelSmall,
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          Text(
                            'Details: Service=${span.service}, Operation=${span.operation}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
