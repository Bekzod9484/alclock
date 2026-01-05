import '../models/sleep_record_model.dart';

/// New sleep advice system with exact rules
class SleepAdviceGenerator {
  /// Build daily sleep advice based on exact rules
  static String buildDailyAdvice(SleepRecordModel record) {
    // Validate input
    if (record.sleepStart == null || record.wakeTime == null || record.durationMinutes <= 0) {
      return "Ma'lumot yetarli emas. Uyqu vaqtini kiriting.";
    }

    final sleepStart = record.sleepStart!;
    final durationHours = record.durationMinutes / 60.0;
    final qualityScore = record.score;

    // STEP 1: Categorize sleepStart time
    final sleepTime = _categorizeSleepTime(sleepStart);

    // STEP 2: Categorize sleep duration
    final duration = _categorizeDuration(durationHours);

    // STEP 3: Categorize sleep quality
    final quality = _categorizeQuality(qualityScore);

    // STEP 4: Generate advice based on conditions
    return _generateDailyAdvice(sleepTime, duration, quality);
  }

  /// STEP 1: Categorize sleepStart time
  static String _categorizeSleepTime(DateTime sleepStart) {
    final hour = sleepStart.hour;
    final minute = sleepStart.minute;
    final totalMinutes = hour * 60 + minute;

    // Convert to minutes from midnight for easier comparison
    // Handle midnight rollover: if hour is 0-2, it's after midnight
    int sleepMinutes;
    if (hour >= 22) {
      // 22:00-23:59
      sleepMinutes = totalMinutes;
    } else if (hour < 3) {
      // 00:00-02:59 (after midnight)
      sleepMinutes = totalMinutes + 1440; // Add 24 hours
    } else {
      // 03:00-21:59 (shouldn't happen for normal sleep, but handle it)
      sleepMinutes = totalMinutes;
    }

    // Categorize
    final earlyEnd = 22 * 60; // 22:00
    final normalStart = 23 * 60 + 30; // 23:30
    final normalEnd = 24 * 60 + 30; // 00:30 (next day)
    final lateEnd = 24 * 60 + 2 * 60; // 02:00 (next day)

    if (sleepMinutes >= earlyEnd && sleepMinutes < normalStart) {
      return "early"; // 22:00-23:30
    } else if (sleepMinutes >= normalStart && sleepMinutes < normalEnd) {
      return "normal"; // 23:30-00:30
    } else if (sleepMinutes >= normalEnd && sleepMinutes < lateEnd) {
      return "late"; // 00:30-02:00
    } else {
      return "veryLate"; // > 02:00
    }
  }

  /// STEP 2: Categorize sleep duration
  static String _categorizeDuration(double durationHours) {
    if (durationHours < 5) {
      return "veryShort";
    } else if (durationHours >= 5 && durationHours < 6) {
      return "short";
    } else if (durationHours >= 6 && durationHours < 7) {
      return "belowIdeal";
    } else if (durationHours >= 7 && durationHours <= 9) {
      return "ideal";
    } else if (durationHours > 9.5) {
      return "oversleep";
    } else {
      // 9.0-9.5 hours - still ideal
      return "ideal";
    }
  }

  /// STEP 3: Categorize sleep quality
  static String _categorizeQuality(int qualityScore) {
    if (qualityScore >= 90) {
      return "excellent";
    } else if (qualityScore >= 75 && qualityScore <= 89) {
      return "good";
    } else if (qualityScore >= 60 && qualityScore <= 74) {
      return "average";
    } else {
      return "low";
    }
  }

  /// STEP 4: Generate daily advice based on conditions
  static String _generateDailyAdvice(String sleepTime, String duration, String quality) {
    // 1) Ideal night
    if ((sleepTime == "early" || sleepTime == "normal") &&
        duration == "ideal" &&
        (quality == "excellent" || quality == "good")) {
      return "☀️ Ajoyib tun! Yetarli muddat va vaqtida uxlabsiz. Tanangiz yaxshi tiklangan. "
          "Shu tartibni davom ettiring.";
    }

    // 2) Good but slightly late
    if (sleepTime == "late" && (duration == "ideal" || duration == "belowIdeal")) {
      return "😴 Uyqu sifati yaxshi, ammo yotish vaqti biroz kech. "
          "Agar imkon bo'lsa, 23:00 gacha yotish uyqu sifatini yanada oshiradi.";
    }

    // 3) Very late sleep OR short duration
    if (sleepTime == "veryLate" ||
        (sleepTime == "late" && (duration == "veryShort" || duration == "short"))) {
      return "⚠️ Juda kech uxlagansiz yoki uyqu yetarli bo'lmagan. "
          "Bu ertasi kuni charchoq va diqqatning pasayishiga olib keladi. "
          "Bugun ertaroq yotishga harakat qiling.";
    }

    // 4) Duration too short
    if ((duration == "veryShort" || duration == "short") && quality != "excellent") {
      return "⚠️ Uyqu davomiyligi yetarli bo'lmagan. Tanangiz to'liq tiklana olmaydi. "
          "Kamida 7 soat uyquni nishonga oling.";
    }

    // 5) Oversleep
    if (duration == "oversleep") {
      return "😴 Bugun juda ko'p uxlagansiz. Ba'zan tanaga shunday tun kerak bo'lishi mumkin, "
          "ammo muntazam takrorlansa, kun davomida sustlikka olib keladi.";
    }

    // 6) Quality low but duration normal
    if (quality == "low" && (duration == "ideal" || duration == "belowIdeal")) {
      return "🌙 Uyqu davomiyligi yaxshi, ammo sifat past. "
          "Tez-tez uyg'onish yoki bezovtalik bo'lgan bo'lishi mumkin. "
          "Uxlashdan 1 soat oldin ekranlardan uzoqlashish yordam beradi.";
    }

    // Default fallback
    return "Uyqu ma'lumotlari qayta ishlanmoqda. Uyqu tartibini yaxshilash uchun "
        "muntazam vaqtda uxlash va uyg'onishni odat qiling.";
  }

  /// Legacy method for backward compatibility
  static String? getAdvice(SleepRecordModel record) {
    return buildDailyAdvice(record);
  }
}
