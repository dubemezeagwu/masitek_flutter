import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ble_connection_state.dart';
import '../../services/persistence_service.dart';
import '../../data/isolate/worker_isolate.dart';
import '../providers/ble_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/data_preview_row.dart';
import '../widgets/live_chart.dart';
import '../widgets/date_time_widget.dart';

class MainScreen extends ConsumerStatefulWidget {
  final WorkerIsolate workerIsolate;

  const MainScreen({
    super.key,
    required this.workerIsolate,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleProvider);
    final cameraState = ref.watch(cameraProvider);

    // Determine status text and color based on connection state
    final String statusText;
    final Color statusColor;

    // Override status if recording
    if (_isRecording) {
      statusText = 'Recording...';
      statusColor = Colors.orange;
    } else {
      switch (bleState.connectionState) {
        case BleConnectionState.connected:
          statusText = 'Connected';
          statusColor = Colors.green;
          break;
        case BleConnectionState.connecting:
          statusText = 'Connecting...';
          statusColor = Colors.orange;
          break;
        case BleConnectionState.reconnecting:
          statusText = 'Reconnecting...';
          statusColor = Colors.amber;
          break;
        case BleConnectionState.disconnected:
          statusText = 'Disconnected';
          statusColor = Colors.red;
          break;
        case BleConnectionState.failed:
          statusText = 'Connection Failed';
          statusColor = Colors.red;
          break;
        case BleConnectionState.scanning:
          statusText = 'Scanning...';
          statusColor = Colors.blue;
          break;
      }
    }

    // Get device name for title, fallback to default if null/empty
    final deviceName = bleState.connectedDevice?.platformName;
    final title = (deviceName != null && deviceName.isNotEmpty)
        ? deviceName
        : 'BLE Live Monitor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Top row: Date/time and connection status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Date and time (left side)
                    const Expanded(
                      child: DateTimeWidget(),
                    ),

                    const SizedBox(width: 12),

                    // Connection status (right side)
                    ConnectionStatusBar(
                      status: statusText,
                      color: statusColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Data preview - compact row showing hex and decoded message
              DataPreviewRow(
                bytes: bleState.lastReceivedBytes,
              ),

              const SizedBox(height: 8),

              // Live chart - displays raw sensor values in real-time
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
        ],
      ),
      // FAB for starting/stopping recording (icon only)
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

      debugPrint('[MainScreen] ✅ Recording started');
    } catch (e) {
      debugPrint('[MainScreen] ❌ Error starting recording: $e');
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

      // Stop camera recording
      final videoPath = await cameraNotifier.stopRecording();

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });

      // Flush buffer from worker isolate (get all accumulated samples)
      debugPrint('[MainScreen] Flushing buffer from worker isolate...');
      final samples = await widget.workerIsolate.flushBuffer();
      debugPrint('[MainScreen] ✅ Retrieved ${samples.length} samples from buffer');

      // Save JSON file with real sample data
      final jsonPath = await PersistenceService.saveSessionData(
        samples: samples,
        startTime: startTime,
        endTime: endTime,
      );

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
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

      debugPrint('[MainScreen] ✅ Recording saved');
      debugPrint('[MainScreen] Video: $videoPath');
      debugPrint('[MainScreen] JSON: $jsonPath');
    } catch (e) {
      debugPrint('[MainScreen] ❌ Error stopping recording: $e');

      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showError('Failed to save recording: $e');
    }
  }

  /// Shows error message as snackbar
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
