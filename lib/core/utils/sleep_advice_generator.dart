import 'dart:math';
import '../../core/models/sleep_record_model.dart';

/// Intelligent sleep advice generator based on multi-factor analysis
/// Analyzes sleepStart, wakeTime, duration, quality, and circadian health
class SleepAdviceGenerator {
  /// Get intelligent advice based on comprehensive sleep analysis
  static String? getAdvice(SleepRecordModel record) {
    if (record.sleepStart == null || record.wakeTime == null || record.durationMinutes <= 0) {
      return null;
    }

    final sleepStart = record.sleepStart!;
    final wakeTime = record.wakeTime!;
    final durationHours = record.durationMinutes / 60.0;
    final sleepHour = sleepStart.hour;
    final wakeHour = wakeTime.hour;

    // Determine the most critical issue (priority order)
    final adviceCategory = _determineAdviceCategory(
      sleepHour: sleepHour,
      wakeHour: wakeHour,
      durationHours: durationHours,
    );

    // Get random advice from the selected category
    return _getRandomAdvice(adviceCategory);
  }

  /// Determine the most appropriate advice category based on sleep patterns
  static AdviceCategory _determineAdviceCategory({
    required int sleepHour,
    required int wakeHour,
    required double durationHours,
  }) {
    // Priority 1: Very late sleep (after 02:00) - most critical
    if (sleepHour >= 2) {
      return AdviceCategory.veryLateSleep;
    }

    // Priority 2: Short sleep (< 6h) - critical health issue
    if (durationHours < 6) {
      return AdviceCategory.shortSleep;
    }

    // Priority 3: Oversleep (> 10h) - can indicate problems
    if (durationHours > 10) {
      return AdviceCategory.oversleep;
    }

    // Priority 4: Late wake time (after 10:00) - circadian disruption
    if (wakeHour >= 10) {
      return AdviceCategory.lateWakeTime;
    }

    // Priority 5: Perfect duration but wrong timing (7-9h but past 01:00 start or after 10:00 wake)
    if (durationHours >= 7 && durationHours <= 9) {
      if (sleepHour > 1 || wakeHour >= 10) {
        return AdviceCategory.wrongTiming;
      }
    }

    // Priority 6: Late sleep (after 00:00 but before 02:00) with good duration (>= 7h)
    if (sleepHour > 0 && sleepHour < 2 && durationHours >= 7) {
      return AdviceCategory.lateSleep;
    }

    // Priority 7: Ideal sleep (21:00-23:00 start, 05:00-08:00 wake, 7-9h duration)
    final isIdealSleepTime = (sleepHour >= 21 && sleepHour <= 23);
    final isIdealWakeTime = (wakeHour >= 5 && wakeHour <= 8);
    final isIdealDuration = (durationHours >= 7 && durationHours <= 9);
    
    if (isIdealSleepTime && isIdealWakeTime && isIdealDuration) {
      return AdviceCategory.idealSleep;
    }

    // Default: Late sleep if after midnight but before 02:00
    if (sleepHour > 0 && sleepHour < 2) {
      return AdviceCategory.lateSleep;
    }

    // If duration is good but timing is off
    if (durationHours >= 7 && durationHours <= 9) {
      return AdviceCategory.wrongTiming;
    }

    return AdviceCategory.idealSleep;
  }

  /// Get a random advice message from the specified category
  static String _getRandomAdvice(AdviceCategory category) {
    final random = Random();
    final adviceList = _getAdviceList(category);
    return adviceList[random.nextInt(adviceList.length)];
  }

  /// Get advice list for a specific category
  static List<String> _getAdviceList(AdviceCategory category) {
    switch (category) {
      case AdviceCategory.idealSleep:
        return [
          "Uyqu ritmingiz juda sog'lom — tanangiz a'lo qayta tiklangan.",
          "Ajoyib! Biologik soatingiz tabiiy ritmda ishlayapti.",
          "Bugungi uyqu — namunali. Shu tartibni davom ettiring.",
          "Sog'lom uyqu rejimi — energiya va sog'liqning kaliti.",
          "A'lo natija! Uyqu vaqtingiz va davomiyligi ideal.",
          "Tabiiy ritm bilan uxlash — organizm uchun eng yaxshi.",
        ];

      case AdviceCategory.lateSleep:
        return [
          "Kecha biroz kech uxlagansiz, lekin umumiy uyqu yetarli. Ertaroq uxlashga intiling.",
          "Uyqu davomiyligi yaxshi, ammo kech uxlaganlik ertasi kun energiyani pasaytiradi.",
          "Kech uxlaganlik biologik ritmni buzadi. Ertaroq uxlashga harakat qiling.",
          "Uyqu yetarli, lekin vaqti ideal emas. Ertaroq uxlash sog'liq uchun yaxshiroq.",
          "Kech uxlaganlik uyqu sifatiga ta'sir qiladi. Tartibni normallashtiring.",
        ];

      case AdviceCategory.veryLateSleep:
        return [
          "Juda kech uxlagansiz. Bu uyqu sifatiga salbiy ta'sir qiladi.",
          "Kecha organizm juda kech tinchlagan. Ertaroq uyqu texnikasini sinab ko'ring.",
          "Juda kech uxlaganlik — biologik ritmning jiddiy buzilishi.",
          "Kech uxlaganlik uyqu sifatini pasaytiradi. Ertaroq uxlashga intiling.",
          "Organizm tabiiy ritmga qaytishi uchun ertaroq uxlash kerak.",
          "Juda kech uxlaganlik — sog'liq uchun xavfli. Tartibni o'zgartiring.",
        ];

      case AdviceCategory.lateWakeTime:
        return [
          "Kech uyg'onish biologik ritmni susaytiradi. Bir necha kun ertaroq turib ko'ring.",
          "Uyg'onish odati me'yordan kech. Tana biroz dang bo'lishi mumkin.",
          "Kech uyg'onish kunlik ritmni buzadi. Ertaroq turishga intiling.",
          "Uyg'onish vaqti ideal emas. Ertaroq turish energiyani oshiradi.",
          "Kech uyg'onish — uyqu sifatiga ta'sir qiladi. Tartibni o'zgartiring.",
        ];

      case AdviceCategory.shortSleep:
        return [
          "Uyqu yetarli bo'lmagan. Bugun imkon bo'lsa erta uxlab oling.",
          "6 soatdan kam uyqu — diqqat va kayfiyatga ta'sir qiladi.",
          "Uyqu yetarli emas. Organizm tiklanishga ulgurmagan.",
          "Qisqa uyqu — sog'liq uchun xavfli. Kamida 7 soat uxlashga harakat qiling.",
          "Uyqu yetarli bo'lmagan. Ertasi kun charchoq bo'lishi mumkin.",
          "Kam uyqu — konsentratsiya va energiyani pasaytiradi.",
        ];

      case AdviceCategory.oversleep:
        return [
          "Uyqu me'yoridan ko'p. Bu ham charchoqlik belgisidir.",
          "O'ta ko'p uyqu — organizmning signali. Tartibni normallashtiring.",
          "10 soatdan ko'p uyqu — sog'liq uchun yaxshi emas.",
          "Oshiqcha uyqu — energiyani pasaytiradi. 7-9 soat yetarli.",
          "Uyqu me'yoridan oshib ketgan. Tartibni o'zgartiring.",
        ];

      case AdviceCategory.wrongTiming:
        return [
          "Uyqu davomiyligi yaxshi, ammo vaqtlar ritmga zid.",
          "Soatlar bo'yicha uyqu ideal emas, tartibga solish foydali.",
          "Davomiylik yaxshi, lekin uyqu vaqti tabiiy ritmga mos emas.",
          "Uyqu yetarli, ammo vaqtlar biologik soatga zid.",
          "Davomiylik ideal, lekin uyqu vaqti o'zgartirilishi kerak.",
        ];
    }
  }
}

/// Advice categories based on sleep patterns
enum AdviceCategory {
  idealSleep,
  lateSleep,
  veryLateSleep,
  lateWakeTime,
  shortSleep,
  oversleep,
  wrongTiming,
}
