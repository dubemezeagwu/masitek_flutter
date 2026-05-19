import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/models/ble_connection_state.dart';
import '../../core/extensions/date_time_extensions.dart';
import '../providers/ble_provider.dart';
import '../providers/worker_isolate_provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Request all permissions upfront on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAllPermissionsUpfront();
    });
  }

  Future<void> _requestAllPermissionsUpfront() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      List<Permission> blePermissions;
      if (sdkInt >= 31) {
        blePermissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];
      } else {
        blePermissions = [Permission.location];
      }

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
    super.dispose();
  }

  Future<void> _handleDeviceConnection(ScanResult result) async {
    final bleNotifier = ref.read(bleProvider.notifier);
    final bleState = ref.read(bleProvider);

    // Guard: Prevent connection if already connecting or connected
    if (bleState.connectionState == BleConnectionState.connecting ||
        bleState.connectionState == BleConnectionState.connected) {
      return;
    }

    // Capture context-dependent values before async gap
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final workerIsolateNotifier = ref.read(workerIsolateProvider.notifier);

    // Spawn worker isolate
    await workerIsolateNotifier.spawn();

    // Connect to device
    final success = await bleNotifier.connectToDevice(
      result.device,
      onDataReceived: (bytes) {
        bleNotifier.updateReceivedBytes(bytes);
        workerIsolateNotifier.processBytes(bytes);
      },
    );

    // Show feedback
    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Connected! Click "Go to Session" to start recording.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            bleState.errorMessage ?? 'Connection failed',
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleProvider);
    final bleNotifier = ref.read(bleProvider.notifier);

    // Listen for errors and show toast (SnackBar)
    ref.listen<BleState>(bleProvider, (previous, next) {
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
          const DateTimeWidget(),

          const SizedBox(height: 8),

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
                final workerIsolateState = ref.read(workerIsolateProvider);
                if (workerIsolateState.isSpawned) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(),
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
                                final isConnecting = bleState.connectionState == BleConnectionState.connecting &&
                                    bleState.connectedDevice?.remoteId.toString() == result.device.remoteId.toString();

                                return DeviceListItem(
                                  result: result,
                                  isConnecting: isConnecting,
                                  onConnect: () => _handleDeviceConnection(result),
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
