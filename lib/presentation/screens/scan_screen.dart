import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/models/ble_connection_state.dart';
import '../../core/models/chart_data_point.dart';
import '../../data/isolate/worker_isolate.dart';
import '../providers/ble_provider.dart';
import '../providers/camera_provider.dart';
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

      // Note: No error handling here - individual operations will check
      // permissions again and show specific error messages if needed
      debugPrint('[ScanScreen] ✅ Upfront permission request completed');
    } catch (e) {
      debugPrint('[ScanScreen] ⚠️ Error requesting permissions: $e');
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
              onPressed: bleState.connectionState == BleConnectionState.scanning ||
                      bleState.connectionState == BleConnectionState.connected
                  ? null // Disable button while scanning or connected
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

          // Connected device banner (show when connected)
          if (bleState.connectionState == BleConnectionState.connected &&
              bleState.connectedDevice != null)
            ConnectedDeviceBanner(
              deviceName: bleState.connectedDevice!.platformName.isNotEmpty
                  ? bleState.connectedDevice!.platformName
                  : 'Unknown Device',
              onDisconnect: () async {
                debugPrint('[ScanScreen] Disconnect button tapped');
                await bleNotifier.disconnect();
                // Clear device list after disconnect
                debugPrint('[ScanScreen] Connection closed, device list will be cleared on next scan');
              },
              onReturnToSession: () {
                debugPrint('[ScanScreen] Go to Session button tapped');
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
                  debugPrint('[ScanScreen] ⚠️ Worker isolate not available');
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

                          // Capture messenger, chart notifier, and camera notifier before async gap
                          final messenger = ScaffoldMessenger.of(context);
                          final theme = Theme.of(context);
                          final chartNotifier = ref.read(chartProvider.notifier);
                          final cameraNotifier = ref.read(cameraProvider.notifier);

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

                          // Initialize camera (back camera for recording)
                          debugPrint('[ScanScreen] Initializing camera...');
                          final cameraInitialized = await cameraNotifier.initialize();
                          if (!cameraInitialized) {
                            debugPrint('[ScanScreen] ⚠️ Camera initialization failed (permission denied or unavailable)');
                            // Show warning but continue - BLE works independently
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Camera unavailable - recording disabled'),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            debugPrint('[ScanScreen] ✅ Camera initialized successfully');
                          }

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
                            debugPrint('[ScanScreen] ✅ Connection successful');
                            // Show success message - user can now click "Go to Session" button
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Connected! Click "Go to Session" to start recording.'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
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
