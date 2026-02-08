import 'package:flutter/material.dart';

class TestDetailsScreen extends StatelessWidget {
  final dynamic run;

  const TestDetailsScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(run.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryHeader(run: run),
            const SizedBox(height: 24),
            Text(
              'Failed Steps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _FailedStepCard(
              step: 'POST /api/auth/login',
              expected: '200',
              actual: '401',
              message: 'Authentication failed - invalid credentials',
            ),
            const SizedBox(height: 24),
            Text(
              'Diff Viewer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _DiffViewer(
              expected: '{"token": "abc123", "user": {"id": 1}}',
              actual: '{"error": "Invalid credentials", "code": 401}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final dynamic run;

  const _SummaryHeader({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              run.passed ? Icons.check_circle : Icons.cancel,
              size: 48,
              color: run.passed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Duration: ${run.duration}'),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(run.passed ? 'Passed' : 'Failed'),
                    backgroundColor: run.passed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
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

class _FailedStepCard extends StatefulWidget {
  final String step;
  final String expected;
  final String actual;
  final String message;

  const _FailedStepCard({
    required this.step,
    required this.expected,
    required this.actual,
    required this.message,
  });

  @override
  State<_FailedStepCard> createState() => _FailedStepCardState();
}

class _FailedStepCardState extends State<_FailedStepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.error.withOpacity(0.1),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.step,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                style: theme.textTheme.bodySmall,
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                Text('Expected: ${widget.expected}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
                Text('Actual: ${widget.actual}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffViewer extends StatefulWidget {
  final String expected;
  final String actual;

  const _DiffViewer({required this.expected, required this.actual});

  @override
  State<_DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends State<_DiffViewer> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Expected vs Actual'),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.expected,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Actual:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.actual,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
