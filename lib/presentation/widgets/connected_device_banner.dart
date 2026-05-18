import 'package:flutter/material.dart';
import '../../core/extensions/rssi_extensions.dart';

/// Banner widget displaying current BLE connection status.
///
/// Shows connected device name with signal strength indicator, plus options to disconnect or return to session.
/// Displayed at top of scan screen when a device is connected.
class ConnectedDeviceBanner extends StatelessWidget {
  final String deviceName;
  final int currentRssi;
  final VoidCallback onDisconnect;
  final VoidCallback onReturnToSession;

  const ConnectedDeviceBanner({
    super.key,
    required this.deviceName,
    required this.currentRssi,
    required this.onDisconnect,
    required this.onReturnToSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.shade700,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CURRENTLY CONNECTED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Device name with signal indicator
          Row(
            children: [
              const Text(
                'Device:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Signal strength indicator
              if (currentRssi != 0)
                Icon(
                  currentRssi.signalIcon,
                  color: currentRssi.signalColor,
                  size: 20,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Disconnect button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.bluetooth_disabled, size: 18),
                  label: const Text(
                    'Disconnect',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Go to session button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onReturnToSession,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text(
                    'Go to Session',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
