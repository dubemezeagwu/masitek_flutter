import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
