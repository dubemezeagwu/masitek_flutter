// Single data point for chart visualization.
class ChartDataPoint {
  // absolute sample index (increments forever, never resets)
  final int sampleIndex;
  final DateTime timestamp;

  // raw sensor value (int16 from BLE)
  final int rawValue;

  // processed sensor value (transformed from isolate buffer)
  final double? processedValue;

  const ChartDataPoint({
    required this.sampleIndex,
    required this.timestamp,
    required this.rawValue,
    this.processedValue,
  });

  // sampleIndex is set to 0 as placeholder. ChartProvider will assign correct index.
  factory ChartDataPoint.fromRawSample({
    required DateTime timestamp,
    required int rawValue,
  }) {
    return ChartDataPoint(
      sampleIndex: 0,
      timestamp: timestamp,
      rawValue: rawValue,
      processedValue: null,
    );
  }

  // sampleIndex is set to 0 as placeholder. ChartProvider will assign correct index.
  factory ChartDataPoint.fromProcessedSample({
    required DateTime timestamp,
    required int rawValue,
    required double processedValue,
  }) {
    return ChartDataPoint(
      sampleIndex: 0,
      timestamp: timestamp,
      rawValue: rawValue,
      processedValue: processedValue,
    );
  }

  /// time since epoch in milliseconds (for x-axis)
  double get timestampMs => timestamp.millisecondsSinceEpoch.toDouble();

  /// raw value as double (for y-axis)
  double get rawValueDouble => rawValue.toDouble();

  @override
  String toString() {
    return 'ChartDataPoint(time: ${timestamp.toIso8601String()}, raw: $rawValue, processed: $processedValue)';
  }
}
