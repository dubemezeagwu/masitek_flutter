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
  static const List<Duration> _retryBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];

  /// Connects to a BLE device and subscribes to NUS TX characteristic.
  ///
  /// Returns the TX characteristic subscription stream on success.
  /// Throws [BleConnectionException] if connection or subscription fails.
  static Future<StreamSubscription<List<int>>> connectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    int attemptCount = 0;
    debugPrint('[BLE] Starting connection to device: ${device.platformName} (${device.remoteId})');

    while (attemptCount < _maxConnectionAttempts) {
      attemptCount++;
      debugPrint('[BLE] Connection attempt $attemptCount/$_maxConnectionAttempts');

      try {
        // Step 1: Stop scanning before connecting (CRITICAL)
        debugPrint('[BLE] Step 1: Stopping scan before connect');
        await FlutterBluePlus.stopScan();
        debugPrint('[BLE] Step 1: Scan stopped successfully');

        // Step 2: Connect to device
        debugPrint('[BLE] Step 2: Calling device.connect()');
        await device.connect(autoConnect: false);
        debugPrint('[BLE] Step 2: Device connected successfully');

        // Step 3: Discover services (MUST be called after every connect/reconnect)
        debugPrint('[BLE] Step 3: Discovering services');
        final services = await device.discoverServices();
        debugPrint('[BLE] Step 3: Discovered ${services.length} services');
        for (var service in services) {
          debugPrint('[BLE]   Service: ${service.uuid}');
        }

        // Step 4: Find NUS service
        debugPrint('[BLE] Step 4: Looking for NUS service: $_nusServiceUuid');
        final nusService = services.firstWhere(
          (s) => s.uuid == _nusServiceUuid,
          orElse: () => throw BleConnectionException(
            'NUS service not found. Device not compatible.',
          ),
        );
        debugPrint('[BLE] Step 4: NUS service found');

        // Step 5: Find TX characteristic
        debugPrint('[BLE] Step 5: Looking for TX characteristic: $_nusTxCharUuid');
        debugPrint('[BLE]   Available characteristics in NUS service:');
        for (var char in nusService.characteristics) {
          debugPrint('[BLE]     Characteristic: ${char.uuid}');
        }
        final txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid == _nusTxCharUuid,
          orElse: () => throw BleConnectionException(
            'TX characteristic not found. Device not compatible.',
          ),
        );
        debugPrint('[BLE] Step 5: TX characteristic found');

        // Step 6: Subscribe to notifications with auto-cleanup
        debugPrint('[BLE] Step 6: Setting up notification listener');
        final subscription = txCharacteristic.onValueReceived.listen(onDataReceived);
        device.cancelWhenDisconnected(subscription, delayed: true);
        debugPrint('[BLE] Step 6: Notification listener set up successfully');

        // Step 7: Enable notifications
        debugPrint('[BLE] Step 7: Enabling notifications on TX characteristic');
        try {
          await txCharacteristic.setNotifyValue(true);
          debugPrint('[BLE] Step 7: Notifications enabled successfully');
        } on PlatformException catch (e) {
          debugPrint('[BLE] Step 7: GATT error - ${e.code}: ${e.message}');
          if (e.code.contains('set_notification_failed')) {
            // GATT error: Device rejected subscription
            await device.disconnect();
            throw BleConnectionException(
              'Device rejected notification subscription (GATT error: ${e.code})',
            );
          }
          rethrow;
        }

        // Success: Return the subscription
        debugPrint('[BLE] ✅ Connection and subscription successful!');
        return subscription;
      } catch (e) {
        debugPrint('[BLE] ❌ Connection attempt $attemptCount failed: $e');

        // Connection or subscription failed
        if (attemptCount < _maxConnectionAttempts) {
          final backoffDuration = _retryBackoff[attemptCount - 1];
          debugPrint('[BLE] Retrying in ${backoffDuration.inSeconds}s...');
          // Retry after exponential backoff
          await Future.delayed(backoffDuration);
        } else {
          // Max attempts reached
          debugPrint('[BLE] ❌ Max connection attempts reached. Giving up.');
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
