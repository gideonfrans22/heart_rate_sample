import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _currentHeartRate = 0.0;
  List<FlSpot> _heartRateData = [];
  List<Map<String, dynamic>> _recentUsers = [];
  bool _isLoading = true;
  int _dataPointCounter = 0;

  @override
  void initState() {
    super.initState();
    _setupHeartRateListener();
    _loadRecentUsers();
  }

  void _setupHeartRateListener() {
    MqttService.instance.heartRateStream.listen((heartRate) {
      if (mounted) {
        setState(() {
          _currentHeartRate = heartRate;

          // Add to chart data using incremental counter instead of timestamp
          _heartRateData.add(FlSpot(_dataPointCounter.toDouble(), heartRate));
          _dataPointCounter++;

          // Keep only last 50 data points
          if (_heartRateData.length > 50) {
            _heartRateData.removeAt(0);
            // Adjust all x values to maintain continuity
            for (int i = 0; i < _heartRateData.length; i++) {
              _heartRateData[i] = FlSpot(i.toDouble(), _heartRateData[i].y);
            }
            _dataPointCounter = _heartRateData.length;
          }
        });
      }
    });
  }

  Future<void> _loadRecentUsers() async {
    try {
      final users = await FirebaseService.instance.getRecentUsers(limit: 10);
      if (mounted) {
        setState(() {
          _recentUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recent users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentHeartRateCard(),
              const SizedBox(height: 20),
              _buildHeartRateChart(),
              const SizedBox(height: 20),
              _buildRecentUsersSection(),
            ],
          ),
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
            colors: [Colors.red.shade400, Colors.red.shade600],
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
                    MqttService.instance.isConnected
                        ? Icons.wifi
                        : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    MqttService.instance.isConnected
                        ? 'Connected'
                        : 'Disconnected',
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
                                if (_heartRateData.isEmpty)
                                  return const Text('');
                                // Show relative time labels
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _heartRateData.length) {
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
                                Colors.red.shade400,
                                Colors.red.shade600,
                              ],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400.withOpacity(0.3),
                                  Colors.red.shade600.withOpacity(0.1),
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

  Widget _buildRecentUsersSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recentUsers.isEmpty
                ? const Center(
                    child: Text(
                      'No recent users found',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentUsers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = _recentUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade400,
                          child: Text(
                            user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          user['email'] ?? 'No email',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: user['lastUpdated'] != null
                            ? Text(
                                DateFormat(
                                  'MMM dd, HH:mm',
                                ).format(user['lastUpdated'].toDate()),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
