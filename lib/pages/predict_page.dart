import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mqtt_service.dart';
import '../services/prediction_service.dart';
import '../services/firebase_service.dart';
import '../widgets/widgets.dart';

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

  // MBTI selection
  String _selectedMBTI = 'T';

  // User selection for saving to Firebase
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _users = [];
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _newUserNameController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  final TextEditingController _newUserAgeController = TextEditingController();

  // Prediction results
  Map<String, dynamic>? _predictionResult;
  bool _isPredicting = false;
  bool _showResults = false;
  String? _errorMessage;

  // Prediction history
  List<Map<String, dynamic>> _predictionHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _setupHeartRateListener();
    _loadPredictionHistory();
  }

  void _setupHeartRateListener() {
    MqttService.instance.heartRateStream.listen((heartRate) {
      if (mounted) {
        // Check recording state before setState to ensure we capture it
        final bool isCurrentlyRecording = _isRecording;

        setState(() {
          _currentHeartRate = heartRate;

          // Add to chart data
          _heartRateData.add(FlSpot(_dataPointCounter.toDouble(), heartRate));
          _dataPointCounter++;

          // Keep only last 50 data points for chart
          if (_heartRateData.length > 50) {
            _heartRateData.removeAt(0);
            for (int i = 0; i < _heartRateData.length; i++) {
              _heartRateData[i] = FlSpot(i.toDouble(), _heartRateData[i].y);
            }
            _dataPointCounter = _heartRateData.length;
          }
        });

        // Add to raw data outside setState to avoid any timing issues
        if (isCurrentlyRecording) {
          _rawHeartRateData.add(heartRate);
        }
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _users = []);
      return;
    }

    try {
      final users = await FirebaseService.instance.searchUsers(query);
      setState(() => _users = users);
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  Future<void> _createNewUser() async {
    if (_newUserNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    try {
      final userId = await FirebaseService.instance.createUser(
        _newUserNameController.text,
        email: _newUserEmailController.text.isEmpty
            ? null
            : _newUserEmailController.text,
        age: _newUserAgeController.text.isEmpty
            ? null
            : int.tryParse(_newUserAgeController.text),
      );

      setState(() {
        _selectedUser = {
          'id': userId,
          'name': _newUserNameController.text,
          'email': _newUserEmailController.text,
          'age': int.tryParse(_newUserAgeController.text),
        };
      });

      _newUserNameController.clear();
      _newUserEmailController.clear();
      _newUserAgeController.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating user: $e')));
    }
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newUserNameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newUserEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newUserAgeController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createNewUser,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPredictionHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await FirebaseService.instance.getPredictionHistory(
        userId: _selectedUser?['id'],
        limit: 10,
      );
      setState(() {
        _predictionHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoadingHistory = false);
    }
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
        _errorMessage = null;
      });
    } else {
      // Stop recording and predict
      setState(() {
        _isRecording = false;
        _isPredicting = true;
        _errorMessage = null;
      });

      if (_rawHeartRateData.length >= 10) {
        try {
          // Make prediction
          final result = await PredictionService.instance.predictEmotion(
            heartRateData: _rawHeartRateData,
            mbtiType: _selectedMBTI,
          );

          setState(() {
            _predictionResult = result;
            _isPredicting = false;
            _showResults = true;
          });

          // Save to Firebase if user is selected
          if (_selectedUser != null) {
            await _savePredictionToFirebase(result);
          }
        } catch (e) {
          setState(() {
            _isPredicting = false;
            _errorMessage = 'Prediction failed: ${e.toString()}';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        setState(() {
          _isPredicting = false;
          _errorMessage = 'Not enough data. Record for at least 10 seconds.';
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
    }
  }

  Future<void> _savePredictionToFirebase(Map<String, dynamic> result) async {
    try {
      await FirebaseService.instance.savePrediction(
        userId: _selectedUser!['id'],
        predictionResult: result,
        heartRateFeatures: result['features'] as Map<String, double>,
        mbtiType: _selectedMBTI,
        dataPoints: result['data_points'],
      );

      await _loadPredictionHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prediction saved to history!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving to Firebase: $e');
    }
  }

  void _resetPrediction() {
    setState(() {
      _rawHeartRateData.clear();
      _predictionResult = null;
      _showResults = false;
      _recordingStartTime = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Prediction'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InstructionCard(
              instructions: [
                'Select your MBTI personality type (T or F)',
                'Choose a user to save prediction results',
                'Start recording your heart rate',
                'The system will predict your emotional state',
              ],
            ),
            const SizedBox(height: 20),
            MBTISelector(
              selectedMBTI: _selectedMBTI,
              onChanged: (value) => setState(() => _selectedMBTI = value),
            ),
            const SizedBox(height: 20),
            UserSelectionCard(
              selectedUser: _selectedUser,
              searchResults: _users,
              searchController: _userSearchController,
              onSearchChanged: _searchUsers,
              onUserSelected: (user) {
                setState(() {
                  _selectedUser = user;
                  _userSearchController.clear();
                  _users.clear();
                });
                _loadPredictionHistory();
              },
              onClearSelection: () => setState(() => _selectedUser = null),
              onCreateNew: _showCreateUserDialog,
            ),
            const SizedBox(height: 20),
            HeartRateCard(
              heartRate: _currentHeartRate,
              primaryColor: Colors.purple.shade400,
              secondaryColor: Colors.purple.shade600,
              statusBadge: RecordingStatusBadge(
                isRecording: _isRecording,
                dataPointCount: _rawHeartRateData.length,
              ),
            ),
            const SizedBox(height: 20),
            HeartRateChart(
              heartRateData: _heartRateData,
              showTimeLabels: true,
              primaryColor: Colors.purple.shade400,
            ),
            const SizedBox(height: 20),
            RecordingControls(
              isRecording: _isRecording,
              onToggleRecording: _toggleRecording,
              recordedDataCount: _rawHeartRateData.length,
              recordingStartTime: _recordingStartTime,
              isPredicting: _isPredicting,
              showResults: _showResults,
              onReset: _resetPrediction,
              startLabel: 'Start Recording',
              stopLabel: 'Predict Emotion',
            ),
            if (_isPredicting) ...[
              const SizedBox(height: 20),
              const PredictingIndicator(),
            ],
            if (_showResults && _predictionResult != null) ...[
              const SizedBox(height: 20),
              PredictionResultCard(
                predictionResult: _predictionResult!,
                selectedMBTI: _selectedMBTI,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              ErrorMessageCard(message: _errorMessage!),
            ],
            const SizedBox(height: 20),
            PredictionHistoryCard(
              historyItems: _predictionHistory,
              isLoading: _isLoadingHistory,
              onRefresh: _loadPredictionHistory,
            ),
          ],
        ),
      ),
    );
  }
}
