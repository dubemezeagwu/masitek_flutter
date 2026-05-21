import 'app_ble.dart';

abstract class BleScannerInterface {
  Stream<List<ScanResult>> scanForDevices();
  Future<void> stopScan();
  Stream<bool> get isScanning;
}

class BleScanException implements Exception {
  final String message;
  BleScanException(this.message);

  @override
  String toString() => 'BleScanException: $message';
}
