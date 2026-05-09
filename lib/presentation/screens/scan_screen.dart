import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'main_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Device Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement scan logic (Milestone 3)
                // For now, navigate to main screen for testing
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              icon: const Icon(Icons.bluetooth_searching, size: 28),
              label: const Text('Scan for Devices'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Mock device list for visual testing (will be replaced with real DeviceListItem in Milestone 3)
          Expanded(
            child: ListView(
              children: [
                _buildMockDeviceCard('NUS-Py', 'AA:BB:CC:DD:EE:FF', context),
                _buildMockDeviceCard('Unknown Device', '11:22:33:44:55:66', context),
                _buildMockDeviceCard('Arduino BLE', 'FF:EE:DD:CC:BB:AA', context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockDeviceCard(String deviceName, String macAddress, BuildContext context) {
    final theme = Theme.of(context);
    final technicalTheme = theme.extension<TechnicalTextTheme>()!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: Colors.blue),
        title: Text(
          deviceName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          macAddress,
          style: technicalTheme.deviceId,
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Mock action - navigate to MainScreen for visual testing
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }
}
