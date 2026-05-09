import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HexPreviewWidget extends StatelessWidget {
  final String hexString;

  const HexPreviewWidget({
    super.key,
    required this.hexString,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final technicalTheme = theme.extension<TechnicalTextTheme>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Payload (hex)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hexString,
            style: technicalTheme.hexData,
          ),
        ],
      ),
    );
  }
}
