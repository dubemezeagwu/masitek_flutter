import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/performance_metrics.dart';

/// Performance metrics provider for tracking app performance.
///
/// Tracks:
/// - FPS (frames per second) via SchedulerBinding
/// - Memory usage (MB) via dart:developer
/// - BLE notification rate (notifications/sec)
/// - Chart render rate (renders/sec)
final performanceProvider = StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) {
  return PerformanceNotifier();
});

/// Performance state containing metrics and overlay visibility.
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
    // Start FPS tracking
    _startFpsTracking();
  }

  /// Start tracking FPS using SchedulerBinding.
  void _startFpsTracking() {
    SchedulerBinding.instance.addPostFrameCallback(_onFrameRendered);
  }

  /// Called after each frame render to calculate FPS.
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

  /// Start periodic metrics collection (every 1 second).
  void startTracking() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMetrics();
    });
  }

  /// Stop periodic metrics collection.
  void stopTracking() {
    _metricsTimer?.cancel();
  }

  /// Update metrics snapshot (called every 1 second).
  void _updateMetrics() {
    // Calculate rates (per second)
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

  /// Record a BLE notification received.
  void recordBleNotification() {
    _bleNotificationCount++;
  }

  /// Record a chart render.
  void recordChartRender() {
    _chartRenderCount++;
  }

  /// Toggle performance overlay visibility.
  void toggleOverlay() {
    state = state.copyWith(overlayVisible: !state.overlayVisible);

    // Start/stop tracking based on visibility
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
