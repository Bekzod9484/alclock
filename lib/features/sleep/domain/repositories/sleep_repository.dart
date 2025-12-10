import '../../../../core/models/sleep_record_model.dart';

abstract class SleepRepository {
  Future<SleepRecordModel?> getTodayRecord();
  Future<List<SleepRecordModel>> getWeeklyRecords([DateTime? baseDate]);
  Future<List<SleepRecordModel>> getAllRecords();
  Future<void> saveSleepRecord(SleepRecordModel record);
  Future<void> updateSleepRecord(SleepRecordModel record);
}

