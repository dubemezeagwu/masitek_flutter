/// Single decoded sensor reading from BLE payload.
///
/// Represents one sample extracted from the 8-byte BLE notification.
/// Each notification contains exactly 2 samples.
class RawSample {
  /// Channel identifier (uint16, typically fixed at 1)
  final int channel;

  /// Scaled sensor value (int16, can be negative)
  final int value;

  /// Timestamp when sample was received
  final DateTime timestamp;

  const RawSample({
    required this.channel,
    required this.value,
    required this.timestamp,
  });

  /// Converts sample to JSON format for persistence.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'channel': channel,
      'value': value,
    };
  }

  /// Creates sample from JSON (for loading saved data).
  factory RawSample.fromJson(Map<String, dynamic> json) {
    return RawSample(
      channel: json['channel'] as int,
      value: json['value'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'RawSample(channel: $channel, value: $value, time: ${timestamp.toIso8601String()})';
  }
}
