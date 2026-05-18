import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ble_connection_state.dart';
import '../../ble/ble_permission_handler.dart';
import '../../ble/ble_scanner.dart';
import '../../ble/ble_connection_manager.dart';

/// Converts technical error messages to user-friendly messages.
///
/// Technical errors are still printed to debug console for debugging.
/// Only common errors are mapped - others are simplified but kept technical.
String _getUserFriendlyError(String technicalError) {
  // Log technical error for debugging
  debugPrint('[Error] Technical: $technicalError');

  // Convert to lowercase for easier matching
  final error = technicalError.toLowerCase();

  // Map common errors to user-friendly messages
  if (error.contains('permission') && error.contains('denied')) {
    return 'Bluetooth permission needed. Please enable in Settings.';
  } else if (error.contains('nus service not found')) {
    return "This device isn't compatible.";
  } else if (error.contains('tx characteristic not found')) {
    return "Device doesn't support required features.";
  } else if (error.contains('connection failed') || error.contains('failed to connect')) {
    return "Couldn't connect to device. Please try again.";
  } else if (error.contains('scan failed') || error.contains('failed to start scan')) {
    return 'Bluetooth scan failed. Check Bluetooth is enabled.';
  } else if (error.contains('timeout')) {
    return 'Connection timed out. Device might be out of range.';
  } else if (error.contains('device disconnected')) {
    return 'Device disconnected unexpectedly.';
  } else {
    // For other errors, return simplified version (remove stack traces, etc.)
    // Keep first line only
    return technicalError.split('\n').first;
  }
}

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
  final List<int>? lastReceivedBytes;  // Last received BLE notification bytes
  final int currentRssi;  // Current signal strength (dBm), updated every 2 seconds when connected

  const BleState({
    this.connectionState = BleConnectionState.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.errorMessage,
    this.connectionAttempt,
    this.lastReceivedBytes,
    this.currentRssi = 0,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    List<ScanResult>? discoveredDevices,
    BluetoothDevice? connectedDevice,
    String? errorMessage,
    int? connectionAttempt,
    List<int>? lastReceivedBytes,
    int? currentRssi,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage ?? this.errorMessage,
      connectionAttempt: connectionAttempt ?? this.connectionAttempt,
      lastReceivedBytes: lastReceivedBytes ?? this.lastReceivedBytes,
      currentRssi: currentRssi ?? this.currentRssi,
    );
  }
}

/// BLE state notifier managing all BLE operations.
class BleNotifier extends StateNotifier<BleState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  Timer? _rssiTimer; // Periodic timer for RSSI polling (every 2 seconds)

  Function(List<int>)? _currentDataCallback; // Store for reconnect

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
  /// Permission check acts as safety guard (permissions requested upfront at app launch).
  ///
  /// If scan is already running, stops it first and starts fresh (handles double-tap).
  Future<bool> startScanning() async {
    // Guard: If already scanning, stop current scan first (double-tap handling)
    if (state.connectionState == BleConnectionState.scanning) {
      debugPrint('[Provider] Scan already running - restarting scan with fresh state');
      await _stopScanningInternal();
      // Small delay to ensure clean stop
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Check permissions (safety guard)
    final hasPermissions = await BlePermissionHandler.checkBlePermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: _getUserFriendlyError('BLE permissions denied'),
      );
      return false;
    }

    // Start scanning (clear devices for fresh start)
    state = state.copyWith(
      connectionState: BleConnectionState.scanning,
      discoveredDevices: [],
      errorMessage: null,
    );

    try {
      _scanSubscription = BleScanner.scanForDevices().listen(
        (results) {
          // Update discovered devices in real-time (RSSI updates every ~1 second)
          state = state.copyWith(discoveredDevices: results);
        },
        onError: (error) {
          state = state.copyWith(
            connectionState: BleConnectionState.failed,
            errorMessage: _getUserFriendlyError('Scan failed: $error'),
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
        errorMessage: _getUserFriendlyError('Failed to start scan: $e'),
      );
      return false;
    }
  }

  /// Internal method to stop scanning without changing state.
  ///
  /// Used for clean restart when double-tapping scan button.
  Future<void> _stopScanningInternal() async {
    await _scanSubscription?.cancel();
    await BleScanner.stopScan();
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
      // Store callback for reconnect
      _currentDataCallback = onDataReceived;

      _dataSubscription = await BleConnectionManager.connectToDevice(
        device,
        onDataReceived: onDataReceived,
      );

      state = state.copyWith(connectionState: BleConnectionState.connected);

      // Start RSSI polling for signal strength monitoring
      _startRssiPolling();

      // Set up connection state listener immediately after successful connection
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((connectionState) {
        debugPrint('[Provider] 📡 Connection state changed: $connectionState');

        if (connectionState == BluetoothConnectionState.disconnected) {
          debugPrint('[Provider] ⚠️ Disconnect detected! Current app state: ${state.connectionState}');

          // Only trigger reconnection if we're in connected state (not intentional disconnect)
          if (state.connectionState == BleConnectionState.connected) {
            debugPrint('[Provider] 🔄 Unexpected disconnect, attempting reconnection...');
            _attemptReconnection(device);
          } else {
            debugPrint('[Provider] Disconnect was intentional (state: ${state.connectionState}), not reconnecting');
          }
        }
      });

      return true;
    } catch (e) {
      debugPrint('[Provider] ❌ Connection failed: $e');
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: _getUserFriendlyError('Connection failed: $e'),
      );
      return false;
    }
  }

  /// Attempts to reconnect after unexpected disconnect.
  Future<void> _attemptReconnection(BluetoothDevice device) async {
    // Guard: Prevent multiple simultaneous reconnection attempts
    if (state.connectionState == BleConnectionState.reconnecting) {
      debugPrint('[Provider] ⚠️ Reconnection already in progress, ignoring duplicate request');
      return;
    }

    if (_currentDataCallback == null) {
      debugPrint('[Provider] ⚠️ No data callback available for reconnection');
      return;
    }

    // Update state to reconnecting
    debugPrint('[Provider] 🔄 Starting reconnection attempt...');
    state = state.copyWith(connectionState: BleConnectionState.reconnecting);

    try {
      debugPrint('[Provider] 🔄 Calling BleConnectionManager.reconnectToDevice()...');

      _dataSubscription = await BleConnectionManager.reconnectToDevice(
        device,
        onDataReceived: _currentDataCallback!,
      );

      state = state.copyWith(connectionState: BleConnectionState.connected);

      // Restart RSSI polling after successful reconnection
      _startRssiPolling();
    } catch (e) {
      debugPrint('[Provider] ❌ Reconnection failed after all attempts: $e');
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: _getUserFriendlyError('Reconnection failed: $e'),
      );
    }
  }

  /// Disconnects from the current device.
  Future<void> disconnect() async {
    if (state.connectedDevice != null) {
      debugPrint('[Provider] Intentional disconnect requested');

      // Stop RSSI polling
      _stopRssiPolling();

      // Set state to disconnected FIRST to prevent reconnection logic from triggering
      state = state.copyWith(
        connectionState: BleConnectionState.disconnected,
        discoveredDevices: [], // Clear device list on disconnect
      );

      await _dataSubscription?.cancel();
      await BleConnectionManager.disconnectDevice(state.connectedDevice!);

      state = state.copyWith(connectedDevice: null);
    }
  }

  /// Updates the last received bytes from BLE notification.
  ///
  /// Called by UI layer when data is received from device.
  void updateReceivedBytes(List<int> bytes) {
    state = state.copyWith(lastReceivedBytes: bytes);
  }

  /// Starts periodic RSSI polling (every 2 seconds).
  ///
  /// Called automatically after successful connection.
  void _startRssiPolling() {
    _rssiTimer?.cancel(); // Cancel any existing timer
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final device = state.connectedDevice;

      if (device != null && state.connectionState == BleConnectionState.connected) {
        try {
          final rssi = await device.readRssi();
          state = state.copyWith(currentRssi: rssi);
        } catch (e) {
          debugPrint('[Provider] ⚠️ Failed to read RSSI: $e');
        }
      }
    });
  }

  /// Stops RSSI polling.
  ///
  /// Called automatically on disconnect.
  void _stopRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
    state = state.copyWith(currentRssi: 0); // Reset RSSI
  }

  /// Pauses RSSI polling when app goes to background.
  ///
  /// Called from lifecycle observer (saves battery).
  void pauseRssiPolling() {
    debugPrint('[Provider] ⏸️ Pausing RSSI polling (app backgrounded)');
    _rssiTimer?.cancel();
    _rssiTimer = null;
    // Keep currentRssi value (don't reset to 0)
  }

  /// Resumes RSSI polling when app comes to foreground.
  ///
  /// Called from lifecycle observer.
  void resumeRssiPolling() {
    // Only resume if we're connected
    if (state.connectionState == BleConnectionState.connected) {
      debugPrint('[Provider] ▶️ Resuming RSSI polling (app foregrounded)');
      _startRssiPolling();
    }
  }

  @override
  void dispose() {
    _stopRssiPolling();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}
