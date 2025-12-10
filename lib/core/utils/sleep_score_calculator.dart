import '../models/sleep_record_model.dart';

class SleepScoreCalculator {
  /// Calculate sleep quality score (0-100) using formula:
  /// ideal = 8 hours
  /// score = max(0, min(100, 100 - (abs(ideal - actual) * 10)))
  static Future<SleepScoreResult> calculateScore(SleepRecordModel record) async {
    final List<String> warnings = [];
    String advice = '';
    String islamicAdvice = '';

    // Calculate score based on duration using the required formula
    final hours = record.durationMinutes / 60.0;
    const idealHours = 8.0;
    final difference = (idealHours - hours).abs();
    int score = (100 - (difference * 10)).round().clamp(0, 100);

    // Generate warnings and advice based on duration
    if (hours < 6) {
      warnings.add('Sleep duration is too short. Aim for 7-9 hours.');
    } else if (hours < 7) {
      warnings.add('Sleep duration is slightly below recommended (7-9 hours)');
    } else if (hours > 9) {
      warnings.add('Sleep duration is slightly above recommended (7-9 hours)');
    }

    // Generate advice based on score
    if (score >= 80) {
      advice = 'Excellent sleep quality! Keep maintaining this routine.';
      islamicAdvice = 'Subh namozi – nurdir. Erta turish – barakadir.';
    } else if (score >= 60) {
      advice = 'Good sleep quality. Try to maintain consistent sleep schedule.';
      islamicAdvice = 'Tong – Allohning eng go\'zal ne\'matidir.';
    } else if (score >= 40) {
      advice = 'Moderate sleep quality. Consider improving your sleep routine.';
      islamicAdvice = 'Erta turuvchi – duo oluvchi.';
    } else {
      advice = 'Sleep quality needs improvement. Focus on getting 7-9 hours of sleep.';
      islamicAdvice = 'Tong – yangi umid. Erta turish – barakadir.';
    }

    // Add Islamic advice if score is low
    if (score < 50) {
      warnings.add('Erta turish – Allohning rahmatidir.');
    }

    return SleepScoreResult(
      score: score,
      warnings: warnings,
      advice: advice,
      islamicAdvice: islamicAdvice,
    );
  }

  /// Placeholder for ChatGPT API call
  /// Replace this with actual API integration if needed
  static Future<SleepScoreResult> calculateScoreWithAI(SleepRecordModel record) async {
    // TODO: Implement ChatGPT API call
    // For now, use local calculation
    return await calculateScore(record);
  }
}

class SleepScoreResult {
  final int score;
  final List<String> warnings;
  final String advice;
  final String islamicAdvice;

  SleepScoreResult({
    required this.score,
    required this.warnings,
    required this.advice,
    required this.islamicAdvice,
  });
}
