import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/theme/app_theme.dart';

/// Reusable widget for displaying a discovered BLE device in a list.
///
/// Used in Milestone 3+ when BLE scanning is implemented.
/// Takes a ScanResult from flutter_blue_plus and displays:
/// - Device name (or "Unknown Device" if empty)
/// - Device MAC address
/// - "Connect" button
class DeviceListItem extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;

  const DeviceListItem({
    super.key,
    required this.result,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final technicalTheme = theme.extension<TechnicalTextTheme>()!;
    final device = result.device;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        // Very light blue background, almost white (matching doc-sync)
        color: const Color(0xFFF5F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.cardBorderBlack,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadowBlack.withOpacity(0.4),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          deviceName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          device.remoteId.toString(),
          style: technicalTheme.deviceId.copyWith(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: onConnect,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            minimumSize: const Size(70, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Connect',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
