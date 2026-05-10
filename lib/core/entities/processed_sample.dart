class ProcessedSample {
  final int channel;
  final int rawValue;
  final double processedValue;
  final DateTime timestamp;

  ProcessedSample({
    required this.channel,
    required this.rawValue,
    required this.processedValue,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'rawValue': rawValue,
        'processedValue': processedValue,
        'timestamp': timestamp.toIso8601String(),
      };
}
