import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants/ble_constants.dart';

/// Manages BLE connection lifecycle with proper sequencing and error handling.
///
/// Connection Flow (per CLAUDE.md):
/// 1. Stop scan before connecting (prevents connection failures on some Android devices)
/// 2. Connect with retry logic (exponential backoff: 1s, 2s, 4s, 8s, 16s)
/// 3. Discover services
/// 4. Find NUS service + TX characteristic
/// 5. Subscribe to notifications with auto-cleanup
/// 6. Navigate to main screen ONLY after successful subscription
class BleConnectionManager {
  // NUS (Nordic UART Service) UUIDs - using constants from BLEConstants
  static final Guid _nusServiceUuid = Guid(BLEConstants.nusServiceUuid);
  static final Guid _nusTxCharUuid = Guid(BLEConstants.nusTxCharUuid);

  static const int _maxConnectionAttempts = BLEConstants.maxConnectionAttempts;
  static final List<Duration> _retryBackoff = BLEConstants.reconnectBackoffSeconds
      .map((seconds) => Duration(seconds: seconds))
      .toList();

  /// Connects to a BLE device and subscribes to NUS TX characteristic.
  ///
  /// Returns the TX characteristic subscription stream on success.
  /// Throws [BleConnectionException] if connection or subscription fails.
  static Future<StreamSubscription<List<int>>> connectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    int attemptCount = 0;
    debugPrint('[BLE] Connecting to ${device.platformName}');

    while (attemptCount < _maxConnectionAttempts) {
      attemptCount++;

      try {
        // Stop scanning before connecting (CRITICAL)
        await FlutterBluePlus.stopScan();

        // Connect to device
        await device.connect(autoConnect: false);

        // Discover services (MUST be called after every connect/reconnect)
        final services = await device.discoverServices();

        // Find NUS service
        final nusService = services.firstWhere(
          (s) => s.uuid == _nusServiceUuid,
          orElse: () => throw BleConnectionException(
            'NUS service not found. Device not compatible.',
          ),
        );

        // Find TX characteristic
        final txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid == _nusTxCharUuid,
          orElse: () => throw BleConnectionException(
            'TX characteristic not found. Device not compatible.',
          ),
        );

        // Subscribe to notifications with auto-cleanup
        final subscription = txCharacteristic.onValueReceived.listen(onDataReceived);
        device.cancelWhenDisconnected(subscription, delayed: true);

        // Enable notifications
        try {
          await txCharacteristic.setNotifyValue(true);
        } on PlatformException catch (e) {
          if (e.code.contains('set_notification_failed')) {
            await device.disconnect();
            throw BleConnectionException(
              'Device rejected notification subscription (GATT error: ${e.code})',
            );
          }
          rethrow;
        }

        debugPrint('[BLE] ✅ Connected successfully');
        return subscription;
      } catch (e) {
        if (attemptCount < _maxConnectionAttempts) {
          await Future.delayed(_retryBackoff[attemptCount - 1]);
        } else {
          debugPrint('[BLE] ❌ Connection failed: $e');
          throw BleConnectionException(
            'Failed to connect after $_maxConnectionAttempts attempts: $e',
          );
        }
      }
    }

    throw BleConnectionException('Unexpected connection failure');
  }

  /// Reconnects to a device after mid-session disconnect.
  ///
  /// MUST call discoverServices() again after reconnect (handles are invalidated).
  static Future<StreamSubscription<List<int>>> reconnectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    int attemptCount = 0;

    while (attemptCount < _maxConnectionAttempts) {
      attemptCount++;

      try {
        // Reconnect with autoConnect: true (returns immediately for known devices, no timeout)
        await device.connect(autoConnect: true);

        // CRITICAL: Re-discover services after every reconnect
        final services = await device.discoverServices();

        // Find NUS service
        final nusService = services.firstWhere(
          (s) => s.uuid == _nusServiceUuid,
          orElse: () => throw BleConnectionException('NUS service not found'),
        );

        // Find TX characteristic
        final txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid == _nusTxCharUuid,
          orElse: () => throw BleConnectionException('TX characteristic not found'),
        );

        // Re-subscribe (old subscription auto-cancelled on disconnect)
        final subscription = txCharacteristic.onValueReceived.listen(onDataReceived);
        device.cancelWhenDisconnected(subscription, delayed: true);

        // Re-enable notifications
        await txCharacteristic.setNotifyValue(true);

        return subscription;
      } catch (e) {
        if (attemptCount < _maxConnectionAttempts) {
          await Future.delayed(_retryBackoff[attemptCount - 1]);
        } else {
          throw BleConnectionException(
            'Failed to reconnect after $_maxConnectionAttempts attempts: $e',
          );
        }
      }
    }

    throw BleConnectionException('Unexpected reconnection failure');
  }

  /// Disconnects from a BLE device.
  static Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      // Ignore errors when disconnecting (already disconnected)
    }
  }
}

/// Exception thrown when BLE connection or subscription fails.
class BleConnectionException implements Exception {
  final String message;
  BleConnectionException(this.message);

  @override
  String toString() => 'BleConnectionException: $message';
}
