import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/mqtt_service.dart';
import '../services/ml_service.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  // Heart rate data
  double _currentHeartRate = 0.0;
  List<FlSpot> _heartRateData = [];
  List<double> _rawHeartRateData = [];
  int _dataPointCounter = 0;
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  // Prediction results
  Map<String, dynamic>? _predictionResult;
  bool _isPredicting = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _setupHeartRateListener();
    _initializeML();
  }

  Future<void> _initializeML() async {
    await MLService.instance.initialize();
  }

  void _setupHeartRateListener() {
    MqttService.instance.heartRateStream.listen((heartRate) {
      if (mounted) {
        setState(() {
          _currentHeartRate = heartRate;

          // Add to chart data
          _heartRateData.add(FlSpot(_dataPointCounter.toDouble(), heartRate));
          _dataPointCounter++;

          // If recording, add to raw data
          if (_isRecording) {
            _rawHeartRateData.add(heartRate);
          }

          // Keep only last 50 data points for chart
          if (_heartRateData.length > 50) {
            _heartRateData.removeAt(0);
            for (int i = 0; i < _heartRateData.length; i++) {
              _heartRateData[i] = FlSpot(i.toDouble(), _heartRateData[i].y);
            }
            _dataPointCounter = _heartRateData.length;
          }
        });
      }
    });
  }

  void _toggleRecording() async {
    if (!_isRecording) {
      // Start recording
      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _rawHeartRateData.clear();
        _showResults = false;
        _predictionResult = null;
      });
    } else {
      // Stop recording and predict
      setState(() {
        _isRecording = false;
        _isPredicting = true;
      });

      if (_rawHeartRateData.length >= 10) {
        // Make prediction
        final result = await MLService.instance.predictMBTI(_rawHeartRateData);

        setState(() {
          _predictionResult = result;
          _isPredicting = false;
          _showResults = true;
        });
      } else {
        setState(() {
          _isPredicting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough data. Record for at least 10 seconds.'),
          ),
        );
      }
    }
  }

  void _resetPrediction() {
    setState(() {
      _rawHeartRateData.clear();
      _predictionResult = null;
      _showResults = false;
      _recordingStartTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MBTI Prediction'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 20),
            _buildCurrentHeartRateCard(),
            const SizedBox(height: 20),
            _buildHeartRateChart(),
            const SizedBox(height: 20),
            _buildRecordingControls(),
            if (_showResults) ...[
              const SizedBox(height: 20),
              _buildPredictionResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade400),
                const SizedBox(width: 8),
                const Text(
                  'How it works',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Watch a heart-moving video\n'
              '2. Start recording your heart rate\n'
              '3. Let your emotions flow naturally\n'
              '4. Stop recording after at least 30 seconds\n'
              '5. Get your MBTI prediction (T or F)',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentHeartRateCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
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
              '${_currentHeartRate.toInt()} BPM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRecording ? Icons.fiber_manual_record : Icons.stop,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isRecording
                        ? 'Recording (${_rawHeartRateData.length} points)'
                        : 'Stopped',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heart Rate Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _heartRateData.isEmpty
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
                          verticalInterval: _heartRateData.length > 10
                              ? _heartRateData.length / 5
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
                              showTitles: true,
                              reservedSize: 30,
                              interval: _heartRateData.length > 10
                                  ? _heartRateData.length / 5
                                  : 2,
                              getTitlesWidget: (value, meta) {
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
                        maxX: _heartRateData.isNotEmpty
                            ? (_heartRateData.length - 1).toDouble()
                            : 1,
                        minY: 40,
                        maxY: 200,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _heartRateData,
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600,
                              ],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400.withOpacity(0.3),
                                  Colors.purple.shade600.withOpacity(0.1),
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

  Widget _buildRecordingControls() {
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
            if (_isRecording && _recordingStartTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Recording since: ${DateFormat('HH:mm:ss').format(_recordingStartTime!)}',
                  style: TextStyle(
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPredicting ? null : _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _isRecording ? 'Stop & Predict' : 'Start Recording',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    minimumSize: const Size(180, 48),
                  ),
                ),
                if (_showResults) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _resetPrediction,
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
            if (_isPredicting)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            if (_rawHeartRateData.isNotEmpty && !_showResults)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Recorded ${_rawHeartRateData.length} data points',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionResults() {
    if (_predictionResult == null) return const SizedBox.shrink();

    final prediction = _predictionResult!['prediction'] as String;
    final confidence = _predictionResult!['confidence'] as double;
    final details = _predictionResult!['details'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              prediction == 'T' ? Colors.blue.shade400 : Colors.pink.shade400,
              prediction == 'T' ? Colors.blue.shade600 : Colors.pink.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.psychology, color: Colors.white, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Your MBTI Prediction',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prediction == 'T' ? 'Thinking (T)' : 'Feeling (F)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildScoreBar(
                    'Thinking',
                    details['thinking_score'],
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildScoreBar(
                    'Feeling',
                    details['feeling_score'],
                    Colors.pink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              prediction == 'T'
                  ? 'You tend to make decisions based on logic and objective analysis.'
                  : 'You tend to make decisions based on personal values and emotions.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(score * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
