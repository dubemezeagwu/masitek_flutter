import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ble_connection_state.dart';
import '../../core/extensions/rssi_extensions.dart';
import '../../services/persistence_service.dart';
import '../providers/ble_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/performance_provider.dart';
import '../providers/worker_isolate_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/data_preview_row.dart';
import '../widgets/live_chart.dart';
import '../widgets/date_time_widget.dart';
import '../widgets/performance_overlay.dart' as perf;

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  CameraNotifier? _cameraNotifier; // Capture notifier reference

  @override
  void initState() {
    super.initState();
    // Capture camera notifier reference early (before dispose might be called)
    _cameraNotifier = ref.read(cameraProvider.notifier);

    // Add lifecycle observer to handle app background/foreground
    WidgetsBinding.instance.addObserver(this);

    // Initialize camera when MainScreen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    final cameraInitialized = await _cameraNotifier!.initialize();

    if (!cameraInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera unavailable - recording disabled'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose camera to release resources when leaving screen
    // Use captured notifier reference (safe to call during dispose)
    _cameraNotifier?.disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isRecording) {
          ref.read(bleProvider.notifier).resumeRssiPolling();
        } else {
          _initializeCamera();
          ref.read(bleProvider.notifier).resumeRssiPolling();
        }
        break;

      case AppLifecycleState.inactive:
        // Brief pause (phone call, dialog, switching apps)
        // Don't release resources yet - might come back immediately
        break;

      case AppLifecycleState.paused:
        // App went to background
        if (_isRecording) {
          // Recording in progress - keep camera and RSSI alive
          // Do nothing - let camera and RSSI continue
        } else {
          // Not recording - release resources to save battery
          _cameraNotifier?.disposeCamera();
          ref.read(bleProvider.notifier).pauseRssiPolling();
        }
        break;

      case AppLifecycleState.detached:
        // App being destroyed - final cleanup
        break;

      case AppLifecycleState.hidden:
        // Added in Flutter 3.13+ - similar to paused
        break;
    }
  }

  ({String text, Color color}) _getConnectionStatus(BleConnectionState state) {
    if (_isRecording) {
      return (text: 'Recording...', color: Colors.orange);
    }

    return switch (state) {
      BleConnectionState.connected => (text: 'Connected', color: Colors.green),
      BleConnectionState.connecting => (text: 'Connecting...', color: Colors.orange),
      BleConnectionState.reconnecting => (text: 'Reconnecting...', color: Colors.amber),
      BleConnectionState.disconnected => (text: 'Disconnected', color: Colors.red),
      BleConnectionState.failed => (text: 'Connection Failed', color: Colors.red),
      BleConnectionState.scanning => (text: 'Scanning...', color: Colors.blue),
    };
  }

  String _getScreenTitle(String? deviceName) {
    return (deviceName != null && deviceName.isNotEmpty)
        ? deviceName
        : 'BLE Live Monitor';
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleProvider);
    final cameraState = ref.watch(cameraProvider);

    final status = _getConnectionStatus(bleState.connectionState);
    final title = _getScreenTitle(bleState.connectedDevice?.platformName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Performance metrics toggle button
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Toggle Performance Metrics',
            onPressed: () {
              ref.read(performanceProvider.notifier).toggleOverlay();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Top row: Date/time, signal indicator, and connection status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Date and time (left side)
                    const Expanded(
                      child: DateTimeWidget(),
                    ),

                    const SizedBox(width: 8),

                    // Signal strength indicator (middle)
                    if (bleState.connectionState == BleConnectionState.connected && bleState.currentRssi != 0)
                      Icon(
                        bleState.currentRssi.signalIcon,
                        color: bleState.currentRssi.signalColor,
                        size: 20,
                      ),

                    const SizedBox(width: 8),

                    // Connection status (right side)
                    ConnectionStatusBar(
                      status: status.text,
                      color: status.color,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              DataPreviewRow(
                bytes: bleState.lastReceivedBytes,
              ),

              const SizedBox(height: 8),

              const Expanded(
                child: LiveChart(),
              ),

              const SizedBox(height: 16),
            ],
          ),

          // Camera preview overlay (only show when recording)
          if (_isRecording && cameraState.isInitialized)
            Positioned(
              bottom: 20,
              left: 20,
              child: _buildCameraPreview(),
            ),

          const perf.PerformanceOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        backgroundColor: _isRecording ? Colors.red : Colors.blue,
        elevation: 4,
        child: Icon(
          _isRecording ? Icons.stop : Icons.play_arrow,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Builds camera preview overlay (circular, bottom-left corner)
  Widget _buildCameraPreview() {
    final cameraState = ref.watch(cameraProvider);
    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.videocam_off,
          color: Colors.white,
          size: 40,
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: ClipOval(
        child: CameraPreview(controller),
      ),
    );
  }

  /// Starts video recording
  Future<void> _startRecording() async {
    final cameraNotifier = ref.read(cameraProvider.notifier);
    final cameraState = ref.read(cameraProvider);

    // Check if camera is available
    if (!cameraState.isInitialized) {
      _showError('Camera not available');
      return;
    }

    // Check if disconnected
    final bleState = ref.read(bleProvider);
    if (bleState.connectionState != BleConnectionState.connected) {
      _showError('BLE not connected');
      return;
    }

    // Check storage space
    final hasStorage = await PersistenceService.hasEnoughStorage();
    if (!hasStorage) {
      final storageStatus = await PersistenceService.getStorageStatus();
      _showError('Not enough storage space. $storageStatus\nFree up at least 100 MB and try again.');
      return;
    }

    try {
      // Start camera recording
      final started = await cameraNotifier.startRecording();
      if (!started) {
        _showError('Failed to start camera recording');
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
      });

    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  /// Stops video recording and saves session data
  Future<void> _stopRecording() async {
    if (!_isRecording) {
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Saving data...'),
            ],
          ),
        ),
      );
    }

    try {
      final cameraNotifier = ref.read(cameraProvider.notifier);
      final endTime = DateTime.now();
      final startTime = _recordingStartTime ?? endTime;

      final videoPath = await cameraNotifier.stopRecording();

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });

      final workerIsolateNotifier = ref.read(workerIsolateProvider.notifier);
      final samples = await workerIsolateNotifier.flushBuffer();

      final jsonPath = await PersistenceService.saveSessionData(
        samples: samples,
        startTime: startTime,
        endTime: endTime,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted && videoPath != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Recording Saved'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${samples.length} samples recorded'),
                const SizedBox(height: 8),
                Text(
                  'Video: $videoPath',
                  style: const TextStyle(fontSize: 12),
                ),
                if (jsonPath != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Data: $jsonPath',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }

      _showError('Failed to save recording: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
