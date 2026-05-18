import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/models/ble_connection_state.dart';
import '../../core/models/chart_data_point.dart';
import '../../core/extensions/date_time_extensions.dart';
import '../../data/isolate/worker_isolate.dart';
import '../providers/ble_provider.dart';
import '../providers/chart_provider.dart';
import '../widgets/device_list_item.dart';
import '../widgets/date_time_widget.dart';
import '../widgets/connected_device_banner.dart';
import 'main_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  WorkerIsolate? _workerIsolate;

  @override
  void initState() {
    super.initState();
    // Request all permissions upfront on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAllPermissionsUpfront();
    });
  }

  /// Request all required permissions upfront (BLE + Camera + Microphone).
  ///
  /// This runs once on app launch to avoid interrupting user workflow later.
  /// Individual permission checks still exist as safety guards.
  Future<void> _requestAllPermissionsUpfront() async {
    try {
      // Get Android SDK version for BLE permission branching
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // BLE permissions (SDK-branched)
      List<Permission> blePermissions;
      if (sdkInt >= 31) {
        // Android 12+ (API 31+)
        blePermissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];
      } else {
        // Android 6-11 (API 23-30)
        blePermissions = [Permission.location];
      }

      // Camera and Microphone permissions
      final cameraPermission = Permission.camera;
      final microphonePermission = Permission.microphone;

      // Request all at once
      final allPermissions = [...blePermissions, cameraPermission, microphonePermission];
      await allPermissions.request();
    } catch (e) {
      // Continue anyway - safety checks will catch this later
    }
  }

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
        title: Text(
          DateTime.now().greeting,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: bleState.connectionState == BleConnectionState.connected
                  ? null // Disable button when connected
                  : () async {
                      // Handles double-tap gracefully (stops current scan, starts fresh)
                      await bleNotifier.startScanning();
                    },
              icon: const Icon(
                Icons.bluetooth,
                size: 20,
              ),
              label: const Text(
                'Scan',
                style: TextStyle(
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

          // Connected device banner (show when connected)
          if (bleState.connectionState == BleConnectionState.connected &&
              bleState.connectedDevice != null)
            ConnectedDeviceBanner(
              deviceName: bleState.connectedDevice!.platformName.isNotEmpty
                  ? bleState.connectedDevice!.platformName
                  : 'Unknown Device',
              currentRssi: bleState.currentRssi,
              onDisconnect: () async {
                await bleNotifier.disconnect();
              },
              onReturnToSession: () {
                // Navigate to MainScreen with existing worker isolate
                if (_workerIsolate != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainScreen(
                        workerIsolate: _workerIsolate!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session not ready. Please reconnect.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

          if (bleState.connectionState == BleConnectionState.connected)
            const SizedBox(height: 8),

          // Device list
          Expanded(
            child: bleState.connectionState == BleConnectionState.connected
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Device connected. Disconnect to scan for other devices.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : bleState.discoveredDevices.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            bleState.connectionState == BleConnectionState.scanning
                                ? 'Searching for devices...'
                                : 'No devices found. Tap "Scan" to start.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Device count header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              '${bleState.discoveredDevices.length} ${bleState.discoveredDevices.length == 1 ? 'device' : 'devices'} found',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Device list
                          Expanded(
                            child: ListView.builder(
                              itemCount: bleState.discoveredDevices.length,
                              itemBuilder: (context, index) {
                                final result = bleState.discoveredDevices[index];
                                return DeviceListItem(
                                  result: result,
                                  connectionState: bleState.connectionState,
                                  connectingDeviceId: bleState.connectedDevice?.remoteId.toString(),
                                  onConnect: () async {
                                    // Guard: Prevent connection if already connecting or connected
                                    if (bleState.connectionState == BleConnectionState.connecting ||
                                        bleState.connectionState == BleConnectionState.connected) {
                                      return;
                                    }

                                    // Capture messenger and chart notifier before async gap
                                    final messenger = ScaffoldMessenger.of(context);
                                    final theme = Theme.of(context);
                                    final chartNotifier = ref.read(chartProvider.notifier);

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
                                      },
                                    );

                                    // Spawn isolate (transformation: processed = raw * 0.12 + 34)
                                    await _workerIsolate!.spawn();

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
                                      // Show success message - user can now click "Go to Session" button
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: const Text('Connected! Click "Go to Session" to start recording.'),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
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
          ),
        ],
      ),
    );
  }
}
