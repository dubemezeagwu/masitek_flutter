import 'dart:async';
import 'dart:isolate';
import '../../core/app_core.dart';
import '../parser/payload_parser.dart';
import '../scripting/script_engine.dart';
import '../buffer/sample_buffer.dart';
import 'worker_messages.dart';

// Main spawns worker → Worker creates ReceivePort → Worker sends SendPort back
// Main receives SendPort → Stores in _sendPort → Communication ready

class BleDataProcessorConfig {
  final SendPort sendPort;

  BleDataProcessorConfig({required this.sendPort});
}

class BleDataProcessor {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;

  bool _isSpawned = false;
  final ReceivePort _receivePort = ReceivePort();
  Completer<List<ProcessedSample>>? _flushCompleter;

  // Buffer in main thread for safety and separation of concerns
  final SampleBuffer _buffer = SampleBuffer();

  final void Function(List<ProcessedSample>) onProcessedSamples;

  BleDataProcessor({required this.onProcessedSamples});

  Future<void> spawn() async {
    // if isolate has been spawned, return early
    if (_isSpawned) return;

    _errorPort = ReceivePort();
    _exitPort = ReceivePort();

    _errorPort!.listen((errorData) {
      debugPrint("Worker Isolate Error: ${errorData[0]}");
      debugPrint("Stack Trace: ${errorData[1]}");
      // TODO: Send to analytics in production
    });

    _exitPort!.listen((message) {
      debugPrint("Worker Isolate exited. Message $message");

      _isSpawned = false;

      // clean up
      _errorPort?.close();
      _exitPort?.close();
    });

    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      BleDataProcessorConfig(sendPort: _receivePort.sendPort),
      onError: _errorPort!.sendPort,
      onExit: _exitPort!.sendPort,
      debugName: "BLE-Worker",
    );

    _receivePort.listen((message) {
      if (message is SendPort) {
        // Handshake: worker sends its SendPort first
        _sendPort = message;
        _isSpawned = true;
      } else if (message is ProcessedDataResponse) {
        _buffer.addAll(message.samples);
        onProcessedSamples(message.samples);
      } else if (message is ParseErrorResponse) {
        debugPrint('Parse error: ${message.error}');
        debugPrint('Raw bytes: ${message.rawBytes}');
        debugPrint('Stack: ${message.stackTrace}');
        // TODO: Log to analytics in production
      } else if (message is BufferFlushResponse) {
        // Worker acknowledged - now flush main thread buffer
        final flushedSamples = _buffer.flush();
        _flushCompleter?.complete(flushedSamples);
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

    // Calculate dynamic timeout based on buffer size
    // Formula: 5s base + 1s per 1000 samples, capped at 30s
    final sampleCount = _buffer.count;
    final timeoutSeconds = (5 + (sampleCount ~/ 1000)).clamp(5, 30);
    final timeout = Duration(seconds: timeoutSeconds);

    try {
      return await _flushCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          debugPrint('⚠️ Flush timeout after ${timeoutSeconds}s for $sampleCount samples');
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
    _errorPort?.close();
    _exitPort?.close();
    _isSpawned = false;
    _sendPort = null;
    _buffer.clear(); // Clean up main thread buffer
  }

  // Worker entry point - runs in separate OS thread (STATELESS)
  static void _workerEntryPoint(BleDataProcessorConfig config) {
    
    // TODO: Add thread priority optimization via platform channel
  
    final receivePort = ReceivePort();

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

          // Send processed data back - no buffering in worker
          config.sendPort.send(ProcessedDataResponse(processedSamples));
        } catch (e, stackTrace) {
          config.sendPort.send(
            ParseErrorResponse(
              error: e.toString(),
              stackTrace: stackTrace.toString(),
              rawBytes: message.bytes,
            ),
          );
        }
      } else if (message is FlushBufferCommand) {
        // Worker has no buffer - just acknowledge the flush request
        // Main thread will flush its own buffer when it receives this
        config.sendPort.send(BufferFlushResponse(const []));
      }
    });
  }
}
