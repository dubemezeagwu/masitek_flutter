import 'dart:async';
import '../core/app_core.dart';
import 'app_ble.dart';

class BleScanner implements BleScannerInterface {
  final int _maxScanAttempts = BLEConstants.maxScanAttempts;
  final Duration _scanDuration = const Duration(seconds: BLEConstants.scanDurationSeconds);
  final Duration _retryDelay = const Duration(seconds: BLEConstants.scanRetryDelaySeconds);

  @override
  Stream<List<ScanResult>> scanForDevices() async* {
    int attemptCount = 0;

    while (attemptCount < _maxScanAttempts) {
      attemptCount++;

      try {
        await FlutterBluePlus.startScan(
          timeout: _scanDuration,
          androidUsesFineLocation: true,
        );

        // listen to scan results (RSSI updates in real-time for 90 seconds)
        await for (final results in FlutterBluePlus.scanResults) {
          yield results;
        }

        break;
      } catch (e) {
        // Scan failed, retry after delay
        if (attemptCount < _maxScanAttempts) {
          await Future.delayed(_retryDelay);
        } else {
          // Max attempts reached
          throw BleScanException(
            'Failed to scan for BLE devices after $_maxScanAttempts attempts: $e',
          );
        }
      }
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // Ignore errors when stopping scan (already stopped)
    }
  }

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;
}
