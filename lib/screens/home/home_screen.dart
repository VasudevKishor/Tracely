import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _environment = 'Production';
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Tracely'),
            actions: [
              PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(_environment, style: const TextStyle(fontSize: 14)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onSelected: (v) => setState(() => _environment = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'Production', child: Text('Production')),
                  const PopupMenuItem(value: 'Staging', child: Text('Staging')),
                  const PopupMenuItem(value: 'Development', child: Text('Development')),
                ],
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryCards(context),
                const SizedBox(height: 24),
                Text(
                  'Service Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildServiceList(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final theme = Theme.of(context);

    final cards = [
      _SummaryCard(
        title: 'Total Requests',
        value: '12,847',
        icon: Icons.analytics_rounded,
        color: theme.colorScheme.primary,
      ),
      _SummaryCard(
        title: 'Error Rate',
        value: '0.2%',
        icon: Icons.error_outline_rounded,
        color: Colors.orange,
      ),
      _SummaryCard(
        title: 'Avg Latency',
        value: '124ms',
        icon: Icons.speed_rounded,
        color: Colors.teal,
      ),
    ];

    return Column(
      children: cards.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: e.value.animate().fadeIn(delay: (e.key * 80).ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
      )).toList(),
    );
  }

  Widget _buildServiceList(BuildContext context) {
    final services = [
      ('Auth Service', 0),
      ('Payment API', 0),
      ('User Service', 1),
      ('Analytics', 2),
    ];

    return Column(
      children: services.map((s) => _ServiceItem(name: s.$1, status: s.$2)).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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

class _ServiceItem extends StatelessWidget {
  final String name;
  final int status; // 0=green, 1=yellow, 2=red

  const _ServiceItem({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [Colors.green, Colors.amber, Colors.red];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors[status],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors[status].withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        title: Text(name),
      ),
    );
  }
}
