import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String videosCollection = 'videos';
  static const String heartRateDataCollection = 'heartRateData';
  static const String predictionsCollection = 'predictions';

  // User operations
  Future<List<Map<String, dynamic>>> getRecentUsers({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(usersCollection)
          .orderBy('lastUpdated', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching recent users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(usersCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Future<String> createUser(String name, {String? email, int? age}) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(usersCollection)
          .add({
            'name': name,
            'email': email,
            'age': age,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Video operations
  Future<List<Map<String, dynamic>>> searchVideos(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(videosCollection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  Future<String> createVideo(
    String title, {
    String? description,
    String? url,
  }) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(videosCollection)
          .add({
            'title': title,
            'description': description,
            'url': url,
            'createdAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      print('Error creating video: $e');
      rethrow;
    }
  }

  // Heart rate data operations
  Future<void> saveHeartRateData({
    required String userId,
    required String videoId,
    required List<Map<String, dynamic>> heartRateData,
  }) async {
    try {
      await _firestore.collection(heartRateDataCollection).add({
        'userId': userId,
        'videoId': videoId,
        'heartRateData': heartRateData,
        'startTime': DateTime.now(),
        'endTime': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user's last updated timestamp
      await _firestore.collection(usersCollection).doc(userId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving heart rate data: $e');
      rethrow;
    }
  }

  // Prediction operations
  Future<String> savePrediction({
    required String userId,
    required Map<String, dynamic> predictionResult,
    required Map<String, double> heartRateFeatures,
    required String mbtiType,
    required int dataPoints,
  }) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(predictionsCollection)
          .add({
            'userId': userId,
            'prediction': {
              'class_id': predictionResult['class_id'],
              'class_name': predictionResult['class_name'],
              'prob_angry': predictionResult['prob_angry'],
              'prob_sad': predictionResult['prob_sad'],
              'emoji': predictionResult['emoji'],
              'color_hex': predictionResult['color_hex'],
            },
            'heartRateFeatures': {
              'mean_hr': heartRateFeatures['mean_hr'],
              'std_hr': heartRateFeatures['std_hr'],
              'range_hr': heartRateFeatures['range_hr'],
            },
            'mbtiType': mbtiType,
            'dataPoints': dataPoints,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Update user's last updated timestamp
      await _firestore.collection(usersCollection).doc(userId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error saving prediction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPredictionHistory({
    String? userId,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(predictionsCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      QuerySnapshot snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('Error fetching prediction history: $e');
      return [];
    }
  }
}
