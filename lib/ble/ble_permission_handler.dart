import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/app_services.dart';

// handles BLE permission requests with SDK-branched logic.
//
// android BLE permissions vary by SDK version:
// - android 6-11 (API 23-30): requires ACCESS_FINE_LOCATION (OS quirk)
// - android 12+ (API 31+): requires BLUETOOTH_SCAN + BLUETOOTH_CONNECT
//
// iOS always requires Bluetooth permissions (consistent).
class BlePermissionHandler {
  static Future<bool> requestBlePermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidBlePermissions();
    } else if (Platform.isIOS) {
      return await _requestIosBlePermissions();
    }
    return false;
  }

  // android-specific BLE permission logic with SDK branching.
  static Future<bool> _requestAndroidBlePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // android 12+ (still requires location for BLE scanning)
    if (sdkInt >= 31) {
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.locationWhenInUse.request();

      return scanStatus.isGranted && connectStatus.isGranted && locationStatus.isGranted;
    } else {
      // android 6-11
      final locationStatus = await Permission.locationWhenInUse.request();
      return locationStatus.isGranted;
    }
  }

  static Future<bool> _requestIosBlePermissions() async {
    final bluetoothStatus = await Permission.bluetooth.request();
    return bluetoothStatus.isGranted;
  }

  // Checks if BLE permissions are already granted (without requesting).
  static Future<bool> checkBlePermissions() async {
    if (Platform.isAndroid) {
      return await _checkAndroidBlePermissions();
    } else if (Platform.isIOS) {
      return await _checkIosBlePermissions();
    }
    return false;
  }

  // Android-specific permission check with SDK branching.
  static Future<bool> _checkAndroidBlePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // android 12+ (still requires location for BLE scanning)
    if (sdkInt >= 31) {
      final scanGranted = await Permission.bluetoothScan.isGranted;
      final connectGranted = await Permission.bluetoothConnect.isGranted;
      final locationGranted = await Permission.locationWhenInUse.isGranted;
      return scanGranted && connectGranted && locationGranted;
    } else {
      // android 6-11
      return await Permission.locationWhenInUse.isGranted;
    }
  }

  static Future<bool> _checkIosBlePermissions() async {
    return await Permission.bluetooth.isGranted;
  }

  // opens app settings if permissions are permanently denied.
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
