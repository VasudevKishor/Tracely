import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: isDark ? Colors.white12 : Colors.black12);
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingSkeleton(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 12),
        LoadingSkeleton(width: 200, height: 20),
        const SizedBox(height: 8),
        LoadingSkeleton(width: 150, height: 16),
      ],
    );
  }
}
