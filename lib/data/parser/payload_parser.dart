import 'dart:typed_data';
import '../../core/app_core.dart';

/// Utility for parsing 8-byte BLE payloads into RawSample objects.
///
/// Protocol:
/// - Each notification: 8 bytes = 2 samples
/// - Sample format: [uint16 channel, int16 value] (big-endian)
/// - Bytes 0-3: Sample 1
/// - Bytes 4-7: Sample 2
class PayloadParser {
  /// Parses 8-byte payload into 2 RawSample objects.
  ///
  /// Throws [FormatException] if:
  /// - Payload length != 8 bytes
  /// - Data cannot be parsed
  static List<RawSample> parse(List<int> bytes) {
    if (bytes.length != 8) {
      throw FormatException(
        'Invalid payload size: expected 8 bytes, got ${bytes.length}. '
        'Hex dump: ${bytesToHex(bytes)}',
      );
    }

    try {
      final samples = <RawSample>[];
      final buffer = Uint8List.fromList(bytes).buffer;
      final data = ByteData.view(buffer);
      final timestamp = DateTime.now();

      // Parse first sample (bytes 0-3)
      final channel1 = data.getUint16(0, Endian.big);
      final value1 = data.getInt16(2, Endian.big);
      samples.add(RawSample(
        channel: channel1,
        value: value1,
        timestamp: timestamp,
      ));

      // Parse second sample (bytes 4-7)
      // Add 1 microsecond to differentiate timestamps
      final channel2 = data.getUint16(4, Endian.big);
      final value2 = data.getInt16(6, Endian.big);
      samples.add(RawSample(
        channel: channel2,
        value: value2,
        timestamp: timestamp.add(const Duration(microseconds: 1)),
      ));

      return samples;
    } catch (e) {
      throw FormatException(
        'Failed to parse payload: $e. '
        'Hex dump: ${bytesToHex(bytes)}',
      );
    }
  }

  /// Converts byte array to hex string for debugging.
  ///
  /// Example: [0, 1, 254, 255] → "00 01 FE FF"
  static String bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  /// Validates if payload can be parsed without exceptions.
  ///
  /// Returns true if valid, false otherwise.
  static bool isValidPayload(List<int> bytes) {
    try {
      parse(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
