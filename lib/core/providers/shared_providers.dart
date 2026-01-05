import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/hive_service.dart';
import '../../services/alarm_service.dart';
import '../../services/notification_service.dart';
import '../../services/quote_service.dart';
import '../../services/screen_state_service.dart';
import '../../services/automatic_sleep_tracker.dart';

/// Hive Service (singleton) - initialized instance from main.dart
/// This provider must be overridden in main.dart with the initialized instance
final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError(
    'HiveService provider must be overridden in main.dart with initialized instance',
  );
});

/// Helper alias for clarity - use this in all providers
final initializedHiveServiceProvider = hiveServiceProvider;

/// Quote Service (singleton)
final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService();
});

/// Notification Service (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final hive = ref.watch(initializedHiveServiceProvider);
  return NotificationService(hive);
});

/// Alarm Service (singleton) - platform-aware
/// - Android: Uses REAL AlarmManager
/// - iOS: Uses NotificationService
final alarmServiceProvider = Provider<AlarmService>((ref) {
  final hive = ref.watch(initializedHiveServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AlarmService(hive, notificationService);
});

/// Screen State Service (singleton)
final screenStateServiceProvider = Provider<ScreenStateService>((ref) {
  return ScreenStateService();
});

/// Automatic Sleep Tracker (singleton)
final automaticSleepTrackerProvider = Provider<AutomaticSleepTracker>((ref) {
  final hive = ref.watch(initializedHiveServiceProvider);
  final screenState = ref.watch(screenStateServiceProvider);
  final tracker = AutomaticSleepTracker(hive, screenState, ref);
  return tracker;
});
