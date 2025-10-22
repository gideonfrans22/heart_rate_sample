import 'dart:math';

class MLService {
  static final MLService _instance = MLService._internal();
  static MLService get instance => _instance;
  MLService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Dummy initialization - no actual model loading
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
    print('ML Service initialized (dummy mode)');
  }

  /// Predict MBTI type (T or F) based on heart rate data
  /// Returns: 'T' for Thinking, 'F' for Feeling
  /// This is a DUMMY implementation for demonstration purposes
  Future<Map<String, dynamic>> predictMBTI(List<double> heartRateData) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Add some delay to simulate model processing
    await Future.delayed(const Duration(milliseconds: 500));

    // Use dummy prediction based on heart rate features
    return _dummyPrediction(heartRateData);
  }

  /// Dummy prediction function
  /// Uses simple heuristics to simulate a trained model
  Map<String, dynamic> _dummyPrediction(List<double> heartRateData) {
    if (heartRateData.isEmpty) {
      return {
        'prediction': 'T',
        'confidence': 0.5,
        'details': {'thinking_score': 0.5, 'feeling_score': 0.5},
      };
    }

    // Calculate basic statistics
    final mean = heartRateData.reduce((a, b) => a + b) / heartRateData.length;

    // Calculate Heart Rate Variability (HRV)
    double hrv = 0.0;
    for (int i = 1; i < heartRateData.length; i++) {
      hrv += (heartRateData[i] - heartRateData[i - 1]).abs();
    }
    hrv = hrv / (heartRateData.length - 1);

    // Calculate variance
    final variance =
        heartRateData
            .map((hr) => (hr - mean) * (hr - mean))
            .reduce((a, b) => a + b) /
        heartRateData.length;

    final stdDev = sqrt(variance);

    // Dummy heuristic:
    // Higher HRV and variability = More emotional responsiveness = Feeling (F)
    // Lower HRV and more stable = More controlled response = Thinking (T)

    // Normalize features (scale to 0-1 range)
    final normalizedHRV = min(hrv / 10.0, 1.0);
    final normalizedStdDev = min(stdDev / 20.0, 1.0);
    final normalizedMean = mean / 100.0;

    // Calculate feeling score (weighted combination)
    double feelingScore =
        (normalizedHRV * 0.4) +
        (normalizedStdDev * 0.4) +
        (normalizedMean * 0.2);

    // Add some randomness to make it more realistic (±10%)
    final random = Random();
    feelingScore += (random.nextDouble() - 0.5) * 0.2;

    // Clamp between 0 and 1
    feelingScore = max(0.0, min(1.0, feelingScore));

    final thinkingScore = 1.0 - feelingScore;

    // Determine prediction
    final prediction = feelingScore > 0.5 ? 'F' : 'T';
    final confidence = feelingScore > 0.5 ? feelingScore : thinkingScore;

    // Add some detail for transparency
    print('Dummy Prediction Details:');
    print('  Mean HR: ${mean.toStringAsFixed(2)}');
    print('  HRV: ${hrv.toStringAsFixed(2)}');
    print('  Std Dev: ${stdDev.toStringAsFixed(2)}');
    print('  Feeling Score: ${(feelingScore * 100).toStringAsFixed(1)}%');
    print('  Thinking Score: ${(thinkingScore * 100).toStringAsFixed(1)}%');
    print(
      '  Prediction: $prediction (${(confidence * 100).toStringAsFixed(1)}% confidence)',
    );

    return {
      'prediction': prediction,
      'confidence': confidence,
      'details': {
        'thinking_score': thinkingScore,
        'feeling_score': feelingScore,
      },
    };
  }

  void dispose() {
    _isInitialized = false;
  }
}
