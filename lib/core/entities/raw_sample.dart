class RawSample {
  final int channel; // uint16
  final int value; // int16
  final DateTime timestamp;

  RawSample({
    required this.channel,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
      };
}
