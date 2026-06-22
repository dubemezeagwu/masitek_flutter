import '../../core/app_core.dart';
import '../../data/app_data.dart';
import '../app_presentation.dart';

class BleDataProcessorState {
  final BleDataProcessor? processor;
  final bool isSpawned;

  BleDataProcessorState({
    this.processor,
    this.isSpawned = false,
  });

  BleDataProcessorState copyWith({
    BleDataProcessor? processor,
    bool? isSpawned,
  }) {
    return BleDataProcessorState(
      processor: processor ?? this.processor,
      isSpawned: isSpawned ?? this.isSpawned,
    );
  }
}

class BleDataProcessorNotifier extends StateNotifier<BleDataProcessorState> {
  final Ref ref;

  BleDataProcessorNotifier(this.ref) : super(BleDataProcessorState());

  Future<void> spawn() async {
    if (state.isSpawned) return;

    final chartNotifier = ref.read(chartProvider.notifier);

    final processor = BleDataProcessor(
      onProcessedSamples: (processedSamples) {
        final chartPoints = processedSamples.map((sample) {
          return ChartDataPoint.fromProcessedSample(
            timestamp: sample.timestamp,
            rawValue: sample.rawValue,
            processedValue: sample.processedValue,
          );
        }).toList();

        chartNotifier.addDataPoints(chartPoints);
      },
    );

    await processor.spawn();

    state = state.copyWith(
      processor: processor,
      isSpawned: true,
    );
  }

  void processBytes(List<int> bytes) {
    state.processor?.processBytes(bytes);
  }

  Future<List<ProcessedSample>> flushBuffer() async {
    if (state.processor == null) return [];
    return await state.processor!.flushBuffer();
  }

  Future<void> kill() async {
    state.processor?.kill();
    state = BleDataProcessorState();
  }
}

final bleDataProcessorProvider = StateNotifierProvider<BleDataProcessorNotifier, BleDataProcessorState>((ref) {
  return BleDataProcessorNotifier(ref);
});
