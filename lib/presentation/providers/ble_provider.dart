import 'dart:async';
import '../../ble/app_ble.dart';
import '../../core/app_core.dart';
import '../app_presentation.dart';

final bleScannerProvider = Provider<BleScannerInterface>((ref) {
  return BleScanner();
});

final bleConnectionProvider = Provider<BleConnectionInterface>((ref) {
  return BleConnectionManager();
});

final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  final scanner = ref.watch(bleScannerProvider);
  final connectionManager = ref.watch(bleConnectionProvider);
  return BleNotifier(scanner, connectionManager, ref);
});

class BleState {
  final BleConnectionState connectionState;
  final List<ScanResult> discoveredDevices;
  final BluetoothDevice? connectedDevice;
  final String? errorMessage;
  final int? connectionAttempt;
  final List<int>? lastReceivedBytes;
  final int currentRssi;

  const BleState({
    this.connectionState = BleConnectionState.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.errorMessage,
    this.connectionAttempt,
    this.lastReceivedBytes,
    this.currentRssi = 0,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    List<ScanResult>? discoveredDevices,
    BluetoothDevice? connectedDevice,
    String? errorMessage,
    int? connectionAttempt,
    List<int>? lastReceivedBytes,
    int? currentRssi,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage ?? this.errorMessage,
      connectionAttempt: connectionAttempt ?? this.connectionAttempt,
      lastReceivedBytes: lastReceivedBytes ?? this.lastReceivedBytes,
      currentRssi: currentRssi ?? this.currentRssi,
    );
  }
}

class BleNotifier extends StateNotifier<BleState> {
  final BleScannerInterface _scanner;
  final BleConnectionInterface _connectionManager;
  final Ref _ref;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  Timer? _rssiTimer;
  Function(List<int>)? _currentDataCallback;

  BleNotifier(this._scanner, this._connectionManager, this._ref) : super(const BleState()) {
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && state.connectionState == BleConnectionState.scanning) {
        state = state.copyWith(connectionState: BleConnectionState.disconnected);
      }
    });
  }

  Future<bool> startScanning() async {
    if (state.connectionState == BleConnectionState.scanning) {
      await _stopScanningInternal();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final hasPermissions = await BlePermissionHandler.checkBlePermissions();
    if (!hasPermissions) {
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: BleError.getUserFriendlyMessage('BLE permissions denied'),
      );
      return false;
    }

    state = state.copyWith(
      connectionState: BleConnectionState.scanning,
      discoveredDevices: [],
      errorMessage: null,
    );

    try {
      _scanSubscription = _scanner.scanForDevices().listen(
        (results) => state = state.copyWith(discoveredDevices: results),
        onError: (error) => state = state.copyWith(
          connectionState: BleConnectionState.failed,
          errorMessage: BleError.getUserFriendlyMessage('Scan failed: $error'),
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: BleError.getUserFriendlyMessage('Failed to start scan: $e'),
      );
      return false;
    }
  }

  Future<void> _stopScanningInternal() async {
    await _scanSubscription?.cancel();
    await _scanner.stopScan();
  }

  Future<void> stopScanning() async {
    await _scanSubscription?.cancel();
    await _scanner.stopScan();

    if (state.connectionState == BleConnectionState.scanning) {
      state = state.copyWith(connectionState: BleConnectionState.disconnected);
    }
  }

  Future<bool> connectToDevice(
    BluetoothDevice device, {
    required Function(List<int> bytes) onDataReceived,
  }) async {
    if (state.connectionState == BleConnectionState.connecting ||
        state.connectionState == BleConnectionState.connected) {
      return false;
    }

    state = state.copyWith(
      connectionState: BleConnectionState.connecting,
      connectedDevice: device,
      errorMessage: null,
    );

    try {
      _currentDataCallback = onDataReceived;

      _dataSubscription = await _connectionManager.connectToDevice(
        device,
        onDataReceived: onDataReceived,
      );

      state = state.copyWith(connectionState: BleConnectionState.connected);

      _startRssiPolling();

      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((connectionState) {
        if (connectionState == BluetoothConnectionState.disconnected) {
          if (state.connectionState == BleConnectionState.connected) {
            debugPrint('[Provider] Unexpected disconnect, reconnecting...');
            _attemptReconnection(device);
          }
        }
      });

      return true;
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: BleError.getUserFriendlyMessage('Connection failed: $e'),
      );
      return false;
    }
  }

  Future<void> _attemptReconnection(BluetoothDevice device) async {
    if (state.connectionState == BleConnectionState.reconnecting || _currentDataCallback == null) {
      return;
    }

    state = state.copyWith(connectionState: BleConnectionState.reconnecting);

    try {
      _dataSubscription = await _connectionManager.reconnectToDevice(
        device,
        onDataReceived: _currentDataCallback!,
      );

      debugPrint('[Provider] ✅ Reconnected successfully');
      state = state.copyWith(connectionState: BleConnectionState.connected);
      _startRssiPolling();
    } catch (e) {
      debugPrint('[Provider] ❌ Reconnection failed: $e');

      final workerIsolateNotifier = _ref.read(workerIsolateProvider.notifier);
      await workerIsolateNotifier.kill();

      state = state.copyWith(
        connectionState: BleConnectionState.failed,
        errorMessage: BleError.getUserFriendlyMessage('Reconnection failed: $e'),
      );
    }
  }

  Future<void> disconnect() async {
    if (state.connectedDevice == null) return;

    _stopRssiPolling();

    final workerIsolateNotifier = _ref.read(workerIsolateProvider.notifier);
    await workerIsolateNotifier.kill();

    state = state.copyWith(
      connectionState: BleConnectionState.disconnected,
      discoveredDevices: [],
    );

    await _dataSubscription?.cancel();
    await _connectionManager.disconnectDevice(state.connectedDevice!);

    state = state.copyWith(connectedDevice: null);
  }

  void updateReceivedBytes(List<int> bytes) {
    state = state.copyWith(lastReceivedBytes: bytes);
  }

  void _startRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final device = state.connectedDevice;

      if (device != null && state.connectionState == BleConnectionState.connected) {
        try {
          final rssi = await device.readRssi();
          state = state.copyWith(currentRssi: rssi);
        } catch (e) {
          // Silently ignore RSSI errors
        }
      }
    });
  }

  void _stopRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
    state = state.copyWith(currentRssi: 0);
  }

  void pauseRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  void resumeRssiPolling() {
    if (state.connectionState == BleConnectionState.connected) {
      _startRssiPolling();
    }
  }

  @override
  void dispose() {
    _stopRssiPolling();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.dispose();
  }
}
