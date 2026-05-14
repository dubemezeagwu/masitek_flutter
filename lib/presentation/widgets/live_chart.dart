import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';

/// Live chart displaying raw sensor values in real-time.
///
/// Updates automatically as new data arrives via BLE.
/// Keeps last 1000 points in buffer for pan navigation.
class LiveChart extends ConsumerStatefulWidget {
  const LiveChart({super.key});

  @override
  ConsumerState<LiveChart> createState() => _LiveChartState();
}

class _LiveChartState extends ConsumerState<LiveChart> {
  // Default visible window size (can pan to see more)
  static const int _defaultVisiblePoints = 250;

  // Pan offset (how many points to shift the window left from the end)
  double _panOffset = 0;

  @override
  Widget build(BuildContext context) {
    final chartState = ref.watch(chartProvider);

    // Show placeholder if no data yet
    if (!chartState.hasData) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                'Waiting for data...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate visible window with pan offset using absolute sample indices
    final totalPoints = chartState.dataPoints.length;

    // Calculate window bounds based on actual sample indices
    final lastDataIndex = totalPoints - 1;

    // Calculate which data points to show (based on array position)
    final windowEndIndex = (lastDataIndex - _panOffset.toInt()).clamp(0, lastDataIndex);
    final windowStartIndex = (windowEndIndex - _defaultVisiblePoints + 1).clamp(0, windowEndIndex);

    // Get the actual sample indices for minX and maxX
    final minX = chartState.dataPoints[windowStartIndex].sampleIndex.toDouble();
    final maxX = chartState.dataPoints[windowEndIndex].sampleIndex.toDouble();

    // Build chart with data
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Legend at top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Raw values legend
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Raw Values',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                // Processed values legend (now active!)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Processed Values',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Chart with pan gesture
          Expanded(
            child: GestureDetector(
              // Only intercept horizontal drags for panning
              onHorizontalDragStart: (_) {
                // Disable chart touch when panning starts
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  // Pan sensitivity: 1 pixel = 0.5 data points
                  final delta = -details.delta.dx * 0.5;
                  _panOffset = (_panOffset + delta).clamp(0, totalPoints - _defaultVisiblePoints.toDouble());
                });
              },
              onHorizontalDragEnd: (_) {
                // Snap to live view if close to end
                if (_panOffset < 10) {
                  setState(() {
                    _panOffset = 0;
                  });
                }
              },
              // Allow chart's tap detection to work
              behavior: HitTestBehavior.deferToChild,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    // Data series
                    lineBarsData: [
                      // Raw values series (blue line)
                      LineChartBarData(
                        spots: chartState.dataPoints
                            .map((point) => FlSpot(
                                  point.sampleIndex.toDouble(), // X: absolute sample index
                                  point.rawValueDouble, // Y: raw value
                                ))
                            .toList(),
                        isCurved: false, // Straight lines between points
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),

                      // Processed values series (red line)
                      LineChartBarData(
                        spots: chartState.dataPoints
                            .where((point) => point.processedValue != null)
                            .map((point) => FlSpot(
                                  point.sampleIndex.toDouble(), // X: absolute sample index
                                  point.processedValue!, // Y: processed value
                                ))
                            .toList(),
                        isCurved: false,
                        color: Colors.red,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],

                    // Grid styling
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: null,
                      verticalInterval: null,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),

                    // Border styling
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),

                    // Axis numbers only (no titles)
                    titlesData: FlTitlesData(
                      // Bottom axis (X - sample index)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: null,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),

                      // Left axis (Y - raw value)
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: null,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),

                      // Hide top and right titles
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),

                    // Enable touch tooltip with crosshair
                    lineTouchData: LineTouchData(
                      enabled: true,
                      // Show horizontal and vertical indicator lines
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            // Vertical line (from point to X-axis)
                            FlLine(
                              color: Colors.grey.shade600,
                              strokeWidth: 1.5,
                              dashArray: [5, 5], // Dashed line
                            ),
                            // Dot at the touched point
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                      // Horizontal line from point to Y-axis
                      touchSpotThreshold: 10,
                      getTouchLineEnd: (_, __) => double.infinity,
                      getTouchLineStart: (_, __) => -double.infinity,
                      // Tooltip configuration
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Index: ${spot.x.toInt()}\nValue: ${spot.y.toInt()}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),

                    // Set visible window bounds (controlled by pan)
                    minX: minX,
                    maxX: maxX,
                    minY: null, // Auto-calculate
                    maxY: null, // Auto-calculate

                    // Enable clipping
                    clipData: const FlClipData.all(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
