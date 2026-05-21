import 'dart:async';
import '../core/app_core.dart';
import 'app_ble.dart';

// Connection Flow:
// 1. Stop scan before connecting
// 2. Connect with retry (exponential backoff: 1s, 2s, 4s, 8s, 16s)
// 3. Discover services
// 4. Find NUS service + TX characteristic
// 5. Subscribe to notifications with auto-cleanup
// 6. Navigate only after successful subscription

class BleConnectionManager implements BleConnectionInterface {
  final Guid _nusServiceUuid = Guid(BLEConstants.nusServiceUuid);
  final Guid _nusTxCharUuid = Guid(BLEConstants.nusTxCharUuid);
  final int _maxConnectionAttempts = BLEConstants.maxConnectionAttempts;
  final List<Duration> _retryBackoff = BLEConstants.reconnectBackoffSeconds
      .map((seconds) => Duration(seconds: seconds))
      .toList();


  @override
  Future<StreamSubscription<List<int>>> connectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    int attemptCount = 0;
    debugPrint('[BLE] Connecting to ${device.platformName}');

    while (attemptCount < _maxConnectionAttempts) {
      attemptCount++;

      try {
        // stop scanning before connecting (CRITICAL)
        await FlutterBluePlus.stopScan();

        await device.connect(autoConnect: false);

        final services = await device.discoverServices();

        final nusService = services.firstWhere(
          (s) => s.uuid == _nusServiceUuid,
          orElse: () => throw BleConnectionException(
            'NUS service not found. Device not compatible.',
          ),
        );

        final txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid == _nusTxCharUuid,
          orElse: () => throw BleConnectionException(
            'TX characteristic not found. Device not compatible.',
          ),
        );

        // this creates a stream listener that fires onDataReceived() callback
        // every time the BLE device sends a notification 
        // and automatically cleans up when a device disconnects. subscription is auto cancelled
        final subscription = txCharacteristic.onValueReceived.listen(onDataReceived);
        device.cancelWhenDisconnected(subscription, delayed: true);

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


  @override
  Future<StreamSubscription<List<int>>> reconnectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    int attemptCount = 0;

    while (attemptCount < _maxConnectionAttempts) {
      attemptCount++;

      try {
        await device.connect(autoConnect: true);

        // CRITICAL:rRe-discover services after every reconnect
        final services = await device.discoverServices();

        final nusService = services.firstWhere(
          (s) => s.uuid == _nusServiceUuid,
          orElse: () => throw BleConnectionException('NUS service not found'),
        );

        final txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid == _nusTxCharUuid,
          orElse: () => throw BleConnectionException('TX characteristic not found'),
        );

        final subscription = txCharacteristic.onValueReceived.listen(onDataReceived);
        device.cancelWhenDisconnected(subscription, delayed: true);

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

  @override
  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      // Ignore errors when disconnecting (already disconnected)
    }
  }
}
