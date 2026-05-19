import 'package:flutter/foundation.dart';

final _errorMatchers = [
  (keywords: ['permission', 'denied'], message: 'Bluetooth permission needed. Please enable in Settings.'),
  (keywords: ['nus service not found'], message: "This device isn't compatible."),
  (keywords: ['tx characteristic not found'], message: "Device doesn't support required features."),
  (keywords: ['connection failed'], message: "Couldn't connect to device. Please try again."),
  (keywords: ['failed to connect'], message: "Couldn't connect to device. Please try again."),
  (keywords: ['scan failed'], message: 'Bluetooth scan failed. Check Bluetooth is enabled.'),
  (keywords: ['failed to start scan'], message: 'Bluetooth scan failed. Check Bluetooth is enabled.'),
  (keywords: ['timeout'], message: 'Connection timed out. Device might be out of range.'),
  (keywords: ['device disconnected'], message: 'Device disconnected unexpectedly.'),
];

class BleError {
  static String getUserFriendlyMessage(String technicalError) {
    debugPrint('[BLE Error] $technicalError');

    final error = technicalError.toLowerCase();

    for (final matcher in _errorMatchers) {
      if (matcher.keywords.every((keyword) => error.contains(keyword))) {
        return matcher.message;
      }
    }

    return technicalError.split('\n').first;
  }
}
