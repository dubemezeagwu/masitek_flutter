import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';

class ConnectionStatusBar extends StatelessWidget {
  final String status;
  final Color color;

  const ConnectionStatusBar({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: color.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Text(
            status,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color.darken(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
