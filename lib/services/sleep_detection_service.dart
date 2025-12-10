import 'dart:async';
import 'package:screen_brightness/screen_brightness.dart';
import '../core/models/sleep_record_model.dart';
import '../core/utils/sleep_score_calculator.dart';
import 'hive_service.dart';

class SleepDetectionService {
  final HiveService _hiveService;
  Timer? _monitoringTimer;
  DateTime? _possibleSleepStart;
  bool _isMonitoring = false;
  bool _screenWasOff = false;

  SleepDetectionService(this._hiveService);

  // Monitoring window: 22:00 - 03:00
  static const int sleepMonitoringStartHour = 22;
  static const int sleepMonitoringEndHour = 3;
  
  // Wake window: 05:00 - 12:00
  static const int wakeWindowStartHour = 5;
  static const int wakeWindowEndHour = 12;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final now = DateTime.now();
      final currentHour = now.hour;

      // Check if we're in sleep monitoring window (22:00 - 03:00)
      final inSleepWindow = currentHour >= sleepMonitoringStartHour || 
                           currentHour < sleepMonitoringEndHour;

      if (inSleepWindow && _possibleSleepStart == null) {
        // Check if screen is off
        try {
          final brightness = await ScreenBrightness().current;
          if (brightness < 0.01 && !_screenWasOff) {
            _screenWasOff = true;
            _possibleSleepStart = now;
          } else if (brightness > 0.01 && _screenWasOff) {
            // Screen turned on, discard possible sleep start
            _possibleSleepStart = null;
            _screenWasOff = false;
          }
        } catch (e) {
          // Handle error
        }
      }

      // Check if screen has been off for 3 hours
      if (_possibleSleepStart != null) {
        final timeSincePossibleStart = now.difference(_possibleSleepStart!);
        if (timeSincePossibleStart.inHours >= 3) {
          // Confirm sleep start
          await _confirmSleepStart(_possibleSleepStart!);
          _possibleSleepStart = null;
        }
      }

      // Check wake time window (05:00 - 12:00)
      final inWakeWindow = currentHour >= wakeWindowStartHour && 
                          currentHour < wakeWindowEndHour;
      
      if (inWakeWindow) {
        try {
          final brightness = await ScreenBrightness().current;
          if (brightness > 0.01) {
            // Screen is on, this is wake time
            await _detectWakeTime(now);
          }
        } catch (e) {
          // Handle error
        }
      }
    });
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  Future<void> _confirmSleepStart(DateTime sleepStart) async {
    final today = DateTime(sleepStart.year, sleepStart.month, sleepStart.day);
    final existingRecord = await _hiveService.getSleepRecordByDate(today);
    
    if (existingRecord == null || existingRecord.sleepStart == null) {
      await _hiveService.saveSleepRecord(
        SleepRecordModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: today,
          sleepStart: sleepStart,
          isManual: false,
        ),
      );
    }
  }

  Future<void> _detectWakeTime(DateTime wakeTime) async {
    final today = DateTime(wakeTime.year, wakeTime.month, wakeTime.day);
    final record = await _hiveService.getSleepRecordByDate(today);
    
    if (record != null && record.wakeTime == null && record.sleepStart != null) {
      // Use the record's date for wake time
      final recordDate = record.date;
      final wakeOnSameDate = DateTime(
        recordDate.year,
        recordDate.month,
        recordDate.day,
        wakeTime.hour,
        wakeTime.minute,
      );
      
      // Handle case where wake time is next day
      DateTime actualWakeTime = wakeOnSameDate;
      if (wakeOnSameDate.isBefore(record.sleepStart!)) {
        actualWakeTime = wakeOnSameDate.add(const Duration(days: 1));
      }
      
      final duration = actualWakeTime.difference(record.sleepStart!);
      
      // Update record with wake time and duration
      final updatedRecord = record.copyWith(
        wakeTime: actualWakeTime,
        durationMinutes: duration.inMinutes,
      );
      
      // Calculate score and advice
      final scoreResult = await SleepScoreCalculator.calculateScore(updatedRecord);

      await _hiveService.saveSleepRecord(
        updatedRecord.copyWith(
          score: scoreResult.score,
          warnings: scoreResult.warnings,
        ),
      );
    }
  }

  Future<SleepRecordModel?> getTodayRecord() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return await _hiveService.getSleepRecordByDate(todayDate);
  }

  Future<List<SleepRecordModel>> getWeeklyRecords() async {
    return await _hiveService.getWeeklySleepRecords();
  }
}

