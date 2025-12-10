import '../../../../core/models/alarm_model.dart';

abstract class AlarmRepository {
  /// Get all alarms from storage
  Future<List<AlarmModel>> getAllAlarms();
  
  /// Save alarm to storage (fast, synchronous-like)
  Future<void> saveAlarm(AlarmModel alarm);
  
  /// Delete alarm from storage
  Future<void> deleteAlarm(String id);
  
  /// Schedule alarm (non-blocking, background)
  void scheduleAlarm(AlarmModel alarm);
  
  /// Cancel alarm (non-blocking, background)
  void cancelAlarm(String id);
}
