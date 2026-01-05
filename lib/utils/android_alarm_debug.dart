import 'dart:io';

/// Android Alarm Debug Logger
///
/// Bu utility Android alarm xatti-harakatlarini log qilish uchun ishlatiladi.
/// iOS qurilmalarda Android alarm simulyatsiyasini ko'rsatish uchun ham ishlatiladi.
///
/// Barcha loglar o'zbek tilida va [ANDROID-ALARM] prefiksi bilan chiqariladi.
class AndroidAlarmDebug {
  /// Log prefiksi
  static const String _prefix = '[ANDROID-ALARM]';

  /// Alarm belgilandi
  static void logAlarmScheduled({
    required String alarmId,
    required DateTime scheduledTime,
    required String soundName,
    required bool isRepeating,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';
    final repeatInfo = isRepeating ? ' (Takrorlanuvchi)' : '';

    print('$_prefix ⏰ Alarm belgilandi ($platform)');
    print('$_prefix    Alarm ID: $alarmId');
    print('$_prefix    Vaqt: ${scheduledTime.toString()}');
    print('$_prefix    Ovoz: $soundName$repeatInfo');

    if (Platform.isIOS) {
      print(
          '$_prefix    ⚠️ SIMULYATSIYA: iOS\'da Android alarm xatti-harakatlari simulyatsiya qilinmoqda');
    }
  }

  /// Alarm vaqti yetdi (Receiver ishga tushdi)
  static void logAlarmTriggered({
    required String alarmId,
    required String soundName,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';

    print('$_prefix 🔔 Alarm vaqti yetdi, $platform Receiver ishga tushdi');
    print('$_prefix    Alarm ID: $alarmId');
    print('$_prefix    Ovoz: $soundName');

    if (Platform.isIOS) {
      print('$_prefix    ⚠️ SIMULYATSIYA: Android\'da alarm ishga tushardi');
    }
  }

  /// Ringing ekrani ochildi
  static void logRingingScreenOpened({
    required String alarmId,
    required String soundName,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';

    print('$_prefix 📱 Ringing ekrani ochildi ($platform)');
    print('$_prefix    Alarm ID: $alarmId');
    print('$_prefix    Ovoz: $soundName');

    if (Platform.isIOS) {
      print(
          '$_prefix    ⚠️ SIMULYATSIYA: Android\'da full-screen ringing ekrani ochilgan bo\'lardi');
    }
  }

  /// Alarm musiqasi chalinyapti
  static void logAlarmPlaying({
    required String alarmId,
    required String soundName,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';

    print('$_prefix 🔊 Alarm musiqasi chalinyapti ($platform)');
    print('$_prefix    Alarm ID: $alarmId');
    print('$_prefix    Ovoz: $soundName');

    if (Platform.isIOS) {
      print(
          '$_prefix    ⚠️ SIMULYATSIYA: Android\'da native alarm musiqasi chalinyapti');
    }
  }

  /// Snooze bosildi
  static void logSnoozePressed({
    required String alarmId,
    required DateTime snoozeTime,
    required String soundName,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';

    print('$_prefix ⏸ Snooze bosildi (5 daqiqa) ($platform)');
    print('$_prefix    Alarm ID: $alarmId');
    print('$_prefix    Keyingi signal vaqti: ${snoozeTime.toString()}');
    print('$_prefix    Ovoz: $soundName');

    if (Platform.isIOS) {
      print(
          '$_prefix    ⚠️ SIMULYATSIYA: Android\'da snooze alarm belgilangan bo\'lardi');
    }
  }

  /// Alarm to'xtatildi
  static void logAlarmStopped({
    required String alarmId,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';

    print('$_prefix ⏹ Alarm to\'xtatildi ($platform)');
    print('$_prefix    Alarm ID: $alarmId');

    if (Platform.isIOS) {
      print(
          '$_prefix    ⚠️ SIMULYATSIYA: Android\'da alarm to\'xtatilgan bo\'lardi');
    }
  }

  /// Alarm bekor qilindi
  static void logAlarmCancelled({
    required String alarmId,
  }) {
    final platform = Platform.isAndroid ? 'Android' : 'iOS (SIMULYATSIYA)';

    print('$_prefix ❌ Alarm bekor qilindi ($platform)');
    print('$_prefix    Alarm ID: $alarmId');

    if (Platform.isIOS) {
      print(
          '$_prefix    ⚠️ SIMULYATSIYA: Android\'da alarm bekor qilingan bo\'lardi');
    }
  }

  /// Alarm xatosi
  static void logAlarmError({
    required String alarmId,
    required String error,
  }) {
    print('$_prefix ❌ Alarm xatosi');
    print('$_prefix    Alarm ID: $alarmId');
    print('$_prefix    Xato: $error');
  }
}
