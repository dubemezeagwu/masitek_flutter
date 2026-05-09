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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: Colors.blue),
        title: Text(
          deviceName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          device.remoteId.toString(),
          style: technicalTheme.deviceId,
        ),
        trailing: ElevatedButton(
          onPressed: onConnect,
          child: const Text('Connect'),
        ),
      ),
    );
  }
}
