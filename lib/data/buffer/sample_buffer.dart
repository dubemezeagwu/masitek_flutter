import '../../core/app_core.dart';


class SampleBuffer {
  final List<ProcessedSample> _buffer = [];

  void addAll(List<ProcessedSample> samples) {
    _buffer.addAll(samples);
  }

  List<ProcessedSample> flush() {
    final flushed = List<ProcessedSample>.from(_buffer);
    _buffer.clear();
    return flushed;
  }

  int get count => _buffer.length;

  // clears buffer without returning samples.
  void clear() {
    _buffer.clear();
  }
}
