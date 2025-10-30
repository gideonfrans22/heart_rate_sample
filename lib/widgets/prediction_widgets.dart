import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Instruction card showing how to use the prediction feature
class InstructionCard extends StatelessWidget {
  final Color accentColor;
  final List<String> instructions;

  const InstructionCard({
    super.key,
    this.accentColor = Colors.purple,
    this.instructions = const [
      '1. Select your MBTI type (T or F)',
      '2. Watch an emotion-evoking video',
      '3. Start recording your heart rate',
      '4. Record for at least 30 seconds',
      '5. Stop to see your emotion prediction',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: accentColor),
                const SizedBox(width: 8),
                const Text(
                  'How it works',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              instructions.join('\n'),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// MBTI type selector (Thinking vs Feeling)
class MBTISelector extends StatelessWidget {
  final String selectedMBTI;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const MBTISelector({
    super.key,
    required this.selectedMBTI,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your MBTI Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Thinking (T)'),
                    subtitle: const Text('Logic-based decisions'),
                    value: 'T',
                    groupValue: selectedMBTI,
                    onChanged: enabled ? (value) => onChanged(value!) : null,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Feeling (F)'),
                    subtitle: const Text('Value-based decisions'),
                    value: 'F',
                    groupValue: selectedMBTI,
                    onChanged: enabled ? (value) => onChanged(value!) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading indicator for prediction
class PredictingIndicator extends StatelessWidget {
  final String message;

  const PredictingIndicator({
    super.key,
    this.message = 'Predicting emotion...',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error message card
class ErrorMessageCard extends StatelessWidget {
  final String message;

  const ErrorMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prediction result display card
class PredictionResultCard extends StatelessWidget {
  final Map<String, dynamic> predictionResult;
  final String selectedMBTI;

  const PredictionResultCard({
    super.key,
    required this.predictionResult,
    required this.selectedMBTI,
  });

  @override
  Widget build(BuildContext context) {
    final emotion = predictionResult['class_name'] as String;
    final emoji = predictionResult['emoji'] as String;
    final colorHex = predictionResult['color_hex'] as String;
    final probAngry = predictionResult['prob_angry'] as double;
    final probSad = predictionResult['prob_sad'] as double;
    final features = predictionResult['features'] as Map<String, double>;

    final color = Color(
      int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000,
    );

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Your Emotion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emotion.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
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
                  ProbabilityBar(
                    label: '😠 Angry',
                    probability: probAngry,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  ProbabilityBar(
                    label: '😢 Sad',
                    probability: probSad,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Heart Rate Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mean: ${features['mean_hr']!.toStringAsFixed(1)} bpm',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Std Dev: ${features['std_hr']!.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Range: ${features['range_hr']!.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'MBTI: $selectedMBTI',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Probability bar widget
class ProbabilityBar extends StatelessWidget {
  final String label;
  final double probability;
  final Color color;

  const ProbabilityBar({
    super.key,
    required this.label,
    required this.probability,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              '${(probability * 100).toStringAsFixed(1)}%',
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
            value: probability,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Prediction history list
class PredictionHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> historyItems;
  final bool isLoading;
  final VoidCallback onRefresh;

  const PredictionHistoryCard({
    super.key,
    required this.historyItems,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prediction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (historyItems.isEmpty)
              const Center(
                child: Text(
                  'No prediction history yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  final prediction = item['prediction'] as Map<String, dynamic>;
                  final features =
                      item['heartRateFeatures'] as Map<String, dynamic>;
                  final timestamp = item['createdAt'] as Timestamp?;
                  final className = prediction['class_name'] as String;
                  final probAngry = prediction['prob_angry'] as double;
                  final probSad = prediction['prob_sad'] as double;

                  return ListTile(
                    leading: Text(
                      prediction['emoji'] ?? '😊',
                      style: const TextStyle(fontSize: 30),
                    ),
                    title: Text(
                      '${className ?? 'Unknown'} (${((className == "sad"
                              ? probSad
                              : className == "angry"
                              ? probAngry
                              : 0) * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MBTI: ${item['mbtiType']} • HR: ${features['mean_hr'].toStringAsFixed(1)} bpm (±${features['std_hr'].toStringAsFixed(1)})',
                        ),
                        if (timestamp != null)
                          Text(
                            DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(timestamp.toDate()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
