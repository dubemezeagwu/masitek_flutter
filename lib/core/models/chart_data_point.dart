/// Single data point for chart visualization.
///
/// Holds both raw and processed values for dual-series display.
/// X-axis: sampleIndex (absolute counter), Y-axis: value
class ChartDataPoint {
  /// Absolute sample index (increments forever, never resets)
  final int sampleIndex;

  /// When this sample was received
  final DateTime timestamp;

  /// Raw sensor value (int16 from BLE)
  final int rawValue;

  /// Processed value from script engine (nullable until M7)
  final double? processedValue;

  const ChartDataPoint({
    required this.sampleIndex,
    required this.timestamp,
    required this.rawValue,
    this.processedValue,
  });

  /// Creates point from RawSample (no processing yet)
  ///
  /// Note: sampleIndex is set to 0 as placeholder. ChartProvider will assign correct index.
  factory ChartDataPoint.fromRawSample({
    required DateTime timestamp,
    required int rawValue,
  }) {
    return ChartDataPoint(
      sampleIndex: 0, // Placeholder - will be assigned by ChartProvider
      timestamp: timestamp,
      rawValue: rawValue,
      processedValue: null, // Will be populated in M7
    );
  }

  /// Creates point from ProcessedSample (with both raw and processed values)
  ///
  /// Note: sampleIndex is set to 0 as placeholder. ChartProvider will assign correct index.
  factory ChartDataPoint.fromProcessedSample({
    required DateTime timestamp,
    required int rawValue,
    required double processedValue,
  }) {
    return ChartDataPoint(
      sampleIndex: 0, // Placeholder - will be assigned by ChartProvider
      timestamp: timestamp,
      rawValue: rawValue,
      processedValue: processedValue,
    );
  }

  /// Time since epoch in milliseconds (for x-axis)
  double get timestampMs => timestamp.millisecondsSinceEpoch.toDouble();

  /// Raw value as double (for y-axis)
  double get rawValueDouble => rawValue.toDouble();

  @override
  String toString() {
    return 'ChartDataPoint(time: ${timestamp.toIso8601String()}, raw: $rawValue, processed: $processedValue)';
  }
}
