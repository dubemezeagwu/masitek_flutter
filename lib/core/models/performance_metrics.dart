// performance metrics for seeing processing data

class PerformanceMetrics {
  final double fps;
  final double memoryUsageMB;
  final int bleNotificationRate;
  final int chartRenderRate;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.fps,
    required this.memoryUsageMB,
    required this.bleNotificationRate,
    required this.chartRenderRate,
    required this.timestamp,
  });

  PerformanceMetrics copyWith({
    double? fps,
    double? memoryUsageMB,
    int? bleNotificationRate,
    int? chartRenderRate,
    DateTime? timestamp,
  }) {
    return PerformanceMetrics(
      fps: fps ?? this.fps,
      memoryUsageMB: memoryUsageMB ?? this.memoryUsageMB,
      bleNotificationRate: bleNotificationRate ?? this.bleNotificationRate,
      chartRenderRate: chartRenderRate ?? this.chartRenderRate,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory PerformanceMetrics.initial() {
    return PerformanceMetrics(
      fps: 0.0,
      memoryUsageMB: 0.0,
      bleNotificationRate: 0,
      chartRenderRate: 0,
      timestamp: DateTime.now(),
    );
  }
}
