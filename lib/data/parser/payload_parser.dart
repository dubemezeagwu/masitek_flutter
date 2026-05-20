import 'dart:typed_data';
import '../../core/app_core.dart';

class PayloadParser {
  // - Sample format: [uint16 channel, int16 value] (big-endian)
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

  // Example: [0, 1, 254, 255] → "00 01 FE FF"
  static String bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }
  
  static bool isValidPayload(List<int> bytes) {
    try {
      parse(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
