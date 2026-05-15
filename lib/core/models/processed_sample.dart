/// Output of scripting engine applied to a RawSample.
///
/// Contains both the original raw value and the processed result
/// from running the JavaScript transformation script.
class ProcessedSample {
  /// Channel identifier (copied from RawSample)
  final int channel;

  /// Original raw sensor value (int16)
  final int rawValue;

  /// Processed value after script transformation (double)
  final double processedValue;

  /// Timestamp when sample was received
  final DateTime timestamp;

  const ProcessedSample({
    required this.channel,
    required this.rawValue,
    required this.processedValue,
    required this.timestamp,
  });

  /// Creates from RawSample with script result
  factory ProcessedSample.fromRawSample({
    required int channel,
    required int rawValue,
    required double processedValue,
    required DateTime timestamp,
  }) {
    return ProcessedSample(
      channel: channel,
      rawValue: rawValue,
      processedValue: processedValue,
      timestamp: timestamp,
    );
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'channel': channel,
      'rawValue': rawValue,
      'processedValue': processedValue,
    };
  }

  /// Creates from JSON (for loading saved data)
  factory ProcessedSample.fromJson(Map<String, dynamic> json) {
    return ProcessedSample(
      channel: json['channel'] as int,
      rawValue: json['rawValue'] as int,
      processedValue: (json['processedValue'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'ProcessedSample(channel: $channel, raw: $rawValue, processed: $processedValue, time: ${timestamp.toIso8601String()})';
  }
}
