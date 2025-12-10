import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/sleep_record_model.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../data/repositories/sleep_repository_impl.dart';
import '../../domain/repositories/sleep_repository.dart';

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final hiveService = ref.watch(initializedHiveServiceProvider);
  return SleepRepositoryImpl(hiveService);
});

final todaySleepRecordProvider = FutureProvider<SleepRecordModel?>((ref) async {
  final repository = ref.watch(sleepRepositoryProvider);
  return await repository.getTodayRecord();
});

/// StateNotifier to manage the current week date for statistics
class WeekDateNotifier extends StateNotifier<DateTime> {
  WeekDateNotifier() : super(DateTime.now());

  void setWeekDate(DateTime date) {
    state = date;
  }

  void goToPreviousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void goToNextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void goToCurrentWeek() {
    state = DateTime.now();
  }
}

final weekDateProvider = StateNotifierProvider<WeekDateNotifier, DateTime>((ref) {
  return WeekDateNotifier();
});

final weeklySleepRecordsProvider = FutureProvider<List<SleepRecordModel>>((ref) async {
  final repository = ref.watch(sleepRepositoryProvider);
  final weekDate = ref.watch(weekDateProvider);
  return await repository.getWeeklyRecords(weekDate);
});

final allSleepRecordsProvider = FutureProvider<List<SleepRecordModel>>((ref) async {
  final repository = ref.watch(sleepRepositoryProvider);
  return await repository.getAllRecords();
});

