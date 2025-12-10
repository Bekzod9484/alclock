import 'dart:math' show Random, sqrt;
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

/// Generates comprehensive weekly sleep analysis and advice
class WeeklyAdviceGenerator {
  // Thresholds
  static const int lateSleepThreshold = 0; // After 00:00
  static const int veryLateSleepThreshold = 2; // After 02:00
  static const int earlyWakeThreshold = 6; // Before 06:00
  static const int lateWakeThreshold = 9; // After 09:30 (9.5 hours = 9:30)
  static const double insufficientSleepHours = 6.0;
  static const double goodSleepMinHours = 7.0;
  static const double goodSleepMaxHours = 9.0;
  static const double oversleepHours = 10.0;
  static const int lateWakeMinutes = 9 * 60 + 30; // 09:30 in minutes

  /// Generate full weekly analysis report
  static WeeklySleepReport generateWeeklyReport(List<SleepRecordModel> weekRecords) {
    // Filter valid records
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

    // Analyze patterns
    final analysis = _analyzeWeeklyPatterns(validRecords);
    
    // Generate report
    return _generateReport(analysis, validRecords.length);
  }

  /// Legacy method for backward compatibility
  static String generateWeeklyAdvice(List<SleepRecordModel> weekRecords) {
    final report = generateWeeklyReport(weekRecords);
    return report.toFormattedText();
  }

  /// Analyze weekly sleep patterns
  static _WeeklyAnalysis _analyzeWeeklyPatterns(List<SleepRecordModel> records) {
    final random = Random();
    
    // Calculate averages
    final avgDuration = records.map((r) => r.durationMinutes).reduce((a, b) => a + b) / records.length;
    final avgDurationHours = avgDuration / 60.0;

    // Calculate sleep start times (handle midnight crossing)
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
    final avgSleepMinutes = (sleepTimes.reduce((a, b) => a + b) / sleepTimes.length).round();
    final avgSleepHour = (avgSleepMinutes % 1440) ~/ 60;
    final avgSleepMinute = (avgSleepMinutes % 1440) % 60;

    // Calculate wake times
    final wakeTimes = records.map((r) {
      final wake = r.wakeTime!;
      return wake.hour * 60 + wake.minute;
    }).toList();
    final avgWakeMinutes = (wakeTimes.reduce((a, b) => a + b) / wakeTimes.length).round();
    final avgWakeHour = avgWakeMinutes ~/ 60;
    final avgWakeMinute = avgWakeMinutes % 60;

    // Detect patterns
    int lateSleepDays = 0; // After 00:00
    int veryLateSleepDays = 0; // After 02:00
    int earlyWakeDays = 0; // Before 06:00
    int lateWakeDays = 0; // After 09:30
    int shortSleepDays = 0; // < 6h
    int oversleepDays = 0; // > 10h

    for (var record in records) {
      final durationHours = record.durationMinutes / 60.0;
      if (durationHours < insufficientSleepHours) shortSleepDays++;
      if (durationHours > oversleepHours) oversleepDays++;

      final sleepHour = record.sleepStart!.hour;
      if (sleepHour >= veryLateSleepThreshold) veryLateSleepDays++;
      if (sleepHour >= lateSleepThreshold && sleepHour < 6) lateSleepDays++;

      final wakeMinutes = record.wakeTime!.hour * 60 + record.wakeTime!.minute;
      if (wakeMinutes < earlyWakeThreshold * 60) earlyWakeDays++;
      if (wakeMinutes > lateWakeMinutes) lateWakeDays++;
    }

    // Calculate consistency (variance in sleep times and wake times)
    final sleepTimeVariance = _calculateVariance(sleepTimes.map((m) => m.toDouble()).toList());
    final wakeTimeVariance = _calculateVariance(wakeTimes.map((m) => m.toDouble()).toList());
    final durationVariance = _calculateVariance(records.map((r) => r.durationMinutes.toDouble()).toList());

    // Calculate consistency score (lower variance = more consistent)
    final sleepTimeStdDev = sqrt(sleepTimeVariance);
    final wakeTimeStdDev = sqrt(wakeTimeVariance);
    final durationStdDev = sqrt(durationVariance);

    return _WeeklyAnalysis(
      avgDurationHours: avgDurationHours,
      avgSleepHour: avgSleepHour,
      avgSleepMinute: avgSleepMinute,
      avgWakeHour: avgWakeHour,
      avgWakeMinute: avgWakeMinute,
      lateSleepDays: lateSleepDays,
      veryLateSleepDays: veryLateSleepDays,
      earlyWakeDays: earlyWakeDays,
      lateWakeDays: lateWakeDays,
      shortSleepDays: shortSleepDays,
      oversleepDays: oversleepDays,
      sleepTimeStdDev: sleepTimeStdDev,
      wakeTimeStdDev: wakeTimeStdDev,
      durationStdDev: durationStdDev,
      totalDays: records.length,
      random: random,
    );
  }

  /// Calculate variance
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Generate report from analysis
  static WeeklySleepReport _generateReport(_WeeklyAnalysis analysis, int totalDays) {
    final problems = <String>[];
    final recommendations = <String>[];

    // Detect problems
    if (analysis.veryLateSleepDays > 0) {
      problems.addAll(_getVeryLateSleepProblems(analysis));
    }
    
    if (analysis.lateSleepDays > 0 && analysis.veryLateSleepDays == 0) {
      problems.addAll(_getLateSleepProblems(analysis));
    }

    if (analysis.shortSleepDays > 0) {
      problems.addAll(_getShortSleepProblems(analysis));
    }

    if (analysis.oversleepDays > 0) {
      problems.addAll(_getOversleepProblems(analysis));
    }

    if (analysis.lateWakeDays > 0) {
      problems.addAll(_getLateWakeProblems(analysis));
    }

    if (analysis.sleepTimeStdDev > 90 || analysis.wakeTimeStdDev > 90) {
      problems.addAll(_getInconsistencyProblems(analysis));
    }

    // Generate recommendations based on problems
    if (analysis.veryLateSleepDays > 0 || analysis.lateSleepDays > 0) {
      recommendations.addAll(_getBedtimeRecommendations(analysis));
    }

    if (analysis.shortSleepDays > 0) {
      recommendations.addAll(_getDurationRecommendations(analysis));
    }

    if (analysis.lateWakeDays > 0) {
      recommendations.addAll(_getWakeTimeRecommendations(analysis));
    }

    if (analysis.sleepTimeStdDev > 90 || analysis.wakeTimeStdDev > 90) {
      recommendations.addAll(_getConsistencyRecommendations(analysis));
    }

    // If no specific problems, give general positive feedback
    if (problems.isEmpty) {
      problems.addAll(_getPositiveFeedback(analysis));
    }

    if (recommendations.isEmpty) {
      recommendations.addAll(_getMaintenanceRecommendations(analysis));
    }

    // Limit problems and recommendations
    final finalProblems = problems.take(5).toList();
    final finalRecommendations = recommendations.take(5).toList();

    // Generate summary
    final summary = _generateSummary(analysis, finalProblems.isEmpty);
    final title = _generateTitle(analysis, finalProblems.isEmpty);

    // Calculate score
    final score = _calculateScore(analysis);

    return WeeklySleepReport(
      summaryTitle: title,
      summaryText: summary,
      problems: finalProblems,
      recommendations: finalRecommendations,
      overallScore: score,
    );
  }

  /// Generate summary text
  static String _generateSummary(_WeeklyAnalysis analysis, bool isPositive) {
    final templates = <String>[];
    
    if (isPositive) {
      templates.addAll([
        "Bu hafta uyqu tartibingiz barqaror va sog'lom bo'lgan. Uyqu davomiyligi va vaqtlari ideal oralig'ida.",
        "Ajoyib! Haftalik uyqu ko'rsatkichlaringiz namunali. Biologik soatingiz to'g'ri ishlayapti.",
        "Uyqu rejimingiz bu hafta a'lo darajada. Tartib barqaror, davomiylik me'yorda.",
        "Sog'lom uyqu tartibi — bu hafta sizda hammasi yaxshi. Shu ritmni davom ettiring.",
        "Uyqu sifat ko'rsatkichlari yaxshi. Tanangiz to'liq tiklangan va energiya darajasi yuqori.",
      ]);
    } else {
      if (analysis.veryLateSleepDays >= 3) {
        templates.addAll([
          "Bu hafta uyqu tartibingiz beqaror — ${analysis.veryLateSleepDays} kun juda kech uxlagansiz (02:00 dan keyin).",
          "Haftalik ko'rsatkichlar: ${analysis.veryLateSleepDays} kun juda kech uxlagan. Bu biologik ritmga salbiy ta'sir qiladi.",
          "Uyqu vaqti tartibsiz — ${analysis.veryLateSleepDays} kun 02:00 dan keyin uxlagansiz.",
        ]);
      } else if (analysis.shortSleepDays >= 3) {
        templates.addAll([
          "Bu hafta ${analysis.shortSleepDays} kun uyqu yetarli bo'lmagan (6 soatdan kam).",
          "Uyqu qarzining belgilari: ${analysis.shortSleepDays} kun yetarli uyqu olmadingiz.",
          "Kam uyqu haftasi — ${analysis.shortSleepDays} kun 6 soatdan kam uxlagansiz.",
        ]);
      } else if (analysis.sleepTimeStdDev > 120) {
        templates.addAll([
          "Uyqu tartibida beqarorlik kuzatilmoqda. Har kuni turli vaqtda uxlash biologik ritmni buzadi.",
          "Tartibsiz uyqu rejimi — uyqu vaqtlari ${_formatTimeDifference(analysis.sleepTimeStdDev)} farq qiladi.",
          "Uyqu vaqtlari beqaror. Biologik soatingiz sinxronlashmagan.",
        ]);
      } else {
        templates.addAll([
          "Bu hafta uyqu tartibingiz o'rtacha barqaror, ammo ba'zi muammolar kuzatilmoqda.",
          "Haftalik uyqu ko'rsatkichlaringiz aralash. Ba'zi kunlar yaxshi, ba'zilarida tuzatish kerak.",
          "Uyqu rejimingizda yaxshilanish mumkin. Quyidagi tavsiyalarga amal qiling.",
        ]);
      }
    }

    return templates[analysis.random.nextInt(templates.length)];
  }

  /// Generate title
  static String _generateTitle(_WeeklyAnalysis analysis, bool isPositive) {
    if (isPositive) {
      final titles = [
        "Uyqu tartibi a'lo",
        "Sog'lom uyqu rejimi",
        "Ideal uyqu tartibi",
        "Barqaror uyqu",
      ];
      return titles[analysis.random.nextInt(titles.length)];
    } else {
      if (analysis.veryLateSleepDays >= 3) {
        return "Kech uxlagan kunlar ko'p";
      } else if (analysis.shortSleepDays >= 3) {
        return "Uyqu yetarli emas";
      } else if (analysis.sleepTimeStdDev > 120) {
        return "Tartibsiz uyqu rejimi";
      } else {
        return "Uyqu tartibi yaxshilanishi mumkin";
      }
    }
  }

  /// Calculate overall score (0-100)
  static int _calculateScore(_WeeklyAnalysis analysis) {
    int score = 100;

    // Deduct for very late sleep
    score -= analysis.veryLateSleepDays * 15;
    score -= analysis.lateSleepDays * 5;

    // Deduct for short sleep
    score -= analysis.shortSleepDays * 12;

    // Deduct for oversleep
    score -= analysis.oversleepDays * 8;

    // Deduct for late wake
    score -= analysis.lateWakeDays * 6;

    // Deduct for inconsistency
    if (analysis.sleepTimeStdDev > 120) score -= 15;
    else if (analysis.sleepTimeStdDev > 90) score -= 10;
    else if (analysis.sleepTimeStdDev > 60) score -= 5;

    if (analysis.wakeTimeStdDev > 120) score -= 15;
    else if (analysis.wakeTimeStdDev > 90) score -= 10;
    else if (analysis.wakeTimeStdDev > 60) score -= 5;

    // Bonus for good duration
    if (analysis.avgDurationHours >= goodSleepMinHours && 
        analysis.avgDurationHours <= goodSleepMaxHours) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  // Problem templates
  static List<String> _getVeryLateSleepProblems(_WeeklyAnalysis analysis) {
    final templates = [
      "${analysis.veryLateSleepDays} kun juda kech uxlagansiz (02:00 dan keyin). Bu biologik ritmga jiddiy zarar yetkazadi.",
      "Juda kech uxlagan kunlar: ${analysis.veryLateSleepDays}. Bu uyqu sifatini pasaytiradi va ertasi kuni charchoqni keltiradi.",
      "${analysis.veryLateSleepDays} kun 02:00 dan keyin uxlagansiz. Bu uyqu qarzini oshiradi.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  static List<String> _getLateSleepProblems(_WeeklyAnalysis analysis) {
    final templates = [
      "${analysis.lateSleepDays} kun kech uxlagansiz (00:00 dan keyin).",
      "Kech uxlagan kunlar: ${analysis.lateSleepDays}. Tartibni normallashtirish kerak.",
      "${analysis.lateSleepDays} kun ertaroq uxlashni tavsiya qilamiz.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  static List<String> _getShortSleepProblems(_WeeklyAnalysis analysis) {
    final templates = [
      "${analysis.shortSleepDays} kun uyqu yetarli bo'lmagan (6 soatdan kam).",
      "Kam uyqu kunlari: ${analysis.shortSleepDays}. Bu diqqat va energiyaga ta'sir qiladi.",
      "${analysis.shortSleepDays} kun 6 soatdan kam uxlagansiz. Uyqu qarzi yig'ilmoqda.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  static List<String> _getOversleepProblems(_WeeklyAnalysis analysis) {
    final templates = [
      "${analysis.oversleepDays} kun uyqu me'yoridan oshib ketgan (10 soatdan ko'p).",
      "Ortiqcha uyqu: ${analysis.oversleepDays} kun. Bu ham charchoq belgisidir.",
      "${analysis.oversleepDays} kun 10 soatdan ko'p uxlagansiz. Uyqu davomiyligini 7-9 soat oralig'ida ushlab turing.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  static List<String> _getLateWakeProblems(_WeeklyAnalysis analysis) {
    final templates = [
      "${analysis.lateWakeDays} kun kech uyg'onish kuzatilgan (09:30 dan keyin).",
      "Kech uyg'onish: ${analysis.lateWakeDays} kun. Bu biologik ritmni buzadi.",
      "${analysis.lateWakeDays} kun 09:30 dan keyin uyg'onansiz. Ertaroq turishni odat qiling.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  static List<String> _getInconsistencyProblems(_WeeklyAnalysis analysis) {
    final sleepDiff = _formatTimeDifference(analysis.sleepTimeStdDev);
    final wakeDiff = _formatTimeDifference(analysis.wakeTimeStdDev);
    
    final templates = [
      "Uyqu vaqtlari beqaror — har kuni ${sleepDiff} farq qiladi. Biologik soatingiz sinxronlashmagan.",
      "Uyg'onish vaqtlari tartibsiz — ${wakeDiff} farq kuzatilmoqda.",
      "Uyqu tartibida beqarorlik bor. Har kuni bir xil vaqtda uxlash va uyg'onish kerak.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  static List<String> _getPositiveFeedback(_WeeklyAnalysis analysis) {
    final templates = [
      "Uyqu davomiyligi ko'pchilik kunlarda me'yorida (7-9 soat).",
      "Uyqu vaqtlari barqaror va biologik ritmga mos.",
      "Uyg'onish vaqtlari muntazam — bu yaxshi belgi.",
    ];
    return [templates[analysis.random.nextInt(templates.length)]];
  }

  // Recommendation templates
  static List<String> _getBedtimeRecommendations(_WeeklyAnalysis analysis) {
    final recommendations = <String>[];
    
    // Calculate how much earlier to sleep
    final targetBedtime = 22 * 60; // 22:00 in minutes
    final currentBedtime = (analysis.avgSleepHour % 24) * 60 + analysis.avgSleepMinute;
    final diffMinutes = currentBedtime > targetBedtime 
        ? currentBedtime - targetBedtime 
        : (currentBedtime + 1440) - targetBedtime;
    
    if (diffMinutes > 0) {
      final humanDiff = _formatTimeDifference(diffMinutes.toDouble());
      recommendations.addAll([
        "Keyingi 3-4 kun davomida ${humanDiff} ertaroq uxlashni boshlang.",
        "Uyqu vaqtini ${humanDiff} ertaroq belgilang. 22:00-23:00 oralig'i ideal.",
        "Har kuni ${humanDiff} ertaroq uxlashga harakat qiling.",
      ]);
    }
    
    recommendations.addAll([
      "Uxlashdan 1 soat oldin ekranlardan uzoqlashing — bu uyquga tushishni osonlashtiradi.",
      "22:00-23:00 oralig'ida uxlashni maqsad qiling. Bu biologik ritmga mos keladi.",
    ]);
    
    return [recommendations[analysis.random.nextInt(recommendations.length)]];
  }

  static List<String> _getDurationRecommendations(_WeeklyAnalysis analysis) {
    final recommendations = [
      "Uyqu davomiyligini kamida 7 soatga yetkazishga harakat qiling.",
      "Har kuni 7-9 soat uxlashni maqsad qiling. Bu sog'liq uchun zarur.",
      "Uyqu qarzini qaytarish uchun keyingi bir necha kun 7-8 soat uxlashni odat qiling.",
      "Kam uyqu diqqat va kayfiyatga ta'sir qiladi. Uyqu vaqtini oshiring.",
    ];
    return [recommendations[analysis.random.nextInt(recommendations.length)]];
  }

  static List<String> _getWakeTimeRecommendations(_WeeklyAnalysis analysis) {
    final recommendations = [
      "Uyg'onish vaqtini 07:00-08:00 oralig'ida ushlab turing.",
      "Har kuni bir xil vaqtda uyg'onishni odat qiling — bu biologik ritmni barqarorlashtiradi.",
      "07:00-08:00 oralig'i uyg'onish uchun ideal vaqt. Shu vaqtni belgilang.",
      "Kech uyg'onish biologik ritmni buzadi. Ertaroq turishni boshlang.",
    ];
    return [recommendations[analysis.random.nextInt(recommendations.length)]];
  }

  static List<String> _getConsistencyRecommendations(_WeeklyAnalysis analysis) {
    final recommendations = [
      "Har kuni bir xil vaqtda uxlash va uyg'onishga intiling. Barqarorlik muhim.",
      "Uyqu tartibini muntazamlashtiring. Har kuni ±30 daqiqa farqga ruxsat bering.",
      "Biologik soatingizni sinxronlashtirish uchun uyqu va uyg'onish vaqtlarini barqarorlashtiring.",
      "Tartibsiz uyqu rejimi uyqu sifatini pasaytiradi. Muntazamlikni maqsad qiling.",
    ];
    return [recommendations[analysis.random.nextInt(recommendations.length)]];
  }

  static List<String> _getMaintenanceRecommendations(_WeeklyAnalysis analysis) {
    final recommendations = [
      "Hozirgi tartibni saqlab turing va muntazam kuzatib boring.",
      "Uyqu rejimingiz yaxshi. Shu ritmni davom ettiring.",
      "Sog'lom uyqu tartibini saqlash uchun muntazam kuzatuvni davom eting.",
    ];
    return [recommendations[analysis.random.nextInt(recommendations.length)]];
  }

  /// Format time difference in human-friendly way
  static String _formatTimeDifference(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    
    if (hours > 0 && mins > 0) {
      return "$hours soat $mins daqiqa";
    } else if (hours > 0) {
      return "$hours soat";
    } else if (mins >= 30) {
      return "${(mins / 15).round() * 15} daqiqa";
    } else if (mins >= 15) {
      return "15-30 daqiqa";
    } else {
      return "15 daqiqa";
    }
  }
}

/// Internal analysis data structure
class _WeeklyAnalysis {
  final double avgDurationHours;
  final int avgSleepHour;
  final int avgSleepMinute;
  final int avgWakeHour;
  final int avgWakeMinute;
  final int lateSleepDays;
  final int veryLateSleepDays;
  final int earlyWakeDays;
  final int lateWakeDays;
  final int shortSleepDays;
  final int oversleepDays;
  final double sleepTimeStdDev;
  final double wakeTimeStdDev;
  final double durationStdDev;
  final int totalDays;
  final Random random;

  _WeeklyAnalysis({
    required this.avgDurationHours,
    required this.avgSleepHour,
    required this.avgSleepMinute,
    required this.avgWakeHour,
    required this.avgWakeMinute,
    required this.lateSleepDays,
    required this.veryLateSleepDays,
    required this.earlyWakeDays,
    required this.lateWakeDays,
    required this.shortSleepDays,
    required this.oversleepDays,
    required this.sleepTimeStdDev,
    required this.wakeTimeStdDev,
    required this.durationStdDev,
    required this.totalDays,
    required this.random,
  });
}
