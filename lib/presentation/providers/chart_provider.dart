import '../../core/app_core.dart';
import '../app_presentation.dart';

class ChartState {
  final List<ChartDataPoint> dataPoints;

  final int nextSampleIndex;

  const ChartState({
    required this.dataPoints,
    required this.nextSampleIndex,
  });

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

  bool get hasData => dataPoints.isNotEmpty;

  int get pointCount => dataPoints.length;
}

class ChartNotifier extends StateNotifier<ChartState> {
  final Ref ref;

  ChartNotifier(this.ref) : super(const ChartState.initial());


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

    if (updatedPoints.length > BLEConstants.maxChartPoints) {
      updatedPoints.removeAt(0);
    }

    state = state.copyWith(
      dataPoints: updatedPoints,
      nextSampleIndex: state.nextSampleIndex + 1,
    );
  }


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

    while (updatedPoints.length > BLEConstants.maxChartPoints) {
      updatedPoints.removeAt(0);
    }

    state = state.copyWith(
      dataPoints: updatedPoints,
      nextSampleIndex: currentIndex,
    );

    // Track chart render for performance metrics
    ref.read(performanceProvider.notifier).recordChartRender();
  }

  void clearData() {
    state = const ChartState.initial();
  }
}

/// Provider for chart data state.
final chartProvider = StateNotifierProvider<ChartNotifier, ChartState>((ref) {
  return ChartNotifier(ref);
});
