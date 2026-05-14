import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ble_connection_state.dart';
import '../../core/models/chart_data_point.dart';
import '../../data/worker_isolate.dart';
import '../providers/ble_provider.dart';
import '../providers/chart_provider.dart';
import '../widgets/device_list_item.dart';
import '../widgets/date_time_widget.dart';
import 'main_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  WorkerIsolate? _workerIsolate;

  @override
  void dispose() {
    _workerIsolate?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleProvider);
    final bleNotifier = ref.read(bleProvider.notifier);

    // Listen for errors and show toast (SnackBar)
    ref.listen<BleState>(bleProvider, (previous, next) {
      // Show toast if there's a new error message
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLE Device Scanner',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: bleState.connectionState == BleConnectionState.scanning
                  ? null // Disable button while scanning
                  : () async {
                      await bleNotifier.startScanning();
                    },
              icon: Icon(
                bleState.connectionState == BleConnectionState.scanning
                    ? Icons.bluetooth_searching
                    : Icons.bluetooth,
                size: 20,
              ),
              label: Text(
                bleState.connectionState == BleConnectionState.scanning
                    ? 'Scanning...'
                    : 'Scan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and time display
          const DateTimeWidget(),

          const SizedBox(height: 8),

          // Device list
          Expanded(
            child: bleState.discoveredDevices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        bleState.connectionState == BleConnectionState.scanning
                            ? 'Searching for devices...'
                            : 'No devices found. Tap "Scan for Devices" to start.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: bleState.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final result = bleState.discoveredDevices[index];
                      return DeviceListItem(
                        result: result,
                        onConnect: () async {
                          debugPrint('[ScanScreen] Connect button tapped for ${result.device.platformName}');

                          // Guard: Prevent connection if already connecting or connected
                          if (bleState.connectionState == BleConnectionState.connecting) {
                            debugPrint('[ScanScreen] ⚠️ Already connecting, ignoring tap');
                            return;
                          }
                          if (bleState.connectionState == BleConnectionState.connected) {
                            debugPrint('[ScanScreen] ⚠️ Already connected, ignoring tap');
                            return;
                          }

                          // Capture navigator, messenger, and chart notifier before async gap
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final theme = Theme.of(context);
                          final chartNotifier = ref.read(chartProvider.notifier);

                          debugPrint('[ScanScreen] Spawning worker isolate...');

                          // Spawn worker isolate with hardcoded transformation (M7)
                          _workerIsolate = WorkerIsolate(
                            onProcessedSamples: (processedSamples) {
                              // Convert ProcessedSamples to ChartDataPoints
                              final chartPoints = processedSamples.map((sample) {
                                return ChartDataPoint.fromProcessedSample(
                                  timestamp: sample.timestamp,
                                  rawValue: sample.rawValue,
                                  processedValue: sample.processedValue,
                                );
                              }).toList();

                              chartNotifier.addDataPoints(chartPoints);
                              debugPrint('[ScanScreen] ✅ Added ${chartPoints.length} processed points to chart');
                            },
                          );

                          // Spawn isolate (transformation: processed = raw * 0.12 + 34)
                          await _workerIsolate!.spawn();

                          debugPrint('[ScanScreen] Initiating connection...');

                          // Connect to device
                          final success = await bleNotifier.connectToDevice(
                            result.device,
                            onDataReceived: (bytes) {
                              // Update state with received bytes for UI display
                              bleNotifier.updateReceivedBytes(bytes);

                              // Send bytes to worker isolate for processing
                              _workerIsolate?.processBytes(bytes);
                            },
                          );

                          if (success) {
                            debugPrint('[ScanScreen] ✅ Connection successful, navigating to MainScreen');
                            // Navigate to main screen ONLY after successful connection
                            // Note: Scan was already stopped during connection (BleConnectionManager:48)
                            // so we don't need to call stopScanning() again
                            navigator.push(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                            );
                            debugPrint('[ScanScreen] ✅ Navigation to MainScreen complete');
                          } else {
                            debugPrint('[ScanScreen] ❌ Connection failed, showing error');
                            // Show error
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  bleState.errorMessage ?? 'Connection failed',
                                ),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
