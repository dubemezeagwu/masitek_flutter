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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // Very light background matching device list items
        color: const Color(0xFFF5F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cardBorderBlack,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadowBlack,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Payload (hex)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hexString,
            style: technicalTheme.hexData?.copyWith(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
