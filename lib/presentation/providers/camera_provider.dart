import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/camera_service.dart';

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

/// Camera state data class.
class CameraState {
  final bool isInitialized;
  final bool isRecording;
  final CameraController? controller;
  final String? errorMessage;

  const CameraState({
    this.isInitialized = false,
    this.isRecording = false,
    this.controller,
    this.errorMessage,
  });

  CameraState copyWith({
    bool? isInitialized,
    bool? isRecording,
    CameraController? controller,
    String? errorMessage,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isRecording: isRecording ?? this.isRecording,
      controller: controller ?? this.controller,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  final CameraService _cameraService = CameraService();

  CameraNotifier() : super(const CameraState());

  Future<bool> initialize() async {

    final success = await _cameraService.initialize();

    if (success) {
      state = state.copyWith(
        isInitialized: true,
        controller: _cameraService.controller,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        isInitialized: false,
        errorMessage: 'Camera unavailable or permission denied',
      );
    }

    return success;
  }


  Future<bool> startRecording() async {
    if (!state.isInitialized) {
      state = state.copyWith(errorMessage: 'Camera not initialized');
      return false;
    }

    if (state.isRecording) {
      return false;
    }

    final success = await _cameraService.startRecording();

    if (success) {
      state = state.copyWith(
        isRecording: true,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        errorMessage: 'Failed to start recording',
      );
    }

    return success;
  }

  Future<String?> stopRecording() async {
    if (!state.isRecording) {
      return null;
    }

    final filePath = await _cameraService.stopRecording();

    state = state.copyWith(
      isRecording: false,
      errorMessage: filePath == null ? 'Failed to save video' : null,
    );

    return filePath;
  }

  Future<void> disposeCamera() async {
    await _cameraService.dispose();

    state = state.copyWith(
      isInitialized: false,
      isRecording: false,
      controller: null,
    );

  }

  @override
  void dispose() {
    // disposeCamera() already handles cleanup when explicitly called
    // If not called, ensure cleanup happens on provider destruction
    if (state.isInitialized) {
      _cameraService.dispose();
    }
    super.dispose();
  }
}
