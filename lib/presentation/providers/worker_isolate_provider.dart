import '../../core/app_core.dart';
import '../../data/app_data.dart';
import '../app_presentation.dart';

class WorkerIsolateState {
  final WorkerIsolate? isolate;
  final bool isSpawned;

  WorkerIsolateState({
    this.isolate,
    this.isSpawned = false,
  });

  WorkerIsolateState copyWith({
    WorkerIsolate? isolate,
    bool? isSpawned,
  }) {
    return WorkerIsolateState(
      isolate: isolate ?? this.isolate,
      isSpawned: isSpawned ?? this.isSpawned,
    );
  }
}

class WorkerIsolateNotifier extends StateNotifier<WorkerIsolateState> {
  final Ref ref;

  WorkerIsolateNotifier(this.ref) : super(WorkerIsolateState());

  Future<void> spawn() async {
    if (state.isSpawned) return;

    final chartNotifier = ref.read(chartProvider.notifier);

    final isolate = WorkerIsolate(
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

    await isolate.spawn();

    state = state.copyWith(
      isolate: isolate,
      isSpawned: true,
    );
  }

  void processBytes(List<int> bytes) {
    state.isolate?.processBytes(bytes);
  }

  Future<List<ProcessedSample>> flushBuffer() async {
    if (state.isolate == null) return [];
    return await state.isolate!.flushBuffer();
  }

  Future<void> kill() async {
    state.isolate?.kill();
    state = WorkerIsolateState();
  }
}

final workerIsolateProvider = StateNotifierProvider<WorkerIsolateNotifier, WorkerIsolateState>((ref) {
  return WorkerIsolateNotifier(ref);
});
