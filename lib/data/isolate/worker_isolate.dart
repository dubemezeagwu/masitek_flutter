import 'dart:async';
import 'dart:isolate';
import '../../core/app_core.dart';
import '../parser/payload_parser.dart';
import '../scripting/script_engine.dart';
import '../buffer/sample_buffer.dart';

// Main spawns worker → Worker creates ReceivePort → Worker sends SendPort back
// Main receives SendPort → Stores in _sendPort → Communication ready

class WorkerMessage { // Main -> Buffer
  final List<int> bytes;

  WorkerMessage(this.bytes);
}

class FlushBufferCommand { // Main -> Buffer
  const FlushBufferCommand();
}

class BufferFlushResponse { // Buffer -> Main
  final List<ProcessedSample> samples;

  BufferFlushResponse(this.samples);
}

class WorkerIsolateConfig {
  final SendPort sendPort;

  WorkerIsolateConfig({required this.sendPort});
}

class WorkerIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  Completer<List<ProcessedSample>>? _flushCompleter;

  final void Function(List<ProcessedSample>) onProcessedSamples;

  WorkerIsolate({required this.onProcessedSamples});

  Future<void> spawn() async {
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      WorkerIsolateConfig(sendPort: _receivePort.sendPort),
    );

    _receivePort.listen((message) {
      if (message is SendPort) {
        // Handshake: worker sends its SendPort first
        _sendPort = message;
      } else if (message is List<ProcessedSample>) {
        onProcessedSamples(message);
      } else if (message is BufferFlushResponse) {
        _flushCompleter?.complete(message.samples);
        _flushCompleter = null;
      }
    });
  }

  void processBytes(List<int> bytes) {
    _sendPort?.send(WorkerMessage(bytes));
  }


  Future<List<ProcessedSample>> flushBuffer() async {
    if (_sendPort == null) {
      return [];
    }

    _flushCompleter = Completer<List<ProcessedSample>>();
    _sendPort!.send(const FlushBufferCommand());

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

  void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  // Worker isolate entry point - runs in separate OS thread
  static void _isolateEntryPoint(WorkerIsolateConfig config) {
    final receivePort = ReceivePort();
    final buffer = SampleBuffer();

    // Handshake: send our SendPort to main isolate
    config.sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is WorkerMessage) {
        try {
          final samples = PayloadParser.parse(message.bytes);

          final processedSamples = samples.map((sample) {
            final processedValue = ScriptEngine.transform(sample.value);
            return ProcessedSample.fromRawSample(
              channel: sample.channel,
              rawValue: sample.value,
              processedValue: processedValue,
              timestamp: sample.timestamp,
            );
          }).toList();

          buffer.addAll(processedSamples);
          config.sendPort.send(processedSamples);
        } catch (e) {
          config.sendPort.send(<ProcessedSample>[]);
        }
      } else if (message is FlushBufferCommand) {
        final flushedSamples = buffer.flush();
        config.sendPort.send(BufferFlushResponse(flushedSamples));
      }
    });
  }
}
