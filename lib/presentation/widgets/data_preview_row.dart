import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Compact row showing both hex bytes and decoded message.
///
/// Format: [Hex: 63 6F] | [Message: congo]
/// Color highlights when data is present.
class DataPreviewRow extends StatelessWidget {
  final List<int>? bytes;

  const DataPreviewRow({
    super.key,
    this.bytes,
  });

  /// Converts byte array to hex string (e.g., [99, 111] → "63 6F")
  String _bytesToHex() {
    if (bytes == null || bytes!.isEmpty) {
      return '-- -- -- --';
    }
    return bytes!.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  /// Decodes byte array to UTF-8 string.
  String _decodeMessage() {
    if (bytes == null || bytes!.isEmpty) {
      return 'No data';
    }

    try {
      return utf8.decode(bytes!);
    } catch (e) {
      return 'Binary data';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = bytes != null && bytes!.isNotEmpty;
    final hexValue = _bytesToHex();
    final messageValue = _decodeMessage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: hasData ? AppTheme.cyan.withValues(alpha: 0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasData ? AppTheme.cyan.withValues(alpha: 0.4) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Hex value (left side)
          Expanded(
            flex: 5,
            child: Text(
              hexValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: hasData ? Colors.black87 : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Divider
          Container(
            height: 16,
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: hasData ? AppTheme.cyan.withValues(alpha: 0.3) : Colors.grey.shade300,
          ),

          // Decoded message (right side)
          Expanded(
            flex: 4,
            child: Text(
              messageValue,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasData ? AppTheme.teal : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
