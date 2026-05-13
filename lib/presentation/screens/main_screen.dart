import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ble_connection_state.dart';
import '../providers/ble_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/data_preview_row.dart';
import '../widgets/chart_placeholder.dart';
import '../widgets/date_time_widget.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);

    // Determine status text and color based on connection state
    final String statusText;
    final Color statusColor;

    switch (bleState.connectionState) {
      case BleConnectionState.connected:
        statusText = 'Connected';
        statusColor = Colors.green;
        break;
      case BleConnectionState.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.orange;
        break;
      case BleConnectionState.reconnecting:
        statusText = 'Reconnecting...';
        statusColor = Colors.amber;
        break;
      case BleConnectionState.disconnected:
        statusText = 'Disconnected';
        statusColor = Colors.red;
        break;
      case BleConnectionState.failed:
        statusText = 'Connection Failed';
        statusColor = Colors.red;
        break;
      case BleConnectionState.scanning:
        statusText = 'Scanning...';
        statusColor = Colors.blue;
        break;
    }

    // Get device name for title, fallback to default if null/empty
    final deviceName = bleState.connectedDevice?.platformName;
    final title = (deviceName != null && deviceName.isNotEmpty)
        ? deviceName
        : 'BLE Live Monitor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top row: Date/time and connection status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Date and time (left side)
                const Expanded(
                  child: DateTimeWidget(),
                ),

                const SizedBox(width: 12),

                // Connection status (right side)
                ConnectionStatusBar(
                  status: statusText,
                  color: statusColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Data preview - compact row showing hex and decoded message
          DataPreviewRow(
            bytes: bleState.lastReceivedBytes,
          ),

          const SizedBox(height: 8),

          // Chart placeholder - will be replaced with fl_chart in Milestone 6
          const Expanded(
            child: ChartPlaceholder(),
          ),

          const SizedBox(height: 16),
        ],
      ),
      // FAB for starting/stopping data recording
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement scan start/stop (Milestone 6+)
        },
        icon: const Icon(Icons.play_arrow, size: 24),
        label: const Text(
          'Start Scan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 4,
      ),
    );
  }
}
