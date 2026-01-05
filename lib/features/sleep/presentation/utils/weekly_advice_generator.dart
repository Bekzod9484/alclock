import '../../../../core/models/sleep_record_model.dart';

/// Weekly sleep analysis report
class WeeklySleepReport {
  final String summaryTitle;
  final String summaryText;
  final List<String> problems;
  final List<String> recommendations;
  final int overallScore;

  WeeklySleepReport({
    required this.summaryTitle,
    required this.summaryText,
    required this.problems,
    required this.recommendations,
    required this.overallScore,
  });

  /// Convert report to formatted text
  String toFormattedText() {
    final buffer = StringBuffer();
    
    buffer.writeln(summaryTitle);
    buffer.writeln();
    buffer.writeln(summaryText);
    buffer.writeln();
    
    if (problems.isNotEmpty) {
      buffer.writeln('**Muammolar:**');
      buffer.writeln();
      for (var problem in problems) {
        buffer.writeln('• $problem');
      }
      buffer.writeln();
    }
    
    if (recommendations.isNotEmpty) {
      buffer.writeln('**Tavsiyalar:**');
      buffer.writeln();
      for (var rec in recommendations) {
        buffer.writeln('• $rec');
      }
    }
    
    return buffer.toString();
  }
}

/// New weekly sleep advice system with exact rules
class WeeklyAdviceGenerator {
  /// Build weekly sleep advice based on exact rules
  static String buildWeeklyAdvice(List<SleepRecordModel> weekRecords) {
    // Filter valid records
    final validRecords = weekRecords.where((r) =>
        r.sleepStart != null &&
        r.wakeTime != null &&
        r.durationMinutes > 0).toList();

    if (validRecords.isEmpty) {
      return "Ma'lumot yetarli emas. Bu hafta uyqu ma'lumotlari yetarli emas. "
          "Uyqu tartibini kuzatish uchun ma'lumotlarni kiriting.";
    }

    // Calculate metrics
    final avgDuration = _calculateAvgDuration(validRecords);
    final avgSleepStart = _calculateAvgSleepStart(validRecords);
    final lateNights = _countLateNights(validRecords);
    final shortNights = _countShortNights(validRecords);
    final goodNights = _countGoodNights(validRecords);

    // STEP 1: Weekly Summary Category
    final summary = _generateWeeklySummary(goodNights, shortNights, lateNights);

    // STEP 2: Weekly Problems List
    final problems = _generateProblems(lateNights, shortNights, avgDuration, avgSleepStart);

    // STEP 3: Weekly Recommendations
    final recommendations = _generateRecommendations();

    // Build final advice
    final buffer = StringBuffer();
    buffer.writeln(summary);
    buffer.writeln();
    
    if (problems.isNotEmpty) {
      buffer.writeln('**Muammolar:**');
      buffer.writeln();
      for (var problem in problems) {
        buffer.writeln('• $problem');
      }
      buffer.writeln();
    }
    
    if (recommendations.isNotEmpty) {
      buffer.writeln('**Tavsiyalar:**');
      buffer.writeln();
      for (var rec in recommendations) {
        buffer.writeln('• $rec');
      }
    }

    return buffer.toString();
  }

  /// Calculate average duration in hours
  static double _calculateAvgDuration(List<SleepRecordModel> records) {
    if (records.isEmpty) return 0.0;
    final totalMinutes = records.map((r) => r.durationMinutes).reduce((a, b) => a + b);
    return totalMinutes / records.length / 60.0;
  }

  /// Calculate average sleep start time (returns formatted string)
  static String _calculateAvgSleepStart(List<SleepRecordModel> records) {
    if (records.isEmpty) return "00:00";
    
    final sleepTimes = <int>[];
    for (var record in records) {
      final sleepStart = record.sleepStart!;
      int minutes = sleepStart.hour * 60 + sleepStart.minute;
      // If sleep is after midnight but before 6 AM, treat as next day (add 24h)
      if (sleepStart.hour >= 0 && sleepStart.hour < 6) {
        minutes += 1440;
      }
      sleepTimes.add(minutes);
    }
    
    final avgMinutes = (sleepTimes.reduce((a, b) => a + b) / sleepTimes.length).round();
    final normalizedMinutes = avgMinutes % 1440;
    final hour = normalizedMinutes ~/ 60;
    final minute = normalizedMinutes % 60;
    
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }


  /// Count late nights (sleepStart > 00:30)
  static int _countLateNights(List<SleepRecordModel> records) {
    int count = 0;
    for (var record in records) {
      final sleepStart = record.sleepStart!;
      final hour = sleepStart.hour;
      final minute = sleepStart.minute;
      
      // After 00:30
      if (hour > 0 || (hour == 0 && minute > 30)) {
        count++;
      }
    }
    return count;
  }

  /// Count short nights (duration < 6h)
  static int _countShortNights(List<SleepRecordModel> records) {
    int count = 0;
    for (var record in records) {
      final durationHours = record.durationMinutes / 60.0;
      if (durationHours < 6) {
        count++;
      }
    }
    return count;
  }

  /// Count good nights (duration == ideal AND sleepTime in ["early","normal"])
  static int _countGoodNights(List<SleepRecordModel> records) {
    int count = 0;
    for (var record in records) {
      final durationHours = record.durationMinutes / 60.0;
      final sleepStart = record.sleepStart!;
      
      // Check duration is ideal (7-9h)
      final isIdealDuration = durationHours >= 7 && durationHours <= 9;
      
      // Check sleep time is early or normal
      final hour = sleepStart.hour;
      final minute = sleepStart.minute;
      int sleepMinutes;
      if (hour >= 22) {
        sleepMinutes = hour * 60 + minute;
      } else if (hour < 3) {
        sleepMinutes = (hour * 60 + minute) + 1440;
      } else {
        sleepMinutes = hour * 60 + minute;
      }
      
      final earlyEnd = 22 * 60; // 22:00
      final normalStart = 23 * 60 + 30; // 23:30
      final normalEnd = 24 * 60 + 30; // 00:30
      
      final isEarlyOrNormal = (sleepMinutes >= earlyEnd && sleepMinutes < normalStart) ||
          (sleepMinutes >= normalStart && sleepMinutes < normalEnd);
      
      if (isIdealDuration && isEarlyOrNormal) {
        count++;
      }
    }
    return count;
  }

  /// STEP 1: Generate weekly summary
  static String _generateWeeklySummary(int goodNights, int shortNights, int lateNights) {
    // A) Excellent week
    if (goodNights >= 4 && shortNights <= 1 && lateNights <= 1) {
      return "Uyqu tartibi juda yaxshi. Ko'p kunlarda sifatli va vaqtida uxlabsiz.";
    }

    // C) Poor week
    if (shortNights >= 3 || lateNights >= 3) {
      return "⚠️ Uyqu tartibi izdan chiqqan. Bu kayfiyat va sog'liqqa ta'sir qilishi mumkin.";
    }

    // B) Mixed week
    return "Uyqu tartibi yomon emas, lekin yaxshilash mumkin. "
        "Ba'zi kunlar yaxshi, ba'zilari esa tartibdan chiqqan.";
  }

  /// STEP 2: Generate problems list
  static List<String> _generateProblems(
      int lateNights, int shortNights, double avgDuration, String avgSleepStart) {
    final problems = <String>[];

    if (lateNights >= 2) {
      problems.add("Juda kech uxlagan tunlar: $lateNights ta.");
    }

    if (shortNights >= 2) {
      problems.add("Yetarli uxlamagan tunlar: $shortNights ta.");
    }

    if (avgDuration < 7) {
      final hours = avgDuration.toStringAsFixed(1);
      problems.add("O'rtacha davomiylik ideal (7–9 soat) dan past: $hours soat.");
    }

    // Check if avgSleepStart is after 00:30
    final sleepStartParts = avgSleepStart.split(':');
    if (sleepStartParts.length == 2) {
      final hour = int.tryParse(sleepStartParts[0]) ?? 0;
      final minute = int.tryParse(sleepStartParts[1]) ?? 0;
      if (hour > 0 || (hour == 0 && minute > 30)) {
        problems.add("O'rtacha yotish vaqti juda kech: $avgSleepStart.");
      }
    }

    return problems;
  }

  /// STEP 3: Generate recommendations (always 2-3 items)
  static List<String> _generateRecommendations() {
    final allRecommendations = [
      "Har kuni bir xil vaqtda uxlash va uyg'onishga harakat qiling.",
      "Uxlashdan 1 soat oldin ekranlardan uzoqlashing.",
      "Og'ir ovqatni yotishdan 3 soat oldin tugating.",
      "Ertalab quyosh nuri va yengil harakat bilan kunni boshlash energiyani oshiradi.",
    ];

    // Return 2-3 random recommendations
    final shuffled = List<String>.from(allRecommendations)..shuffle();
    return shuffled.take(3).toList();
  }

  /// Legacy method for backward compatibility
  static WeeklySleepReport generateWeeklyReport(List<SleepRecordModel> weekRecords) {
    final validRecords = weekRecords.where((r) =>
        r.sleepStart != null &&
        r.wakeTime != null &&
        r.durationMinutes > 0).toList();

    if (validRecords.isEmpty) {
      return WeeklySleepReport(
        summaryTitle: "Ma'lumot yetarli emas",
        summaryText: "Bu hafta uyqu ma'lumotlari yetarli emas. Uyqu tartibini kuzatish uchun ma'lumotlarni kiriting.",
        problems: [],
        recommendations: [
          "Har kuni uyqu vaqtini kiritishni odat qiling.",
          "Avtomatik uyqu kuzatuvchi rejimini yoqing.",
        ],
        overallScore: 0,
      );
    }

    final avgDuration = _calculateAvgDuration(validRecords);
    final avgSleepStart = _calculateAvgSleepStart(validRecords);
    final lateNights = _countLateNights(validRecords);
    final shortNights = _countShortNights(validRecords);
    final goodNights = _countGoodNights(validRecords);

    final summary = _generateWeeklySummary(goodNights, shortNights, lateNights);
    final problems = _generateProblems(lateNights, shortNights, avgDuration, avgSleepStart);
    final recommendations = _generateRecommendations();

    // Calculate score (0-100)
    int score = 100;
    score -= lateNights * 10;
    score -= shortNights * 15;
    if (avgDuration < 7) score -= 10;
    score = score.clamp(0, 100);

    return WeeklySleepReport(
      summaryTitle: goodNights >= 4 ? "Uyqu tartibi a'lo" : "Uyqu tartibi yaxshilanishi mumkin",
      summaryText: summary,
      problems: problems,
      recommendations: recommendations,
      overallScore: score,
    );
  }

  /// Legacy method for backward compatibility
  static String generateWeeklyAdvice(List<SleepRecordModel> weekRecords) {
    return buildWeeklyAdvice(weekRecords);
  }
}
