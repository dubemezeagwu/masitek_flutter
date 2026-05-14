import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/chart_data_point.dart';

/// Maximum number of data points to keep in buffer.
/// Allows panning back through historical data.
/// Memory: ~1000 points = ~32KB (negligible overhead)
const int kMaxChartPoints = 1000;

/// State holding chart data with rolling window.
class ChartState {
  /// Rolling window of data points (max 1000)
  final List<ChartDataPoint> dataPoints;

  /// Absolute sample counter (increments forever, never resets)
  final int nextSampleIndex;

  const ChartState({
    required this.dataPoints,
    required this.nextSampleIndex,
  });

  /// Initial empty state
  const ChartState.initial() : dataPoints = const [], nextSampleIndex = 0;

  /// Creates new state with updated data points
  ChartState copyWith({
    List<ChartDataPoint>? dataPoints,
    int? nextSampleIndex,
  }) {
    return ChartState(
      dataPoints: dataPoints ?? this.dataPoints,
      nextSampleIndex: nextSampleIndex ?? this.nextSampleIndex,
    );
  }

  /// Whether chart has any data to display
  bool get hasData => dataPoints.isNotEmpty;

  /// Number of points currently in buffer
  int get pointCount => dataPoints.length;
}

/// Notifier managing chart data state.
class ChartNotifier extends StateNotifier<ChartState> {
  ChartNotifier() : super(const ChartState.initial());

  /// Adds a new data point to the chart.
  ///
  /// Automatically enforces 1000-point rolling window by dropping oldest points.
  /// Assigns absolute sample index automatically.
  void addDataPoint(ChartDataPoint point) {
    // Create new point with assigned sample index
    final indexedPoint = ChartDataPoint(
      sampleIndex: state.nextSampleIndex,
      timestamp: point.timestamp,
      rawValue: point.rawValue,
      processedValue: point.processedValue,
    );

    final updatedPoints = List<ChartDataPoint>.from(state.dataPoints);
    updatedPoints.add(indexedPoint);

    // Enforce rolling window: keep only last 1000 points
    if (updatedPoints.length > kMaxChartPoints) {
      updatedPoints.removeAt(0); // Remove oldest point
    }

    state = state.copyWith(
      dataPoints: updatedPoints,
      nextSampleIndex: state.nextSampleIndex + 1,
    );
  }

  /// Adds multiple data points at once (batch operation).
  ///
  /// More efficient than calling addDataPoint repeatedly.
  /// Assigns absolute sample indices automatically.
  void addDataPoints(List<ChartDataPoint> points) {
    final updatedPoints = List<ChartDataPoint>.from(state.dataPoints);
    int currentIndex = state.nextSampleIndex;

    // Assign sample indices to each point
    for (final point in points) {
      final indexedPoint = ChartDataPoint(
        sampleIndex: currentIndex,
        timestamp: point.timestamp,
        rawValue: point.rawValue,
        processedValue: point.processedValue,
      );
      updatedPoints.add(indexedPoint);
      currentIndex++;
    }

    // Enforce rolling window
    while (updatedPoints.length > kMaxChartPoints) {
      updatedPoints.removeAt(0);
    }

    state = state.copyWith(
      dataPoints: updatedPoints,
      nextSampleIndex: currentIndex,
    );
  }

  /// Clears all chart data (e.g., on disconnect or new session).
  void clearData() {
    state = const ChartState.initial();
  }
}

/// Provider for chart data state.
final chartProvider = StateNotifierProvider<ChartNotifier, ChartState>((ref) {
  return ChartNotifier();
});
