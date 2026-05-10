import 'package:flutter/material.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/hex_preview_widget.dart';
import '../widgets/chart_placeholder.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLE Live Monitor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Status bar - shows connection state
          const ConnectionStatusBar(
            status: 'Disconnected',
            color: Colors.red,
          ),

          // Hex preview - shows last received payload
          const HexPreviewWidget(
            hexString: '00 00 00 00 00 00 00 00',
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
