// output of scripting engine applied to a RawSample.
// contains both the original raw value and the processed result
// from running the transformation script.

class ProcessedSample {
  final int channel;
  final int rawValue;
  final double processedValue;
  final DateTime timestamp;

  const ProcessedSample({
    required this.channel,
    required this.rawValue,
    required this.processedValue,
    required this.timestamp,
  });

  // creates from RawSample with script result
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

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'channel': channel,
      'rawValue': rawValue,
      'processedValue': processedValue,
    };
  }

  // creates from JSON (for loading saved data; future feature)
  // factory ProcessedSample.fromJson(Map<String, dynamic> json) {
  //   return ProcessedSample(
  //     channel: json['channel'] as int,
  //     rawValue: json['rawValue'] as int,
  //     processedValue: (json['processedValue'] as num).toDouble(),
  //     timestamp: DateTime.parse(json['timestamp'] as String),
  //   );
  // }

  @override
  String toString() {
    return 'ProcessedSample(channel: $channel, raw: $rawValue, processed: $processedValue, time: ${timestamp.toIso8601String()})';
  }
}
