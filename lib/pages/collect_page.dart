import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';

class CollectPage extends StatefulWidget {
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  // Heart rate data
  double _currentHeartRate = 0.0;
  List<FlSpot> _heartRateData = [];
  int _dataPointCounter = 0;
  bool _isRecording = false;
  List<Map<String, dynamic>> _recordedData = [];

  // User selection
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _users = [];
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _newUserNameController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  final TextEditingController _newUserAgeController = TextEditingController();

  // Movie selection
  Map<String, dynamic>? _selectedMovie;
  List<Map<String, dynamic>> _movies = [];
  final TextEditingController _movieSearchController = TextEditingController();
  final TextEditingController _newMovieTitleController =
      TextEditingController();
  final TextEditingController _newMovieDescriptionController =
      TextEditingController();
  final TextEditingController _newMovieUrlController = TextEditingController();

  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _setupHeartRateListener();
  }

  void _setupHeartRateListener() {
    MqttService.instance.heartRateStream.listen((heartRate) {
      if (mounted) {
        setState(() {
          _currentHeartRate = heartRate;

          // Add to chart data using incremental counter instead of timestamp
          _heartRateData.add(FlSpot(_dataPointCounter.toDouble(), heartRate));
          _dataPointCounter++;

          // If recording, add to recorded data
          if (_isRecording) {
            _recordedData.add({
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'heartRate': heartRate,
            });
          }

          // Keep only last 50 data points for chart
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

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() => _movies = []);
      return;
    }

    try {
      final movies = await FirebaseService.instance.searchVideos(query);
      setState(() => _movies = movies);
    } catch (e) {
      print('Error searching movies: $e');
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

  Future<void> _createNewMovie() async {
    if (_newMovieTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a movie title')),
      );
      return;
    }

    try {
      final movieId = await FirebaseService.instance.createVideo(
        _newMovieTitleController.text,
        description: _newMovieDescriptionController.text.isEmpty
            ? null
            : _newMovieDescriptionController.text,
        url: _newMovieUrlController.text.isEmpty
            ? null
            : _newMovieUrlController.text,
      );

      setState(() {
        _selectedMovie = {
          'id': movieId,
          'title': _newMovieTitleController.text,
          'description': _newMovieDescriptionController.text,
          'url': _newMovieUrlController.text,
        };
      });

      _newMovieTitleController.clear();
      _newMovieDescriptionController.clear();
      _newMovieUrlController.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movie created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating movie: $e')));
    }
  }

  void _toggleRecording() async {
    if (!_isRecording) {
      // Start recording
      if (_selectedUser == null || _selectedMovie == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both user and movie')),
        );
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordedData.clear();
      });
    } else {
      // Stop recording and save data
      setState(() => _isRecording = false);

      if (_recordedData.isNotEmpty) {
        try {
          await FirebaseService.instance.saveHeartRateData(
            userId: _selectedUser!['id'],
            videoId: _selectedMovie!['id'],
            heartRateData: _recordedData,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Heart rate data saved successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Heart Rate'),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserSelection(),
            const SizedBox(height: 20),
            _buildMovieSelection(),
            const SizedBox(height: 20),
            _buildCurrentHeartRateCard(),
            const SizedBox(height: 20),
            _buildHeartRateChart(),
            const SizedBox(height: 20),
            _buildRecordingControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedUser != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade400,
                      child: Text(
                        _selectedUser!['name']?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedUser!['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_selectedUser!['email'] != null)
                            Text(_selectedUser!['email']),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedUser = null),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _userSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search Users',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _searchUsers,
              ),
              const SizedBox(height: 8),
              if (_users.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade400,
                          child: Text(
                            user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text(user['email'] ?? 'No email'),
                        onTap: () {
                          setState(() {
                            _selectedUser = user;
                            _userSearchController.clear();
                            _users.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showCreateUserDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create New User'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMovieSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Movie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedMovie != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade400,
                      child: const Icon(Icons.movie, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMovie!['title'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_selectedMovie!['description'] != null)
                            Text(_selectedMovie!['description']),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedMovie = null),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _movieSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search Movies',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _searchMovies,
              ),
              const SizedBox(height: 8),
              if (_movies.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _movies.length,
                    itemBuilder: (context, index) {
                      final movie = _movies[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade400,
                          child: const Icon(Icons.movie, color: Colors.white),
                        ),
                        title: Text(movie['title'] ?? 'Unknown'),
                        subtitle: Text(
                          movie['description'] ?? 'No description',
                        ),
                        onTap: () {
                          setState(() {
                            _selectedMovie = movie;
                            _movieSearchController.clear();
                            _movies.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showCreateMovieDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create New Movie'),
              ),
            ],
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
                    _isRecording ? Icons.fiber_manual_record : Icons.stop,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isRecording ? 'Recording' : 'Stopped',
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
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                minimumSize: const Size(200, 48),
              ),
            ),
            if (_recordedData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Recorded ${_recordedData.length} data points',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
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

  void _showCreateMovieDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Movie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newMovieTitleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newMovieDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newMovieUrlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createNewMovie,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
