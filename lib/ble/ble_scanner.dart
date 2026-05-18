import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE scanner service with retry logic and configurable scan parameters.
///
/// Scanning Strategy:
/// - Max attempts: 5
/// - Scan duration: 90 seconds (allows live RSSI updates)
/// - Delay between attempts: 2 seconds
/// - Returns list of discovered devices
class BleScanner {
  static const int _maxScanAttempts = 5;
  static const Duration _scanDuration = Duration(seconds: 90);
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Scans for BLE devices with automatic retry logic.
  ///
  /// Returns a stream of scan results that can be listened to in real-time.
  /// Scans for 90 seconds to provide live RSSI updates, then silently stops.
  ///
  /// Throws [BleScanException] if scanning fails after max attempts.
  static Stream<List<ScanResult>> scanForDevices() async* {
    int attemptCount = 0;

    while (attemptCount < _maxScanAttempts) {
      attemptCount++;

      try {
        // Start scanning (90-second timeout for live RSSI updates)
        await FlutterBluePlus.startScan(
          timeout: _scanDuration,
          androidUsesFineLocation: true,
        );

        // Listen to scan results (RSSI updates in real-time for 90 seconds)
        await for (final results in FlutterBluePlus.scanResults) {
          yield results;
        }

        // Scan completed successfully
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

  /// Stops an ongoing BLE scan.
  static Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // Ignore errors when stopping scan (already stopped)
    }
  }

  /// Checks if BLE scanning is currently active.
  static Stream<bool> get isScanning => FlutterBluePlus.isScanning;
}

/// Exception thrown when BLE scanning fails after max retry attempts.
class BleScanException implements Exception {
  final String message;
  BleScanException(this.message);

  @override
  String toString() => 'BleScanException: $message';
}
