import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';
import '../widgets/widgets.dart';

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
              },
              onClearSelection: () => setState(() => _selectedUser = null),
              onCreateNew: _showCreateUserDialog,
            ),
            const SizedBox(height: 20),
            VideoSelectionCard(
              selectedVideo: _selectedMovie,
              searchResults: _movies,
              searchController: _movieSearchController,
              onSearchChanged: _searchMovies,
              onVideoSelected: (movie) {
                setState(() {
                  _selectedMovie = movie;
                  _movieSearchController.clear();
                  _movies.clear();
                });
              },
              onClearSelection: () => setState(() => _selectedMovie = null),
              onCreateNew: _showCreateMovieDialog,
            ),
            const SizedBox(height: 20),
            HeartRateCard(
              heartRate: _currentHeartRate,
              primaryColor: Colors.red.shade400,
              secondaryColor: Colors.red.shade600,
              statusBadge: RecordingStatusBadge(isRecording: _isRecording),
            ),
            const SizedBox(height: 20),
            HeartRateChart(
              heartRateData: _heartRateData,
              showTimeLabels: true,
              primaryColor: Colors.red.shade400,
            ),
            const SizedBox(height: 20),
            RecordingControls(
              isRecording: _isRecording,
              onToggleRecording: _toggleRecording,
              recordedDataCount: _recordedData.length,
              recordingStartTime: _recordingStartTime,
              startLabel: 'Start Recording',
              stopLabel: 'Stop Recording',
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
