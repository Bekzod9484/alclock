import '../../../../core/models/sleep_record_model.dart';
import '../../../../services/hive_service.dart';
import '../../domain/repositories/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  final HiveService _hiveService;

  SleepRepositoryImpl(this._hiveService);

  @override
  Future<SleepRecordModel?> getTodayRecord() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return await _hiveService.getSleepRecordByDate(todayDate);
  }

  @override
  Future<List<SleepRecordModel>> getWeeklyRecords([DateTime? baseDate]) async {
    return await _hiveService.getWeeklySleepRecords(baseDate);
  }

  @override
  Future<List<SleepRecordModel>> getAllRecords() async {
    return await _hiveService.getAllSleepRecords();
  }

  @override
  Future<void> saveSleepRecord(SleepRecordModel record) async {
    await _hiveService.saveSleepRecord(record);
  }

  @override
  Future<void> updateSleepRecord(SleepRecordModel record) async {
    await _hiveService.saveSleepRecord(record);
  }
}

