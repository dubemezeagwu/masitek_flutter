import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleConnectionInterface {
  Future<StreamSubscription<List<int>>> connectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  });

  Future<StreamSubscription<List<int>>> reconnectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  });

  Future<void> disconnectDevice(BluetoothDevice device);
}

class BleConnectionException implements Exception {
  final String message;
  BleConnectionException(this.message);

  @override
  String toString() => 'BleConnectionException: $message';
}
