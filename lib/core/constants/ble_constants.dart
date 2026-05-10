class BLEConstants {
  // Nordic UART Service (NUS)
  static const String nusServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String nusTxCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  // Device name
  static const String targetDeviceName = 'NUS-Py';

  // Scan config
  static const int scanTimeoutSeconds = 4;
  static const int maxScanAttempts = 5;

  // Connection config
  static const int maxConnectionAttempts = 5;
  static const List<int> reconnectBackoffSeconds = [1, 2, 4, 8, 16];

  // Chart config
  static const int maxChartPoints = 250;
  static const int chartRefreshMs = 16; // ~60fps

  // Storage
  static const int minStorageSpaceMB = 100;
}
