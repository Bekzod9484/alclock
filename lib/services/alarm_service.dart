import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/alarm_model.dart';
import 'hive_service.dart';
import 'alarm_player.dart';
import 'notification_service.dart';
import '../utils/android_alarm_debug.dart';

class AlarmService {
  final HiveService _hiveService;
  final NotificationService? _notificationService;
  static const MethodChannel _channel =
      MethodChannel('alclock/alarm_scheduler');

  // iOS uchun alarm fire simulyatsiya timerlari (debug-only)
  final Map<String, Timer> _iosSimulationTimers = {};

  AlarmService(this._hiveService, [this._notificationService]);

  Future<void> initialize() async {
    print('✅ AlarmService initialized (using real AlarmManager)');
  }

  /// Schedule alarm - platform-aware implementation
  /// - Android: Uses REAL AlarmManager (NOT notifications)
  /// - iOS: Uses flutter_local_notifications (ONLY mechanism available on iOS)
  ///
  /// IMPORTANT: Always cancels existing alarm first to prevent duplicates
  /// CRITICAL: Platform-safe - works on both Android and iOS
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    try {
      // CRITICAL: Cancel existing alarm FIRST to prevent duplicate IDs
      await cancelAlarmById(alarm.id);

      if (!alarm.isEnabled || !alarm.isActive) {
        // Already cancelled above, just return
        return;
      }

      // Save alarm to Hive first (works on all platforms)
      await _hiveService.saveAlarm(alarm);

      // Platform-specific scheduling
      if (Platform.isAndroid) {
        // ANDROID: Use AlarmManager (existing implementation)
        await _scheduleAlarmAndroid(alarm);
      } else if (Platform.isIOS) {
        // iOS: Use flutter_local_notifications
        // NOTE: iOS cannot auto-open full screen or auto-play audio when app is terminated.
        // This is an Apple limitation, not a bug. User must tap notification to open app.
        await _scheduleAlarmIOS(alarm);
      } else {
        print(
            '⚠️ Alarm scheduling not supported on this platform. Alarm saved to storage only.');
        return;
      }
    } catch (e) {
      // Catch any other unexpected errors
      print('❌ Error scheduling alarm: $e');
      // Don't rethrow - prevent crash, alarm is still saved to Hive
    }
  }

  /// Schedule alarm on Android using AlarmManager
  Future<void> _scheduleAlarmAndroid(AlarmModel alarm) async {
    // Calculate next alarm time
    final scheduledTime = _getNextAlarmTime(alarm);
    if (scheduledTime == null) {
      print('⚠️ No scheduled time found for alarm: ${alarm.id}');
      return;
    }

    // Use REAL AlarmManager via MethodChannel (Android only)
    final scheduledTimeMillis = scheduledTime.millisecondsSinceEpoch;
    final soundName = alarm.soundName ?? 'alarm1';
    final isRepeating = alarm.repeatDays.isNotEmpty;

    // CRITICAL: Log calculated time for debugging
    final now = DateTime.now();
    final timeUntilAlarm = scheduledTime.difference(now);
    print('⏰ [AlarmService] Calculated alarm time:');
    print('   Current time: $now');
    print('   Scheduled time: $scheduledTime');
    print(
        '   Time until alarm: ${timeUntilAlarm.inMinutes} minutes (${timeUntilAlarm.inSeconds} seconds)');

    try {
      print('🔔 [AlarmService] Scheduling alarm via AlarmManager...');
      print('   Alarm ID: ${alarm.id}');
      print('   Scheduled time: $scheduledTime (${scheduledTimeMillis}ms)');
      print('   Sound: $soundName');
      print('   Repeating: $isRepeating');
      if (isRepeating) {
        print('   Repeat days: ${alarm.repeatDays}');
      }

      await _channel.invokeMethod('scheduleAlarm', {
        'alarmId': alarm.id,
        'scheduledTime': scheduledTimeMillis,
        'soundName': soundName,
        'isRepeating': isRepeating,
        'repeatDays': alarm.repeatDays,
      });

      print(
          '✅ [AlarmService] Real alarm scheduled successfully: ${alarm.id} at $scheduledTime (using AlarmManager)');

      // Android alarm debug log
      AndroidAlarmDebug.logAlarmScheduled(
        alarmId: alarm.id,
        scheduledTime: scheduledTime,
        soundName: soundName,
        isRepeating: isRepeating,
      );
    } on MissingPluginException catch (e) {
      // Handle MissingPluginException gracefully - don't crash
      print(
          '⚠️ MissingPluginException: Native alarm scheduling not available. Alarm saved but not scheduled.');
      print(
          '   This usually means the app needs to be rebuilt after native code changes.');
      print('   Error: $e');
      // Don't rethrow - alarm is saved, just not scheduled
    } on PlatformException catch (e) {
      // Handle other platform exceptions
      print('⚠️ PlatformException scheduling alarm: ${e.message}');
      // Don't rethrow - alarm is saved, just not scheduled
    }
  }

  /// Schedule alarm on iOS using flutter_local_notifications
  ///
  /// IMPORTANT iOS LIMITATIONS (Apple restrictions, not bugs):
  /// - iOS cannot auto-open full screen when notification arrives
  /// - iOS cannot auto-play audio when app is terminated
  /// - User MUST tap notification to open app and trigger alarm screen
  /// - This is the ONLY way to implement alarms on iOS without jailbreak
  Future<void> _scheduleAlarmIOS(AlarmModel alarm) async {
    if (_notificationService == null) {
      print('⚠️ NotificationService not available for iOS alarm scheduling');
      return;
    }

    // Calculate next alarm time
    final scheduledTime = _getNextAlarmTime(alarm);
    if (scheduledTime == null) {
      print('⚠️ No scheduled time found for alarm: ${alarm.id}');
      return;
    }

    final soundName = alarm.soundName ?? 'alarm1';
    final isRepeating = alarm.repeatDays.isNotEmpty;
    final alarmTime = TimeOfDay.fromDateTime(alarm.time);

    // Log calculated time for debugging
    final now = DateTime.now();
    final timeUntilAlarm = scheduledTime.difference(now);
    print('⏰ [AlarmService iOS] Calculated alarm time:');
    print('   Current time: $now');
    print('   Scheduled time: $scheduledTime');
    print(
        '   Time until alarm: ${timeUntilAlarm.inMinutes} minutes (${timeUntilAlarm.inSeconds} seconds)');

    try {
      print(
          '🔔 [AlarmService iOS] Scheduling alarm via flutter_local_notifications...');
      print('   Alarm ID: ${alarm.id}');
      print('   Scheduled time: $scheduledTime');
      print('   Sound: $soundName');
      print('   Repeating: $isRepeating');
      if (isRepeating) {
        print('   Repeat days: ${alarm.repeatDays}');
      }

      // Use notification ID based on alarm ID hash
      final notificationId = alarm.id.hashCode.abs();

      if (isRepeating && alarm.repeatDays.isNotEmpty) {
        // Schedule repeating notification
        await _notificationService!.scheduleRepeatingNotification(
          id: notificationId,
          title: 'Alarm',
          body:
              'Wake up! ${alarmTime.hour}:${alarmTime.minute.toString().padLeft(2, '0')}',
          scheduledDate: scheduledTime,
          weekdays: alarm.repeatDays,
          alarmId: alarm.id,
          soundName: soundName,
        );
      } else {
        // Schedule one-time notification
        await _notificationService!.scheduleNotification(
          id: notificationId,
          title: 'Alarm',
          body:
              'Wake up! ${alarmTime.hour}:${alarmTime.minute.toString().padLeft(2, '0')}',
          scheduledDate: scheduledTime,
          alarmId: alarm.id,
          soundName: soundName,
        );
      }

      print(
          '✅ [AlarmService iOS] Alarm scheduled successfully: ${alarm.id} at $scheduledTime (using notifications)');
      print(
          '   NOTE: User must tap notification to open app and trigger alarm screen');

      // iOS uchun Android alarm simulyatsiya logi
      AndroidAlarmDebug.logAlarmScheduled(
        alarmId: alarm.id,
        scheduledTime: scheduledTime,
        soundName: soundName,
        isRepeating: isRepeating,
      );

      // iOS uchun alarm fire simulyatsiyasi (debug-only)
      // Bu Android'da alarm vaqti kelganda nima bo'lishini simulyatsiya qiladi
      _scheduleIOSAlarmFireSimulation(
        alarmId: alarm.id,
        scheduledTime: scheduledTime,
        soundName: soundName,
      );
    } catch (e) {
      print('❌ Error scheduling iOS alarm: $e');
      // Don't rethrow - alarm is saved, just not scheduled
    }
  }

  /// iOS uchun alarm fire simulyatsiyasi (debug-only)
  ///
  /// Bu metod iOS da alarm vaqti kelganda Android alarm xatti-harakatlarini
  /// simulyatsiya qiladi va console loglar chiqaradi.
  ///
  /// NOTE: Bu faqat debug maqsadida. UI ochilmaydi, faqat loglar chiqariladi.
  void _scheduleIOSAlarmFireSimulation({
    required String alarmId,
    required DateTime scheduledTime,
    required String soundName,
  }) {
    // Faqat iOS uchun
    if (!Platform.isIOS) {
      return;
    }

    // Eski timer ni bekor qilish (agar mavjud bo'lsa)
    _iosSimulationTimers[alarmId]?.cancel();

    final now = DateTime.now();
    final duration = scheduledTime.difference(now);

    // Agar alarm vaqti o'tib ketgan bo'lsa, simulyatsiya qilmaymiz
    if (duration.isNegative) {
      print(
          '[ANDROID-ALARM] ⚠️ Alarm vaqti o\'tib ketgan, simulyatsiya qilinmaydi');
      return;
    }

    print(
        '[ANDROID-ALARM] 📅 Alarm fire simulyatsiyasi belgilandi: ${duration.inSeconds} soniyadan keyin');

    // Timer yaratish - alarm vaqti kelganda ishga tushadi
    final timer = Timer(duration, () {
      // Alarm vaqti yetdi - Android alarm trigger simulyatsiyasi
      _simulateAndroidAlarmFire(
        alarmId: alarmId,
        soundName: soundName,
      );

      // Timer ni ro'yxatdan olib tashlash
      _iosSimulationTimers.remove(alarmId);
    });

    // Timer ni saqlash (keyinchalik bekor qilish uchun)
    _iosSimulationTimers[alarmId] = timer;
  }

  /// Android alarm fire simulyatsiyasi
  ///
  /// Bu metod alarm vaqti kelganda Android'da nima bo'lishini simulyatsiya qiladi.
  /// Faqat console loglar chiqariladi, UI ochilmaydi.
  void _simulateAndroidAlarmFire({
    required String alarmId,
    required String soundName,
  }) {
    // Faqat iOS uchun
    if (!Platform.isIOS) {
      return;
    }

    print('[ANDROID-ALARM] ========================================');
    print('[ANDROID-ALARM] 🔔 ALARM VAQTI YETDI (SIMULYATSIYA)');
    print('[ANDROID-ALARM] ========================================');

    // 1. Alarm vaqti yetdi (Receiver ishga tushdi)
    AndroidAlarmDebug.logAlarmTriggered(
      alarmId: alarmId,
      soundName: soundName,
    );

    // 2. Ringing ekrani ochildi (kichik kechikish bilan)
    Future.delayed(const Duration(milliseconds: 100), () {
      AndroidAlarmDebug.logRingingScreenOpened(
        alarmId: alarmId,
        soundName: soundName,
      );
    });

    // 3. Alarm musiqasi chalinyapti (kichik kechikish bilan)
    Future.delayed(const Duration(milliseconds: 200), () {
      AndroidAlarmDebug.logAlarmPlaying(
        alarmId: alarmId,
        soundName: soundName,
      );

      print('[ANDROID-ALARM] ========================================');
      print('[ANDROID-ALARM] ✅ Android alarm fire simulyatsiyasi yakunlandi');
      print('[ANDROID-ALARM] ========================================');
    });
  }

  /// Cancel alarm - platform-aware implementation
  /// - Android: Cancels via AlarmManager
  /// - iOS: Cancels via NotificationService
  /// Safe to call multiple times - won't crash if alarm doesn't exist
  /// CRITICAL: Platform-safe - gracefully handles MissingPluginException
  Future<void> cancelAlarmById(String alarmId) async {
    try {
      if (Platform.isAndroid) {
        // ANDROID: Cancel via AlarmManager
        try {
          print(
              '🔔 [AlarmService] Cancelling alarm via AlarmManager: $alarmId');
          // Cancel real alarm via AlarmManager (safe even if doesn't exist)
          await _channel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
          print('✅ [AlarmService] Real alarm cancelled: $alarmId');

          // Android alarm debug log
          AndroidAlarmDebug.logAlarmCancelled(alarmId: alarmId);
        } on MissingPluginException catch (e) {
          // Handle MissingPluginException gracefully - don't crash
          print(
              '⚠️ MissingPluginException: Native alarm cancellation not available.');
          print('   Error: $e');
          // Continue to update Hive even if native cancel fails
        } on PlatformException catch (e) {
          // Handle other platform exceptions
          print('⚠️ PlatformException cancelling alarm: ${e.message}');
          // Continue to update Hive even if native cancel fails
        }
      } else if (Platform.isIOS) {
        // iOS: Cancel via NotificationService
        if (_notificationService != null) {
          try {
            final notificationId = alarmId.hashCode.abs();
            print(
                '🔔 [AlarmService iOS] Cancelling alarm via NotificationService: $alarmId');
            await _notificationService!.cancelNotification(notificationId);
            print(
                '✅ [AlarmService iOS] Alarm notification cancelled: $alarmId');

            // iOS uchun Android alarm simulyatsiya logi
            AndroidAlarmDebug.logAlarmCancelled(alarmId: alarmId);

            // iOS simulyatsiya timer ni bekor qilish
            _iosSimulationTimers[alarmId]?.cancel();
            _iosSimulationTimers.remove(alarmId);
          } catch (e) {
            print('⚠️ Error cancelling iOS alarm notification: $e');
          }
        }
      }

      // Update alarm in Hive if it exists (non-blocking, works on all platforms)
      try {
        final alarms = await _hiveService.getAllAlarms();
        final alarm = alarms.firstWhere((a) => a.id == alarmId);
        final updatedAlarm = alarm.copyWith(isActive: false);
        await _hiveService.saveAlarm(updatedAlarm);
      } catch (e) {
        // Alarm not found in Hive - this is okay, might be a snooze alarm or already deleted
        // Don't log as error, just continue
      }
    } catch (e) {
      // Don't rethrow - cancel should be safe even if it fails
      print('⚠️ Error cancelling alarm (non-critical): $e');
    }
  }

  /// Schedule snooze (5 minutes later) - platform-aware implementation
  /// - Android: Uses AlarmManager
  /// - iOS: Uses NotificationService
  /// CRITICAL: Platform-safe - gracefully handles MissingPluginException
  Future<void> scheduleSnooze(String alarmId) async {
    try {
      if (Platform.isAndroid) {
        // ANDROID: Use AlarmManager
        await _scheduleSnoozeAndroid(alarmId);
      } else if (Platform.isIOS) {
        // iOS: Use NotificationService
        await _scheduleSnoozeIOS(alarmId);
      } else {
        print('⚠️ Snooze scheduling not supported on this platform.');
        return;
      }
    } catch (e) {
      print('❌ Error scheduling snooze: $e');
      // Don't rethrow - prevent crash
    }
  }

  /// Schedule snooze on Android using AlarmManager
  Future<void> _scheduleSnoozeAndroid(String alarmId) async {
    // Remove _snooze suffix if present to find original alarm
    final baseAlarmId = alarmId.replaceAll('_snooze', '');

    final alarms = await _hiveService.getAllAlarms();
    AlarmModel? alarm;

    try {
      alarm = alarms.firstWhere((a) => a.id == baseAlarmId);
    } catch (e) {
      // If original alarm not found, try to find by the provided ID
      try {
        alarm = alarms.firstWhere((a) => a.id == alarmId);
      } catch (e2) {
        print('⚠️ Alarm not found for snooze: $alarmId');
        // Create a basic alarm for snooze
        alarm = AlarmModel(
          id: baseAlarmId,
          time: DateTime.now(),
          soundName: 'alarm1',
        );
      }
    }

    // Create snooze alarm (5 minutes from now)
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final snoozeTimeMillis = snoozeTime.millisecondsSinceEpoch;
    final soundName = alarm.soundName ?? 'alarm1';

    // Schedule using REAL AlarmManager
    try {
      await _channel.invokeMethod('scheduleSnooze', {
        'alarmId': alarmId,
        'scheduledTime': snoozeTimeMillis,
        'soundName': soundName,
      });

      print('✅ Snooze scheduled for 5 minutes (using AlarmManager)');

      // Android alarm debug log
      AndroidAlarmDebug.logSnoozePressed(
        alarmId: alarmId,
        snoozeTime: snoozeTime,
        soundName: soundName,
      );
    } on MissingPluginException catch (e) {
      // Handle MissingPluginException gracefully - don't crash
      print(
          '⚠️ MissingPluginException: Native snooze scheduling not available.');
      print('   Error: $e');
    } on PlatformException catch (e) {
      // Handle other platform exceptions
      print('⚠️ PlatformException scheduling snooze: ${e.message}');
    }
  }

  /// Schedule snooze on iOS using NotificationService
  Future<void> _scheduleSnoozeIOS(String alarmId) async {
    if (_notificationService == null) {
      print('⚠️ NotificationService not available for iOS snooze scheduling');
      return;
    }

    // Remove _snooze suffix if present to find original alarm
    final baseAlarmId = alarmId.replaceAll('_snooze', '');

    final alarms = await _hiveService.getAllAlarms();
    AlarmModel? alarm;

    try {
      alarm = alarms.firstWhere((a) => a.id == baseAlarmId);
    } catch (e) {
      // If original alarm not found, try to find by the provided ID
      try {
        alarm = alarms.firstWhere((a) => a.id == alarmId);
      } catch (e2) {
        print('⚠️ Alarm not found for snooze: $alarmId');
        // Create a basic alarm for snooze
        alarm = AlarmModel(
          id: baseAlarmId,
          time: DateTime.now(),
          soundName: 'alarm1',
        );
      }
    }

    // Create snooze alarm (5 minutes from now)
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final soundName = alarm.soundName ?? 'alarm1';
    final snoozeNotificationId = '${alarmId}_snooze'.hashCode.abs();

    try {
      await _notificationService!.scheduleSnooze(
        id: snoozeNotificationId,
        alarmId: alarmId,
        scheduledDate: snoozeTime,
        soundName: soundName,
      );

      print(
          '✅ [AlarmService iOS] Snooze scheduled for 5 minutes (using notifications)');

      // iOS uchun Android alarm simulyatsiya logi
      AndroidAlarmDebug.logSnoozePressed(
        alarmId: alarmId,
        snoozeTime: snoozeTime,
        soundName: soundName,
      );
    } catch (e) {
      print('❌ Error scheduling iOS snooze: $e');
    }
  }

  /// Stop alarm (stop playing and cancel if it's a snooze)
  /// CRITICAL: Platform-safe - gracefully handles MissingPluginException
  Future<void> stopAlarm(String alarmId) async {
    try {
      // Stop playing alarm (works on all platforms)
      await AlarmPlayer.stopAlarm();

      // If it's a snooze alarm, cancel it
      if (alarmId.endsWith('_snooze')) {
        if (Platform.isAndroid) {
          try {
            await _channel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
          } on MissingPluginException catch (e) {
            // Handle MissingPluginException gracefully - don't crash
            print(
                '⚠️ MissingPluginException: Native alarm cancellation not available.');
            print('   Error: $e');
          } on PlatformException catch (e) {
            // Handle other platform exceptions
            print('⚠️ PlatformException cancelling snooze alarm: ${e.message}');
          }
        } else if (Platform.isIOS && _notificationService != null) {
          try {
            final snoozeNotificationId = alarmId.hashCode.abs();
            await _notificationService!
                .cancelNotification(snoozeNotificationId);
          } catch (e) {
            print('⚠️ Error cancelling iOS snooze notification: $e');
          }
        }
      }

      print('✅ Alarm stopped: $alarmId');

      // Android alarm debug log
      AndroidAlarmDebug.logAlarmStopped(alarmId: alarmId);
    } catch (e) {
      print('❌ Error stopping alarm: $e');
      // Don't rethrow - prevent crash

      // Error log
      AndroidAlarmDebug.logAlarmError(
        alarmId: alarmId,
        error: e.toString(),
      );
    }
  }

  /// Cancel all alarms - uses REAL AlarmManager
  Future<void> cancelAllAlarms() async {
    try {
      // Get all alarms from Hive and cancel each one
      final alarms = await _hiveService.getAllAlarms();
      for (final alarm in alarms) {
        await cancelAlarmById(alarm.id);
      }

      // iOS simulyatsiya timerlarini bekor qilish
      if (Platform.isIOS) {
        for (final timer in _iosSimulationTimers.values) {
          timer.cancel();
        }
        _iosSimulationTimers.clear();
      }

      print('✅ All alarms cancelled');
    } catch (e) {
      print('❌ Error cancelling all alarms: $e');
    }
  }

  /// Dispose - timerlarni tozalash
  void dispose() {
    // Barcha iOS simulyatsiya timerlarini bekor qilish
    for (final timer in _iosSimulationTimers.values) {
      timer.cancel();
    }
    _iosSimulationTimers.clear();
  }

  /// Get next alarm time
  DateTime? _getNextAlarmTime(AlarmModel alarm) {
    final now = DateTime.now();
    final alarmTime = TimeOfDay.fromDateTime(alarm.time);
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    print('📅 [AlarmService] Calculating next alarm time:');
    print(
        '   Alarm time: ${alarmTime.hour}:${alarmTime.minute.toString().padLeft(2, '0')}');
    print(
        '   Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    print('   Scheduled (today): $scheduled');

    // If alarm time has passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      print(
          '   ⏭️ Alarm time passed today, scheduling for tomorrow: $scheduled');
    } else {
      print('   ✅ Alarm time is in the future today: $scheduled');
    }

    // For repeating alarms, find next matching day
    if (alarm.repeatDays.isNotEmpty) {
      final currentWeekday = now.weekday; // 1=Monday, 7=Sunday

      // Find next matching day
      int daysToAdd = 0;
      bool found = false;

      for (int i = 0; i < 7; i++) {
        final checkDay = (currentWeekday + i) % 7;
        final checkDayAdjusted =
            checkDay == 0 ? 7 : checkDay; // Convert 0 to 7 (Sunday)

        if (alarm.repeatDays.contains(checkDayAdjusted)) {
          daysToAdd = i;
          found = true;
          break;
        }
      }

      if (found) {
        scheduled = scheduled.add(Duration(days: daysToAdd));
      } else {
        return null; // No matching day found
      }
    }

    return scheduled;
  }
}
