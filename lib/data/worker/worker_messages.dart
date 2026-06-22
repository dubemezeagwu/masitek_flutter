import '../../core/app_core.dart';

/// Messages sent FROM main isolate TO worker isolate
class WorkerMessage {
  final List<int> bytes;
  WorkerMessage(this.bytes);
}

class FlushBufferCommand {
  const FlushBufferCommand();
}

/// Messages sent FROM worker isolate TO main isolate
sealed class WorkerResponse {}

class ProcessedDataResponse extends WorkerResponse {
  final List<ProcessedSample> samples;
  ProcessedDataResponse(this.samples);
}

class ParseErrorResponse extends WorkerResponse {
  final String error;
  final String stackTrace;
  final List<int> rawBytes;

  ParseErrorResponse({
    required this.error,
    required this.stackTrace,
    required this.rawBytes,
  });
}

class BufferFlushResponse {
  final List<ProcessedSample> samples;
  BufferFlushResponse(this.samples);
}
