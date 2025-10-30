import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';
import '../widgets/widgets.dart';

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
              HeartRateCard(
                heartRate: _currentHeartRate,
                primaryColor: Colors.red.shade400,
                secondaryColor: Colors.red.shade600,
                statusBadge: ConnectionStatusBadge(
                  isConnected: MqttService.instance.isConnected,
                ),
              ),
              const SizedBox(height: 20),
              HeartRateChart(
                heartRateData: _heartRateData,
                primaryColor: Colors.red.shade400,
                secondaryColor: Colors.red.shade600,
              ),
              const SizedBox(height: 20),
              RecentUsersCard(
                users: _recentUsers,
                isLoading: _isLoading,
                accentColor: Colors.red.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
