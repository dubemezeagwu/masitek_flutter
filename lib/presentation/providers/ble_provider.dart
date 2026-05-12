import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ble_connection_state.dart';
import '../../ble/ble_permission_handler.dart';
import '../../ble/ble_scanner.dart';
import '../../ble/ble_connection_manager.dart';

/// BLE state provider managing scanning, connection, and device discovery.
///
/// Provides:
/// - Current connection state
/// - List of discovered devices
/// - Methods for scanning and connecting
/// - Permission handling
final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

/// BLE state data class.
class BleState {
  final BleConnectionState connectionState;
  final List<ScanResult> discoveredDevices;
  final BluetoothDevice? connectedDevice;
  final String? errorMessage;
  final int? connectionAttempt;

  const BleState({
    this.connectionState = BleConnectionState.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.errorMessage,
    this.connectionAttempt,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    List<ScanResult>? discoveredDevices,
    BluetoothDevice? connectedDevice,
    String? errorMessage,
    int? connectionAttempt,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage ?? this.errorMessage,
      connectionAttempt: connectionAttempt ?? this.connectionAttempt,
    );
  }
}

/// BLE state notifier managing all BLE operations.
class BleNotifier extends StateNotifier<BleState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  BleNotifier() : super(const BleState()) {
    // Listen to FlutterBluePlus scanning state to keep UI in sync
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      // If scan stopped but our state still shows scanning, reset it
      if (!isScanning && state.connectionState == BleConnectionState.scanning) {
        debugPrint('[Provider] Scan completed, resetting state to disconnected');
        state = state.copyWith(connectionState: BleConnectionState.disconnected);
      }
    });
  }

  /// Starts BLE scanning after checking permissions.
  ///
  /// Returns true if scanning started successfully, false otherwise.
  Future<bool> startScanning() async {
    // Check permissions first
    final hasPermissions = await BlePermissionHandler.checkBlePermissions();
    if (!hasPermissions) {
      final granted = await BlePermissionHandler.requestBlePermissions();
      if (!granted) {
        state = state.copyWith(
          connectionState: BleConnectionState.failed,
          errorMessage: 'BLE permissions denied. Please enable in Settings.',
        );
        return false;
      }
    }

    // Start scanning
    state = state.copyWith(
      connectionState: BleConnectionState.scanning,
      discoveredDevices: [],
      errorMessage: null,
    );

    try {
      _scanSubscription = BleScanner.scanForDevices().listen(
        (results) {
          // Update discovered devices in real-time
          state = state.copyWith(discoveredDevices: results);
        },
        onError: (error) {
          state = state.copyWith(
            connectionState: BleConnectionState.failed,
            errorMessage: 'Scan failed: $error',
          );
        },
        // Note: onDone is not used here because FlutterBluePlus.scanResults
        // is a broadcast stream that doesn't close. Instead, we listen to
        // FlutterBluePlus.isScanning in the constructor to track scan state.
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: 'Failed to start scan: $e',
      );
      return false;
    }
  }

  /// Stops BLE scanning.
  ///
  /// IMPORTANT: Does not change connection state if already connected.
  /// Only transitions to disconnected if we're in scanning state.
  Future<void> stopScanning() async {
    await _scanSubscription?.cancel();
    await BleScanner.stopScan();

    // Only set to disconnected if we're currently scanning
    // Don't overwrite connected/connecting states
    if (state.connectionState == BleConnectionState.scanning) {
      state = state.copyWith(connectionState: BleConnectionState.disconnected);
    }
  }

  /// Connects to a BLE device.
  ///
  /// Callback [onDataReceived] will be invoked for every BLE notification.
  /// Returns true if connection and subscription succeeded, false otherwise.
  ///
  /// GUARD: Prevents multiple simultaneous connection attempts.
  Future<bool> connectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    // Guard: Prevent multiple simultaneous connection attempts
    if (state.connectionState == BleConnectionState.connecting) {
      debugPrint('[Provider] ⚠️ Connection already in progress, ignoring duplicate request');
      return false;
    }

    // Guard: Prevent connecting while already connected
    if (state.connectionState == BleConnectionState.connected) {
      debugPrint('[Provider] ⚠️ Already connected to a device, ignoring duplicate request');
      return false;
    }

    debugPrint('[Provider] Starting connection to ${device.platformName}');
    state = state.copyWith(
      connectionState: BleConnectionState.connecting,
      connectedDevice: device,
      errorMessage: null,
    );

    try {
      _dataSubscription = await BleConnectionManager.connectToDevice(
        device,
        onDataReceived: onDataReceived,
      );

      debugPrint('[Provider] ✅ Connection successful, updating state to connected');
      state = state.copyWith(connectionState: BleConnectionState.connected);
      return true;
    } catch (e) {
      debugPrint('[Provider] ❌ Connection failed: $e');
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: 'Connection failed: $e',
      );
      return false;
    }
  }

  /// Disconnects from the current device.
  Future<void> disconnect() async {
    if (state.connectedDevice != null) {
      await _dataSubscription?.cancel();
      await BleConnectionManager.disconnectDevice(state.connectedDevice!);
      state = state.copyWith(
        connectionState: BleConnectionState.disconnected,
        connectedDevice: null,
      );
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }
}
