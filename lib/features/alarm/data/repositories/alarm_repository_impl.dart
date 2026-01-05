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
    print('🔔 [AlarmRepository] scheduleAlarm called: id=${alarm.id}, enabled=${alarm.isEnabled}, active=${alarm.isActive}');
    
    // Schedule in background - non-blocking
    unawaited(Future.microtask(() async {
      try {
        if (alarm.isEnabled && alarm.isActive) {
          print('🔔 [AlarmRepository] Alarm is enabled and active, scheduling...');
          await _alarmService.scheduleAlarm(alarm);
          print('✅ [AlarmRepository] Alarm scheduled successfully');
        } else {
          print('🔔 [AlarmRepository] Alarm is disabled or inactive, cancelling...');
          await _alarmService.cancelAlarmById(alarm.id);
          print('✅ [AlarmRepository] Alarm cancelled successfully');
        }
      } catch (e, stackTrace) {
        print('❌ [AlarmRepository] Error in scheduleAlarm: $e');
        print('❌ [AlarmRepository] Stack trace: $stackTrace');
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
