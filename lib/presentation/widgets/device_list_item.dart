import '../../ble/app_ble.dart';
import '../../core/app_core.dart';

class DeviceListItem extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;
  final bool isConnecting;

  const DeviceListItem({
    super.key,
    required this.result,
    required this.onConnect,
    required this.isConnecting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = result.device;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';

    // Get signal strength metrics using RSSI extension
    final rssi = result.rssi;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: isConnecting ? null : onConnect,
            // Signal strength indicator (left side)
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  rssi.signalIcon,
                  color: rssi.signalColor,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  '$rssi dBm',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            title: Text(
              deviceName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.remoteId.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rssi.proximityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: rssi.signalColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
