import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles BLE permission requests with SDK-branched logic.
///
/// Android BLE permissions vary by SDK version:
/// - Android 6-11 (API 23-30): Requires ACCESS_FINE_LOCATION (OS quirk)
/// - Android 12+ (API 31+): Requires BLUETOOTH_SCAN + BLUETOOTH_CONNECT
///
/// iOS always requires Bluetooth permissions (consistent).
class BlePermissionHandler {
  static Future<bool> requestBlePermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidBlePermissions();
    } else if (Platform.isIOS) {
      return await _requestIosBlePermissions();
    }
    return false;
  }

  /// Android-specific BLE permission logic with SDK branching.
  static Future<bool> _requestAndroidBlePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      // Android 12+ (API 31+): BLUETOOTH_SCAN + BLUETOOTH_CONNECT
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();

      return scanStatus.isGranted && connectStatus.isGranted;
    } else {
      // Android 6-11 (API 23-30): ACCESS_FINE_LOCATION
      final locationStatus = await Permission.locationWhenInUse.request();
      return locationStatus.isGranted;
    }
  }

  /// iOS-specific BLE permission logic.
  static Future<bool> _requestIosBlePermissions() async {
    final bluetoothStatus = await Permission.bluetooth.request();
    return bluetoothStatus.isGranted;
  }

  /// Checks if BLE permissions are already granted (without requesting).
  static Future<bool> checkBlePermissions() async {
    if (Platform.isAndroid) {
      return await _checkAndroidBlePermissions();
    } else if (Platform.isIOS) {
      return await _checkIosBlePermissions();
    }
    return false;
  }

  /// Android-specific permission check with SDK branching.
  static Future<bool> _checkAndroidBlePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      // Android 12+: Check BLUETOOTH_SCAN + BLUETOOTH_CONNECT
      final scanGranted = await Permission.bluetoothScan.isGranted;
      final connectGranted = await Permission.bluetoothConnect.isGranted;
      return scanGranted && connectGranted;
    } else {
      // Android 6-11: Check ACCESS_FINE_LOCATION
      return await Permission.locationWhenInUse.isGranted;
    }
  }

  /// iOS-specific permission check.
  static Future<bool> _checkIosBlePermissions() async {
    return await Permission.bluetooth.isGranted;
  }

  /// Opens app settings if permissions are permanently denied.
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
