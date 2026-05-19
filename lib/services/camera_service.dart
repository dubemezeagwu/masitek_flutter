import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/extensions/date_time_extensions.dart';

// Responsibilities:
// - Initialize camera controller (back camera)
// - Start/stop video recording
// - Handle camera permissions
// - Return file paths for saved videos

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;

  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;

  CameraController? get controller => _controller;

  Future<bool> initialize() async {
    try {

      final permissionStatus = await Permission.camera.status;
      if (!permissionStatus.isGranted) {
        return false;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // prefer back over front
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first, // Fallback to first available camera
      );


      // initialize controller with lower resolution and no audio to reduce file size
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
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


  Future<String?> stopRecording() async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      final videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Move file to Downloads directory with timestamped name
      final movedFilePath = await _moveToPhoneStorage(videoFile.path);

      return movedFilePath;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }


  // Note: saves to app-specific external storage directory instead of public Downloads
  // to avoid scoped storage restrictions on Android 10+
  Future<String> _moveToPhoneStorage(String tempPath) async {
    try {
      final filename = '${DateTime.now().toMasitekFilename()}.mp4';

      final Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir == null) {
        return tempPath;
      }

      // Path: /storage/emulated/0/Android/data/com.example.masitek_flutter/files/Videos
      final videosDir = Directory('${externalDir.path}/Videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final finalPath = '${videosDir.path}/$filename';

      // move file to final location
      final tempFile = File(tempPath);
      final finalFile = await tempFile.copy(finalPath);

      await tempFile.delete();

      return finalFile.path;
    } catch (e) {
      return tempPath;
    }
  }

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


  static Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}

// exception thrown when camera operations fail.
class CameraServiceException implements Exception {
  final String message;
  CameraServiceException(this.message);

  @override
  String toString() => 'CameraServiceException: $message';
}
