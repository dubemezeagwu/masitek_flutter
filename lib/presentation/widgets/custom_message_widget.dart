import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget displaying decoded custom message from BLE bytes.
///
/// Takes raw byte array (e.g., [99, 111, 110, 103, 111])
/// and decodes it to readable text (e.g., "congo").
class CustomMessageWidget extends StatelessWidget {
  final List<int>? bytes;

  const CustomMessageWidget({
    super.key,
    this.bytes,
  });

  /// Decodes byte array to UTF-8 string.
  ///
  /// Returns empty string if bytes is null or empty.
  /// Falls back to showing raw bytes if decoding fails.
  String _decodeMessage() {
    if (bytes == null || bytes!.isEmpty) {
      return 'No message received';
    }

    try {
      // Try to decode as UTF-8 string
      return utf8.decode(bytes!);
    } catch (e) {
      // If decoding fails, show raw bytes
      return 'Invalid UTF-8: ${bytes!.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _decodeMessage();
    final bool isValidMessage = bytes != null && bytes!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isValidMessage ? AppTheme.cyan.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValidMessage ? AppTheme.cyan : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message_outlined,
                size: 16,
                color: isValidMessage ? AppTheme.teal : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Custom Message',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isValidMessage ? AppTheme.teal : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isValidMessage ? Colors.black87 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
