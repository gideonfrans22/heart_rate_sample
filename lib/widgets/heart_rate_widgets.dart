import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// A card displaying the current heart rate with customizable color and status badge
class HeartRateCard extends StatelessWidget {
  final double heartRate;
  final Color primaryColor;
  final Color secondaryColor;
  final Widget? statusBadge;

  const HeartRateCard({
    super.key,
    required this.heartRate,
    this.primaryColor = Colors.red,
    Color? secondaryColor,
    this.statusBadge,
  }) : secondaryColor = secondaryColor ?? primaryColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.8), secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Current Heart Rate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${heartRate.toInt()} BPM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (statusBadge != null) ...[
              const SizedBox(height: 8),
              statusBadge!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Status badge widget for connection status
class ConnectionStatusBadge extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusBadge({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Status badge widget for recording status
class RecordingStatusBadge extends StatelessWidget {
  final bool isRecording;
  final int dataPointCount;

  const RecordingStatusBadge({
    super.key,
    required this.isRecording,
    this.dataPointCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecording ? Icons.fiber_manual_record : Icons.stop,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isRecording ? 'Recording ($dataPointCount points)' : 'Stopped',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A chart displaying heart rate trend over time
class HeartRateChart extends StatelessWidget {
  final List<FlSpot> heartRateData;
  final Color primaryColor;
  final Color secondaryColor;
  final String title;
  final bool showTimeLabels;

  const HeartRateChart({
    super.key,
    required this.heartRateData,
    this.primaryColor = Colors.red,
    Color? secondaryColor,
    this.title = 'Heart Rate Trend',
    this.showTimeLabels = true,
  }) : secondaryColor = secondaryColor ?? primaryColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: heartRateData.isEmpty
                  ? const Center(
                      child: Text(
                        'No heart rate data available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 20,
                          verticalInterval: heartRateData.length > 10
                              ? heartRateData.length / 5
                              : 2,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: showTimeLabels,
                              reservedSize: 30,
                              interval: heartRateData.length > 10
                                  ? heartRateData.length / 5
                                  : 2,
                              getTitlesWidget: (value, meta) {
                                if (!showTimeLabels || heartRateData.isEmpty) {
                                  return const Text('');
                                }
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < heartRateData.length) {
                                  return Text(
                                    '${index}s',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 42,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: heartRateData.isNotEmpty
                            ? (heartRateData.length - 1).toDouble()
                            : 1,
                        minY: 40,
                        maxY: 200,
                        lineBarsData: [
                          LineChartBarData(
                            spots: heartRateData,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.8),
                                secondaryColor,
                              ],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.3),
                                  secondaryColor.withOpacity(0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recording controls widget with start/stop and reset buttons
class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPredicting;
  final bool showResults;
  final int recordedDataCount;
  final DateTime? recordingStartTime;
  final VoidCallback onToggleRecording;
  final VoidCallback? onReset;
  final String startLabel;
  final String stopLabel;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.onToggleRecording,
    this.isPredicting = false,
    this.showResults = false,
    this.recordedDataCount = 0,
    this.recordingStartTime,
    this.onReset,
    this.startLabel = 'Start Recording',
    this.stopLabel = 'Stop Recording',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Recording Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isRecording && recordingStartTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Recording since: ${_formatTime(recordingStartTime!)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isPredicting ? null : onToggleRecording,
                  icon: Icon(isRecording ? Icons.stop : Icons.play_arrow),
                  label: Text(isRecording ? stopLabel : startLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    minimumSize: const Size(180, 48),
                  ),
                ),
                if (showResults && onReset != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (recordedDataCount > 0 && !showResults && !isPredicting)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Recorded $recordedDataCount data points',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
