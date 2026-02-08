import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ToastNotification {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentToast?.remove();
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    Color backgroundColor;
    IconData icon;
    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        backgroundColor = theme.colorScheme.error;
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
        backgroundColor = theme.colorScheme.primary;
        icon = Icons.info_rounded;
        break;
    }

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn().slideY(begin: -1, end: 0, duration: 300.ms),
      ),
    );

    overlay.insert(_currentToast!);

    Future.delayed(duration, () {
      _currentToast?.remove();
      _currentToast = null;
    });
  }
}

enum ToastType { success, error, warning, info }
