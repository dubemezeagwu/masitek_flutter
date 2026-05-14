import 'dart:isolate';
import '../core/models/processed_sample.dart';
import '../core/utils/payload_parser.dart';

/// Message sent from main isolate to worker isolate
class WorkerMessage {
  final List<int> bytes;

  WorkerMessage(this.bytes);
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

  /// Callback for processed samples
  final void Function(List<ProcessedSample>) onProcessedSamples;

  WorkerIsolate({required this.onProcessedSamples});

  /// Spawns the worker isolate
  Future<void> spawn() async {
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      WorkerIsolateConfig(sendPort: _receivePort.sendPort),
    );

    // Listen for processed samples from worker
    _receivePort.listen((message) {
      if (message is SendPort) {
        // First message: worker's SendPort
        _sendPort = message;
      } else if (message is List<ProcessedSample>) {
        // Processed samples from worker
        onProcessedSamples(message);
      }
    });
  }

  /// Sends raw bytes to worker for processing
  void processBytes(List<int> bytes) {
    _sendPort?.send(WorkerMessage(bytes));
  }

  /// Kills the worker isolate
  void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  /// Entry point for worker isolate (runs in separate thread)
  static void _isolateEntryPoint(WorkerIsolateConfig config) {
    final receivePort = ReceivePort();

    // Send our SendPort back to main isolate
    config.sendPort.send(receivePort.sendPort);

    // Listen for incoming bytes from main isolate
    receivePort.listen((message) {
      if (message is WorkerMessage) {
        try {
          // Parse bytes into RawSamples
          final samples = PayloadParser.parse(message.bytes);

          // Apply transformation: processed = raw * 0.12 + 34
          final processedSamples = samples.map((sample) {
            final processedValue = sample.value * 0.12 + 34;
            return ProcessedSample.fromRawSample(
              channel: sample.channel,
              rawValue: sample.value,
              processedValue: processedValue,
              timestamp: sample.timestamp,
            );
          }).toList();

          // Send processed samples back to main isolate
          config.sendPort.send(processedSamples);
        } catch (e) {
          // Parse error - send empty list
          config.sendPort.send(<ProcessedSample>[]);
        }
      }
    });
  }
}
