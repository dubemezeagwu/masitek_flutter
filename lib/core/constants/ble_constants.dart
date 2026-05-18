class BLEConstants {
  // Nordic UART Service (NUS) details
  static const String nusServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String nusTxCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  static const int scanDurationSeconds = 90;
  static const int maxScanAttempts = 5;
  static const int scanRetryDelaySeconds = 2;

  static const int maxConnectionAttempts = 5;
  static const List<int> reconnectBackoffSeconds = [1, 2, 4, 8, 16];

  static const int maxChartPoints = 1000;
}
