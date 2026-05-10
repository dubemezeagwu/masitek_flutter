import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        // Very light background matching other widgets
        color: const Color(0xFFF5F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cardBorderBlack,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadowBlack,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Live chart will appear here',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Raw & Processed Series',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
