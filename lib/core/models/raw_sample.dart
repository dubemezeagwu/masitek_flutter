// single decoded sensor reading from BLE payload.
// Represents one sample extracted from the 8-byte BLE notification.
// each notification contains exactly 2 samples.

class RawSample {
  // channel identifier (uint16, typically fixed at 1)
  final int channel;
  final int value;
  final DateTime timestamp;

  const RawSample({
    required this.channel,
    required this.value,
    required this.timestamp,
  });

  // Map<String, dynamic> toJson() {
  //   return {
  //     'timestamp': timestamp.toIso8601String(),
  //     'channel': channel,
  //     'value': value,
  //   };
  // }

  // creates sample from JSON (for loading saved data; future feat).
  // factory RawSample.fromJson(Map<String, dynamic> json) {
  //   return RawSample(
  //     channel: json['channel'] as int,
  //     value: json['value'] as int,
  //     timestamp: DateTime.parse(json['timestamp'] as String),
  //   );
  // }

  @override
  String toString() {
    return 'RawSample(channel: $channel, value: $value, time: ${timestamp.toIso8601String()})';
  }
}
