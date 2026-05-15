import 'package:flutter/material.dart';

class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        // Simple white background for data clarity
        color: Colors.white,
        // Simple thin black border - no fancy styling for data viz
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
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
