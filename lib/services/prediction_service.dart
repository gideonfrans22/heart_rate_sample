import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  static PredictionService get instance => _instance;
  PredictionService._internal();

  // API endpoint - change this when deploying to cloud
  static const String _apiUrl = 'http://localhost:8000/predict';

  /// Calculate features from heart rate data
  Map<String, double> calculateFeatures(List<double> heartRateData) {
    if (heartRateData.isEmpty) {
      return {'mean_hr': 0.0, 'std_hr': 0.0, 'range_hr': 0.0};
    }

    // Calculate mean
    final mean = heartRateData.reduce((a, b) => a + b) / heartRateData.length;

    // Calculate standard deviation
    final variance =
        heartRateData.map((hr) => pow(hr - mean, 2)).reduce((a, b) => a + b) /
        heartRateData.length;
    final std = sqrt(variance);

    // Calculate range (max - min)
    final min = heartRateData.reduce((a, b) => a < b ? a : b);
    final max = heartRateData.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    return {'mean_hr': mean, 'std_hr': std, 'range_hr': range};
  }

  /// Predict emotion using the FastAPI endpoint
  Future<Map<String, dynamic>> predictEmotion({
    required List<double> heartRateData,
    required String mbtiType, // "T" or "F"
  }) async {
    try {
      // Calculate features
      final features = calculateFeatures(heartRateData);

      print('Calculated features:');
      print('  Mean HR: ${features['mean_hr']?.toStringAsFixed(2)}');
      print('  Std HR: ${features['std_hr']?.toStringAsFixed(2)}');
      print('  Range HR: ${features['range_hr']?.toStringAsFixed(2)}');
      print('  MBTI: $mbtiType');

      // Prepare request body
      final requestBody = {
        'mean_hr': features['mean_hr'],
        'std_hr': features['std_hr'],
        'range_hr': features['range_hr'],
        'mbti_tf': mbtiType.toLowerCase(),
      };

      print('Sending request to: $_apiUrl');
      print('Request body: $requestBody');

      // Make API call
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - API server not responding');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;

        // Add calculated features to result
        result['features'] = features;
        result['data_points'] = heartRateData.length;

        return result;
      } else {
        throw Exception(
          'API returned error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Prediction error: $e');
      rethrow;
    }
  }

  /// Update API URL (useful when switching between localhost and cloud)
  static String getApiUrl() => _apiUrl;

  static void setApiUrl(String url) {
    // This would require making _apiUrl non-const
    // For now, users should modify the const directly
    print('To change API URL, modify PredictionService._apiUrl constant');
  }
}
