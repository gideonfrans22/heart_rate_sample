import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hear_rate_sample_collector/pages/collect_page.dart';
import 'package:hear_rate_sample_collector/pages/predict_page.dart';
import 'services/mqtt_service.dart';
import 'services/ml_service.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize MQTT service
  await MqttService.instance.initialize();

  // Initialize ML service
  // await MLService.instance.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Rate Collector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [HomePage(), CollectPage(), PredictPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fiber_manual_record),
            label: 'Collect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Predict',
          ),
        ],
      ),
    );
  }
}
