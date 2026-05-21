import '../../core/app_core.dart';
import '../app_presentation.dart';

class PerformanceOverlay extends ConsumerWidget {
  const PerformanceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfState = ref.watch(performanceProvider);

    if (!perfState.overlayVisible) {
      return const SizedBox.shrink();
    }

    final metrics = perfState.metrics;

    return Positioned(
      top: 50,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(178),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Performance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // FPS
            _MetricRow(
              label: 'FPS',
              value: metrics.fps.toStringAsFixed(1),
              color: metrics.fps.fpsColor,
            ),

            // Memory (placeholder - shows 0.0 for now)
            _MetricRow(
              label: 'Memory',
              value: '${metrics.memoryUsageMB.toStringAsFixed(1)} MB',
              color: Colors.cyan,
            ),

            // BLE notification rate
            _MetricRow(
              label: 'BLE',
              value: '${metrics.bleNotificationRate}/s',
              color: Colors.blue,
            ),

            // Chart render rate
            _MetricRow(
              label: 'Chart',
              value: '${metrics.chartRenderRate}/s',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
