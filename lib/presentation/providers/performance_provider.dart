import 'dart:async';
import 'package:flutter/scheduler.dart';
import '../../core/app_core.dart';
import '../app_presentation.dart';

final performanceProvider = StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) {
  return PerformanceNotifier();
});

class PerformanceState {
  final PerformanceMetrics metrics;
  final bool overlayVisible;

  const PerformanceState({
    required this.metrics,
    required this.overlayVisible,
  });

  PerformanceState copyWith({
    PerformanceMetrics? metrics,
    bool? overlayVisible,
  }) {
    return PerformanceState(
      metrics: metrics ?? this.metrics,
      overlayVisible: overlayVisible ?? this.overlayVisible,
    );
  }
}

/// Performance notifier managing metrics collection and updates.
class PerformanceNotifier extends StateNotifier<PerformanceState> {
  Timer? _metricsTimer;
  int _bleNotificationCount = 0;
  int _chartRenderCount = 0;
  DateTime? _lastFpsTimestamp;
  int _frameCount = 0;
  double _currentFps = 0.0;

  PerformanceNotifier()
      : super(PerformanceState(
          metrics: PerformanceMetrics.initial(),
          overlayVisible: false,
        )) {

    _startFpsTracking();
  }

  // Start tracking FPS using SchedulerBinding.
  void _startFpsTracking() {
    SchedulerBinding.instance.addPostFrameCallback(_onFrameRendered);
  }

  // Called after each frame render to calculate FPS.
  void _onFrameRendered(Duration timestamp) {
    _frameCount++;

    final now = DateTime.now();
    if (_lastFpsTimestamp != null) {
      final elapsed = now.difference(_lastFpsTimestamp!);
      if (elapsed.inMilliseconds >= 1000) {
        // Calculate FPS over the last second
        _currentFps = _frameCount / (elapsed.inMilliseconds / 1000.0);
        _frameCount = 0;
        _lastFpsTimestamp = now;
      }
    } else {
      _lastFpsTimestamp = now;
    }

    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrameRendered);
  }

  void startTracking() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMetrics();
    });
  }

  void stopTracking() {
    _metricsTimer?.cancel();
  }

  void _updateMetrics() {

    final bleRate = _bleNotificationCount;
    final chartRate = _chartRenderCount;

    // Update state
    state = state.copyWith(
      metrics: PerformanceMetrics(
        fps: _currentFps,
        memoryUsageMB: 0.0, // Placeholder - accurate tracking requires DevTools protocol
        bleNotificationRate: bleRate,
        chartRenderRate: chartRate,
        timestamp: DateTime.now(),
      ),
    );

    // Reset counters
    _bleNotificationCount = 0;
    _chartRenderCount = 0;
  }

  void recordBleNotification() {
    _bleNotificationCount++;
  }

  void recordChartRender() {
    _chartRenderCount++;
  }

  void toggleOverlay() {
    state = state.copyWith(overlayVisible: !state.overlayVisible);

    if (state.overlayVisible) {
      startTracking();
    } else {
      stopTracking();
    }
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    super.dispose();
  }
}
