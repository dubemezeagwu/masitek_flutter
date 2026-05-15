import '../../core/models/processed_sample.dart';

/// Buffer for accumulating processed samples during a recording session.
///
/// Responsibilities:
/// - Store all samples from connection start until flush
/// - Provide thread-safe access for isolate usage
/// - Support flush operation (retrieve + clear)
class SampleBuffer {
  final List<ProcessedSample> _buffer = [];

  /// Adds processed samples to the buffer.
  void addAll(List<ProcessedSample> samples) {
    _buffer.addAll(samples);
  }

  /// Flushes buffer and returns all accumulated samples.
  ///
  /// After flush, buffer is cleared and ready for next session.
  List<ProcessedSample> flush() {
    final flushed = List<ProcessedSample>.from(_buffer);
    _buffer.clear();
    return flushed;
  }

  /// Returns current sample count (for debugging).
  int get count => _buffer.length;

  /// Clears buffer without returning samples.
  void clear() {
    _buffer.clear();
  }
}
