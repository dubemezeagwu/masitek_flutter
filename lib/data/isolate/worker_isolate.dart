import 'dart:async';
import 'dart:isolate';
import '../../core/models/processed_sample.dart';
import '../parser/payload_parser.dart';
import '../scripting/script_engine.dart';
import '../buffer/sample_buffer.dart';

/// Message sent from main isolate to worker isolate
class WorkerMessage {
  final List<int> bytes;

  WorkerMessage(this.bytes);
}

/// Command to flush the buffer and return all accumulated samples
class FlushBufferCommand {
  const FlushBufferCommand();
}

/// Response containing flushed samples from buffer
class BufferFlushResponse {
  final List<ProcessedSample> samples;

  BufferFlushResponse(this.samples);
}

/// Configuration for spawning worker isolate
class WorkerIsolateConfig {
  final SendPort sendPort;

  WorkerIsolateConfig({required this.sendPort});
}

/// Worker isolate for CPU-intensive data processing.
///
/// Runs in separate OS thread to avoid blocking UI.
/// Handles: parsing and data transformation.
class WorkerIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  Completer<List<ProcessedSample>>? _flushCompleter;

  /// Callback for processed samples (real-time chart updates)
  final void Function(List<ProcessedSample>) onProcessedSamples;

  WorkerIsolate({required this.onProcessedSamples});

  /// Spawns the worker isolate
  Future<void> spawn() async {
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      WorkerIsolateConfig(sendPort: _receivePort.sendPort),
    );

    // Listen for messages from worker
    _receivePort.listen((message) {
      if (message is SendPort) {
        // First message: worker's SendPort
        _sendPort = message;
      } else if (message is List<ProcessedSample>) {
        // Processed samples from worker (real-time chart updates)
        onProcessedSamples(message);
      } else if (message is BufferFlushResponse) {
        // Complete the flush Future with buffered samples
        _flushCompleter?.complete(message.samples);
        _flushCompleter = null;
      }
    });
  }

  /// Sends raw bytes to worker for processing
  void processBytes(List<int> bytes) {
    _sendPort?.send(WorkerMessage(bytes));
  }

  /// Flushes the buffer and returns all accumulated samples.
  ///
  /// Returns empty list if worker not ready or flush times out.
  /// This is typically called when stopping a recording session.
  Future<List<ProcessedSample>> flushBuffer() async {
    if (_sendPort == null) {
      return [];
    }

    // Create completer for this flush request
    _flushCompleter = Completer<List<ProcessedSample>>();

    // Send flush command to worker
    _sendPort!.send(const FlushBufferCommand());

    // Wait for response with 5-second timeout
    try {
      return await _flushCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _flushCompleter = null;
          return [];
        },
      );
    } catch (e) {
      _flushCompleter = null;
      return [];
    }
  }

  /// Kills the worker isolate
  void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  /// Entry point for worker isolate (runs in separate thread)
  static void _isolateEntryPoint(WorkerIsolateConfig config) {
    final receivePort = ReceivePort();

    // Buffer to accumulate all processed samples from connection start
    final buffer = SampleBuffer();

    // Send our SendPort back to main isolate
    config.sendPort.send(receivePort.sendPort);

    // Listen for incoming messages from main isolate
    receivePort.listen((message) {
      if (message is WorkerMessage) {
        try {
          // Parse bytes into RawSamples using parser module
          final samples = PayloadParser.parse(message.bytes);

          // Apply transformation using script engine module
          final processedSamples = samples.map((sample) {
            final processedValue = ScriptEngine.transform(sample.value);
            return ProcessedSample.fromRawSample(
              channel: sample.channel,
              rawValue: sample.value,
              processedValue: processedValue,
              timestamp: sample.timestamp,
            );
          }).toList();

          // Add to buffer for persistence
          buffer.addAll(processedSamples);

          // Send processed samples back to main isolate for real-time chart updates
          config.sendPort.send(processedSamples);
        } catch (e) {
          // Parse error - send empty list
          config.sendPort.send(<ProcessedSample>[]);
        }
      } else if (message is FlushBufferCommand) {
        // Flush buffer: send all accumulated samples and clear
        final flushedSamples = buffer.flush();

        // Send buffered samples back to main isolate
        config.sendPort.send(BufferFlushResponse(flushedSamples));
      }
    });
  }
}
