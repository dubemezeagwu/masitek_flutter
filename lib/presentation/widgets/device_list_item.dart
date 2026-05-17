import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/models/ble_connection_state.dart';
import '../../core/theme/app_theme.dart';

/// Reusable widget for displaying a discovered BLE device in a list.
///
/// Used in Milestone 3+ when BLE scanning is implemented.
/// Takes a ScanResult from flutter_blue_plus and displays:
/// - Device name (or "Unknown Device" if empty)
/// - Device MAC address
/// - "Connect" button with loading state
class DeviceListItem extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;
  final BleConnectionState connectionState;
  final String? connectingDeviceId;

  const DeviceListItem({
    super.key,
    required this.result,
    required this.onConnect,
    required this.connectionState,
    this.connectingDeviceId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final technicalTheme = theme.extension<TechnicalTextTheme>()!;
    final device = result.device;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';

    // Check if THIS device is currently being connected to
    final isConnecting = connectionState == BleConnectionState.connecting &&
        connectingDeviceId == device.remoteId.toString();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: isConnecting ? null : onConnect,
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
            trailing: isConnecting
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Connect',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.primaryColor,
                    ),
                  ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade300,
            indent: 16,
            endIndent: 16,
          ),
        ],
      ),
    );
  }
}
