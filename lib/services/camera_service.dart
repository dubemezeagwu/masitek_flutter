import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing camera operations (recording video during BLE sessions).
///
/// Responsibilities:
/// - Initialize camera controller (back camera)
/// - Start/stop video recording
/// - Handle camera permissions
/// - Return file paths for saved videos
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;

  /// Whether camera is currently initialized
  bool get isInitialized => _isInitialized;

  /// Whether camera is currently recording
  bool get isRecording => _isRecording;

  /// Camera controller for preview display
  CameraController? get controller => _controller;

  /// Initializes camera with back camera.
  ///
  /// Should be called once on app start (before any recording attempts).
  /// Returns true if successful, false if camera unavailable or permission denied.
  /// Permission check acts as safety guard (permissions requested upfront at app launch).
  Future<bool> initialize() async {
    try {

      // Check camera permission (safety guard)
      final permissionStatus = await Permission.camera.status;
      if (!permissionStatus.isGranted) {
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Find back camera (prefer back over front)
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first, // Fallback to first available camera
      );


      // Initialize controller with lower resolution to reduce file size
      // medium = ~480p = ~10-15 MB/min (vs high = ~720p = ~60 MB/min)
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium, // Medium quality (good balance of size/quality)
        enableAudio: false, // Disable audio to further reduce file size
        imageFormatGroup: ImageFormatGroup.jpeg, // Use JPEG for better compression
      );

      await _controller!.initialize();
      _isInitialized = true;

      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Starts video recording.
  ///
  /// Returns true if recording started successfully, false otherwise.
  /// Throws [CameraException] if camera not initialized or already recording.
  Future<bool> startRecording() async {
    if (!_isInitialized || _controller == null) {
      return false;
    }

    if (_isRecording) {
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      return true;
    } catch (e) {
      _isRecording = false;
      return false;
    }
  }

  /// Stops video recording and returns the file path.
  ///
  /// Returns null if no recording in progress or stop failed.
  /// File is saved to app's temporary directory initially, then moved to Downloads.
  Future<String?> stopRecording() async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      final videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Move file to Downloads directory with timestamped name
      final movedFilePath = await _moveToDownloads(videoFile.path);

      return movedFilePath;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  /// Moves video file from temp directory to app's Videos directory with custom filename.
  ///
  /// Filename format: masitek_day_month_year_hour_minute.mp4
  /// Example: masitek_13_05_2026_20_30.mp4
  ///
  /// Note: Saves to app-specific external storage directory instead of public Downloads
  /// to avoid scoped storage restrictions on Android 10+
  Future<String> _moveToDownloads(String tempPath) async {
    try {
      // Generate filename with timestamp
      final now = DateTime.now();
      final filename = 'masitek_'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.month.toString().padLeft(2, '0')}_'
          '${now.year}_'
          '${now.hour.toString().padLeft(2, '0')}_'
          '${now.minute.toString().padLeft(2, '0')}'
          '.mp4';

      // Get app's external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir == null) {
        return tempPath;
      }

      // Create Videos directory in app's external storage
      // Path: /storage/emulated/0/Android/data/com.example.masitek_flutter/files/Videos
      final videosDir = Directory('${externalDir.path}/Videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final finalPath = '${videosDir.path}/$filename';

      // Move file to final location
      final tempFile = File(tempPath);
      final finalFile = await tempFile.copy(finalPath);

      // Delete temp file
      await tempFile.delete();

      return finalFile.path;
    } catch (e) {
      return tempPath;
    }
  }

  /// Disposes camera controller and releases resources.
  ///
  /// Should be called when camera is no longer needed (e.g., on disconnect).
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } catch (e) {
    }
  }

  /// Checks if camera permission is granted.
  ///
  /// Returns true if granted, false otherwise.
  static Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Requests camera permission from user.
  ///
  /// Returns true if granted, false if denied.
  static Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}

/// Exception thrown when camera operations fail.
class CameraServiceException implements Exception {
  final String message;
  CameraServiceException(this.message);

  @override
  String toString() => 'CameraServiceException: $message';
}
