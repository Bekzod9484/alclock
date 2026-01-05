import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../core/models/settings_model.dart';
import '../core/models/alarm_sound_model.dart';
import 'hive_service.dart';
import 'quote_service.dart';
import 'alarm_navigation_service.dart';
import 'alarm_kit.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final HiveService _hiveService;
  final QuoteService _quoteService;
  bool _initialized = false;

  NotificationService(this._hiveService) : _quoteService = QuoteService();

  Future<void> initialize() async {
    if (_initialized) return;

    await _quoteService.initialize();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationTap(payload);
        }
      },
    );

    final initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          _handleNotificationTap(details.payload!);
        }
      },
    );

    if (Platform.isIOS) {
      final iosImplementation = _local.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Create alarm notification channel with proper configuration
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'alarm_channel',
          'Alarm Notifications',
          description: 'Notifications for alarm reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          // Note: category and audioAttributesUsage are set in notification details
        ),
      );
    }

    _initialized = true;
  }

  void _handleNotificationTap(String payload) {
    try {
      // Try to parse JSON payload
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final alarmId = data['alarmId'] as String? ?? '';
      final soundName = data['soundName'] as String?;
      if (alarmId.isNotEmpty) {
        print('📱 Notification tapped - opening alarm: $alarmId');
        AlarmNavigationService.openAlarmPage(alarmId, soundName: soundName);
      }
    } catch (e) {
      // Fallback for old format (simple string payload)
      final alarmId = payload;
      if (alarmId.isNotEmpty) {
        print('📱 Notification tapped - opening alarm (fallback): $alarmId');
        AlarmNavigationService.openAlarmPage(alarmId);
      }
    }
  }

  Future<SettingsModel> _getSettings() async {
    return await _hiveService.getSettings();
  }

  Future<String> _getDailyQuote() async {
    return await _quoteService.getDailyQuote();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? alarmId,
    String? soundName,
  }) async {
    if (!_initialized) await initialize();

    final settings = await _getSettings();
    final quote = await _getDailyQuote();

    final scheduled = tz.TZDateTime.from(scheduledDate, tz.local);
    final notificationBody = "$body\n\n$quote";

    final selectedSound = soundName ?? settings.selectedAlarmSound;
    final androidSoundName = AlarmSoundModel.getAndroidSoundName(selectedSound);
    final androidSound = RawResourceAndroidNotificationSound(androidSoundName);

    // iOS sound name - must match bundled sound file
    // iOS notification sounds must be in the app bundle (e.g., ios/Runner/AlarmSounds)
    // Format: 'alarm1.wav', 'alarm2.wav', etc.
    // If sound is not found, iOS will fallback to default notification sound
    final iosSoundName = AlarmSoundModel.getIOSSoundName(selectedSound);

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarm reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      sound: androidSound,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: iosSoundName,
      categoryIdentifier: 'alarmCategory',
    );

    final notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final finalAlarmId = alarmId ?? id.toString();
    final payload = jsonEncode({
      'alarmId': finalAlarmId,
      'soundName': selectedSound,
    });

    await _local.zonedSchedule(
      id,
      title,
      notificationBody,
      scheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required List<int> weekdays,
    String? alarmId,
    String? soundName,
  }) async {
    if (!_initialized) await initialize();

    final settings = await _getSettings();
    final quote = await _getDailyQuote();

    final scheduled = tz.TZDateTime.from(scheduledDate, tz.local);
    final notificationBody = "$body\n\n$quote";

    final selectedSound = soundName ?? settings.selectedAlarmSound;
    final androidSoundName = AlarmSoundModel.getAndroidSoundName(selectedSound);
    final androidSound = RawResourceAndroidNotificationSound(androidSoundName);

    // iOS sound name - must match bundled sound file
    // iOS notification sounds must be in the app bundle (e.g., ios/Runner/AlarmSounds)
    // Format: 'alarm1.wav', 'alarm2.wav', etc.
    // If sound is not found, iOS will fallback to default notification sound
    final iosSoundName = AlarmSoundModel.getIOSSoundName(selectedSound);

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarm reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: settings.vibrationEnabled,
      sound: androidSound,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: iosSoundName,
      categoryIdentifier: 'alarmCategory',
    );

    final notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final finalAlarmId = alarmId ?? id.toString();
    final payload = jsonEncode({
      'alarmId': finalAlarmId,
      'soundName': selectedSound,
    });

    if (weekdays.isNotEmpty) {
      for (final weekday in weekdays) {
        final weekdayId = id + weekday;
        await _local.zonedSchedule(
          weekdayId,
          title,
          notificationBody,
          scheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    } else {
      await _local.zonedSchedule(
        id,
        title,
        notificationBody,
        scheduled,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  Future<void> scheduleSnooze({
    required int id,
    required String alarmId,
    required DateTime scheduledDate,
    String? soundName,
  }) async {
    await scheduleNotification(
      id: id,
      title: 'Alarm (Snooze)',
      body: 'Wake up!',
      scheduledDate: scheduledDate,
      alarmId: alarmId,
      soundName: soundName,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) await initialize();
    await _local.cancel(id);

    for (int weekday = 1; weekday <= 7; weekday++) {
      await _local.cancel(id + weekday);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _local.cancelAll();
  }

  Future<void> showImmediateTest() async {
    if (!_initialized) await initialize();

    const androidSound = RawResourceAndroidNotificationSound('alarm1');
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarm reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      sound: androidSound,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm1.wav',
    );

    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final payload = jsonEncode({
      'alarmId': 'test_alarm',
      'soundName': 'alarm1',
    });

    await _local.show(
      999999,
      'Test Alarm',
      'This is a test notification',
      notificationDetails,
      payload: payload,
    );

    if (Platform.isIOS) {
      AlarmKit.showCallUI(soundName: 'alarm1');
      AlarmNavigationService.openAlarmPage('test_alarm');
    }
  }
}
