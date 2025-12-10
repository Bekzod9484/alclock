import 'package:flutter/material.dart';
import '../core/models/alarm_model.dart';
import 'hive_service.dart';
import 'notification_service.dart';
import 'alarm_player.dart';

class AlarmService {
  final HiveService _hiveService;
  final NotificationService _notificationService;

  AlarmService(this._hiveService, this._notificationService);

  Future<void> initialize() async {
    print('✅ AlarmService initialized');
  }

  /// Schedule alarm - uses NotificationService with FlutterLocalNotificationsPlugin
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    try {
      if (!alarm.isEnabled || !alarm.isActive) {
        await cancelAlarmById(alarm.id);
        return;
      }

      // Save alarm to Hive first
      await _hiveService.saveAlarm(alarm);

      // Calculate next alarm time
      final scheduledTime = _getNextAlarmTime(alarm);
      if (scheduledTime == null) {
        print('⚠️ No scheduled time found for alarm: ${alarm.id}');
        return;
      }

      // Schedule using NotificationService
      if (alarm.repeatDays.isNotEmpty) {
        await _notificationService.scheduleRepeatingNotification(
          id: alarm.id.hashCode,
          title: 'Alarm',
          body: 'Wake up!',
          scheduledDate: scheduledTime,
          weekdays: alarm.repeatDays,
          alarmId: alarm.id,
          soundName: alarm.soundName,
        );
      } else {
        await _notificationService.scheduleNotification(
          id: alarm.id.hashCode,
          title: 'Alarm',
          body: 'Wake up!',
          scheduledDate: scheduledTime,
          alarmId: alarm.id,
          soundName: alarm.soundName,
        );
      }

      print('✅ Alarm scheduled: ${alarm.id} at $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling alarm: $e');
      rethrow;
    }
  }

  /// Cancel alarm
  Future<void> cancelAlarmById(String alarmId) async {
    try {
      // Cancel notification
      await _notificationService.cancelNotification(alarmId.hashCode);
      
      // Update alarm in Hive if it exists
      final alarms = await _hiveService.getAllAlarms();
      try {
        final alarm = alarms.firstWhere((a) => a.id == alarmId);
        final updatedAlarm = alarm.copyWith(isActive: false);
        await _hiveService.saveAlarm(updatedAlarm);
      } catch (e) {
        // Alarm not found in Hive - this is okay, might be a snooze alarm or already deleted
        print('⚠️ Alarm not found in Hive: $alarmId (this is okay for snooze alarms)');
      }
    } catch (e) {
      print('❌ Error cancelling alarm: $e');
    }
  }

  /// Schedule snooze (5 minutes later)
  Future<void> scheduleSnooze(String alarmId) async {
    try {
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
      
      // Schedule using NotificationService
      await _notificationService.scheduleSnooze(
        id: alarmId.hashCode,
        alarmId: alarmId,
        scheduledDate: snoozeTime,
        soundName: alarm.soundName ?? 'alarm1',
      );
      
      print('✅ Snooze scheduled for 5 minutes');
    } catch (e) {
      print('❌ Error scheduling snooze: $e');
    }
  }

  /// Stop alarm (stop playing and cancel if it's a snooze)
  Future<void> stopAlarm(String alarmId) async {
    try {
      // Stop playing alarm
      await AlarmPlayer.stopAlarm();

      // If it's a snooze alarm, cancel it
      if (alarmId.endsWith('_snooze')) {
        await _notificationService.cancelNotification(alarmId.hashCode);
      }
      
      print('✅ Alarm stopped: $alarmId');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }

  /// Cancel all alarms
  Future<void> cancelAllAlarms() async {
    try {
      await _notificationService.cancelAllNotifications();
      print('✅ All alarms cancelled');
    } catch (e) {
      print('❌ Error cancelling all alarms: $e');
    }
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

    // If alarm time has passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // For repeating alarms, find next matching day
    if (alarm.repeatDays.isNotEmpty) {
      final currentWeekday = now.weekday; // 1=Monday, 7=Sunday
      
      // Find next matching day
      int daysToAdd = 0;
      bool found = false;
      
      for (int i = 0; i < 7; i++) {
        final checkDay = (currentWeekday + i) % 7;
        final checkDayAdjusted = checkDay == 0 ? 7 : checkDay; // Convert 0 to 7 (Sunday)
        
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
