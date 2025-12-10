import 'dart:async';
import '../../../../core/models/alarm_model.dart';
import '../../../../services/alarm_service.dart';
import '../../../../services/hive_service.dart';
import '../../domain/repositories/alarm_repository.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final HiveService _hiveService;
  final AlarmService _alarmService;

  AlarmRepositoryImpl(this._hiveService, this._alarmService);

  @override
  Future<List<AlarmModel>> getAllAlarms() async {
    return await _hiveService.getAllAlarms();
  }

  @override
  Future<void> saveAlarm(AlarmModel alarm) async {
    // Only save to Hive - fast operation
    await _hiveService.saveAlarm(alarm);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    // Delete from Hive - fast operation
    await _hiveService.deleteAlarm(id);
  }

  @override
  void scheduleAlarm(AlarmModel alarm) {
    // Schedule in background - non-blocking
    unawaited(Future.microtask(() async {
      if (alarm.isEnabled && alarm.isActive) {
        await _alarmService.scheduleAlarm(alarm);
      } else {
        await _alarmService.cancelAlarmById(alarm.id);
      }
    }));
  }

  @override
  void cancelAlarm(String id) {
    // Cancel in background - non-blocking
    unawaited(Future.microtask(() async {
      await _alarmService.cancelAlarmById(id);
    }));
  }
}
