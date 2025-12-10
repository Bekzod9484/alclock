import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/alarm_model.dart';
import '../core/models/sleep_record_model.dart';
import '../core/models/settings_model.dart';
import '../core/utils/app_date_utils.dart';

class HiveService {
  static const String alarmsBoxName = 'alarms_box';
  static const String sleepRecordsBoxName = 'sleep_records_box';
  static const String settingsBoxName = 'settings_box';

  bool _initialized = false;

  Future<void> init() async {
    // Allow re-initialization if there was an error
    if (_initialized && Hive.isBoxOpen(settingsBoxName)) return;
    
    // Reset flag if box is not open (previous init may have failed)
    if (_initialized && !Hive.isBoxOpen(settingsBoxName)) {
      print('⚠️ Previous initialization failed, retrying...');
      _initialized = false;
    }
    
    if (_initialized) return;
    _initialized = true;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AlarmModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SleepRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }

    // Open boxes (awaits are required)
    await Hive.openBox<AlarmModel>(alarmsBoxName);
    await Hive.openBox<SleepRecordModel>(sleepRecordsBoxName);
    
    // Open settings box with error handling for corrupted data
    Box<SettingsModel> settingsBox;
    try {
      settingsBox = await Hive.openBox<SettingsModel>(settingsBoxName);
    } catch (e) {
      // Error during box opening - likely corrupted data with null values
      // This is expected and will be fixed automatically
      print('🔧 Settings box needs repair. Fixing automatically...');
      
      // If box is corrupted, close it first (if open), then delete and recreate
      try {
        // Try to close the box if it's already open
        if (Hive.isBoxOpen(settingsBoxName)) {
          try {
            final openBox = Hive.box<SettingsModel>(settingsBoxName);
            await openBox.close();
          } catch (closeError) {
            // Ignore close errors - box may already be closed
          }
        }
      } catch (checkError) {
        // Ignore check errors
      }
      
      // Delete the corrupted box
      try {
        await Hive.deleteBoxFromDisk(settingsBoxName);
        // Small delay to ensure file system operations complete
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (deleteError) {
        // Continue anyway - might still be able to open a new box
      }
      
      // Reopen the box (should create a new empty box)
      try {
        settingsBox = await Hive.openBox<SettingsModel>(settingsBoxName);
        print('✅ Settings box repaired successfully');
      } catch (reopenError) {
        print('❌ Critical: Failed to reopen settings box: $reopenError');
        // Last resort: try to open with a different name or throw
        rethrow;
      }
    }

    // Default settings or migrate old settings
    await _initializeOrMigrateSettings(settingsBox);
  }

  /// Initialize or migrate settings with null-safe logic
  Future<void> _initializeOrMigrateSettings(Box<SettingsModel> settingsBox) async {
    try {
      // Check if settings key exists
      if (!settingsBox.containsKey('settings')) {
        // No settings exist, create default
        await settingsBox.put('settings', SettingsModel(languageCode: 'uz'));
        print('✅ Created default settings with languageCode: uz');
        return;
      }

      // Settings exist, try to get and migrate
      final existingSettings = settingsBox.get('settings');
      
      if (existingSettings == null) {
        // Key exists but value is null, create new default
        await settingsBox.put('settings', SettingsModel(languageCode: 'uz'));
        print('✅ Replaced null settings with default');
        return;
      }

      // Check if languageCode is empty or invalid
      // Note: languageCode is non-nullable String, but old data might have empty string
      final langCode = existingSettings.languageCode;
      
      // Handle empty or invalid languageCode
      if (langCode.isEmpty || 
          (langCode != 'uz' && langCode != 'ru' && langCode != 'en')) {
        // Migrate to include valid languageCode
        final migratedSettings = existingSettings.copyWith(languageCode: 'uz');
        await settingsBox.put('settings', migratedSettings);
        print('✅ Migrated settings to include languageCode: uz');
      } else {
        print('✅ Settings already have valid languageCode: $langCode');
      }
    } catch (e, stackTrace) {
      print('❌ Error in settings migration: $e');
      print('Stack trace: $stackTrace');
      // If migration fails completely, create new default settings
      try {
        await settingsBox.put('settings', SettingsModel(languageCode: 'uz'));
        print('✅ Created new default settings after migration error');
      } catch (putError) {
        print('❌ Critical: Failed to create default settings: $putError');
        rethrow; // Re-throw if we can't even create default settings
      }
    }
  }

  // -----------------------------
  // ALARM METHODS
  // -----------------------------

  Future<List<AlarmModel>> getAllAlarms() async {
    try {
      final box = Hive.box<AlarmModel>(alarmsBoxName);
      final alarms = <AlarmModel>[];
      
      // Safely read all alarms with error handling for corrupted data
      for (var key in box.keys) {
        try {
          final alarm = box.get(key);
          if (alarm != null) {
            // Ensure all fields are valid
            alarms.add(_validateAndFixAlarm(alarm));
          }
        } catch (e) {
          print('⚠️ Error reading alarm $key: $e');
          // Skip corrupted alarms
          continue;
        }
      }
      
      return alarms;
    } catch (e) {
      print('❌ Error getting all alarms: $e');
      return [];
    }
  }

  /// Validate and fix alarm data to ensure all fields are valid
  AlarmModel _validateAndFixAlarm(AlarmModel alarm) {
    return AlarmModel(
      id: alarm.id.isNotEmpty ? alarm.id : DateTime.now().millisecondsSinceEpoch.toString(),
      time: alarm.time,
      isEnabled: alarm.isEnabled,
      repeatDays: alarm.repeatDays.isNotEmpty ? alarm.repeatDays : const [],
      soundName: alarm.soundName?.isNotEmpty == true ? alarm.soundName : 'alarm1',
      isVibrationEnabled: alarm.isVibrationEnabled,
      volume: alarm.volume.clamp(0.0, 1.0),
      isActive: alarm.isActive,
      note: alarm.note,
    );
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    try {
      // Validate alarm before saving
      final validatedAlarm = _validateAndFixAlarm(alarm);
      final box = Hive.box<AlarmModel>(alarmsBoxName);
      await box.put(validatedAlarm.id, validatedAlarm);
    } catch (e) {
      print('❌ Error saving alarm: $e');
      rethrow;
    }
  }

  Future<void> deleteAlarm(String id) async {
    final box = Hive.box<AlarmModel>(alarmsBoxName);
    await box.delete(id);
  }

  // -----------------------------
  // SLEEP RECORDS
  // -----------------------------

  Future<void> saveSleepRecord(SleepRecordModel record) async {
    final box = Hive.box<SleepRecordModel>(sleepRecordsBoxName);
    await box.put(record.id, record);
  }

  Future<SleepRecordModel?> getSleepRecordByDate(DateTime date) async {
    final box = Hive.box<SleepRecordModel>(sleepRecordsBoxName);
    final target = DateTime(date.year, date.month, date.day);

    for (var r in box.values) {
      final rd = DateTime(r.date.year, r.date.month, r.date.day);
      if (rd.isAtSameMomentAs(target)) {
        return r;
      }
    }
    return null;
  }

  Future<List<SleepRecordModel>> getWeeklySleepRecords([DateTime? baseDate]) async {
    final referenceDate = baseDate ?? DateTime.now();
    final weekDates = AppDateUtils.getWeekDates(referenceDate);

    final result = <SleepRecordModel>[];

    for (var d in weekDates) {
      final r = await getSleepRecordByDate(d);
      result.add(
        r ??
            SleepRecordModel(
              id: d.millisecondsSinceEpoch.toString(),
              date: d,
            ),
      );
    }
    return result;
  }

  Future<List<SleepRecordModel>> getAllSleepRecords() async {
    final box = Hive.box<SleepRecordModel>(sleepRecordsBoxName);
    return box.values.toList();
  }

  // -----------------------------
  // SETTINGS
  // -----------------------------

  Future<SettingsModel> getSettings() async {
    try {
      // Ensure box is open before accessing
      if (!Hive.isBoxOpen(settingsBoxName)) {
        print('⚠️ Settings box not open, initializing...');
        await init();
      }
      
      final box = Hive.box<SettingsModel>(settingsBoxName);
      final settings = box.get('settings');
      
      // If settings is null or has invalid languageCode, return default
      if (settings == null) {
        print('⚠️ Settings not found, creating default...');
        final defaultSettings = SettingsModel(languageCode: 'uz');
        await saveSettings(defaultSettings);
        return defaultSettings;
      }
      
      // Ensure languageCode is valid
      // Note: languageCode is non-nullable, but old data might have empty string
      final langCode = settings.languageCode;
      if (langCode.isEmpty || 
          (langCode != 'uz' && langCode != 'ru' && langCode != 'en')) {
        print('⚠️ Invalid languageCode in settings, fixing...');
        final fixedSettings = settings.copyWith(languageCode: 'uz');
        await saveSettings(fixedSettings);
        return fixedSettings;
      }
      
      return settings;
    } catch (e, stackTrace) {
      print('❌ Error getting settings: $e');
      print('Stack trace: $stackTrace');
      // Return safe default if anything goes wrong
      return SettingsModel(languageCode: 'uz');
    }
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final box = Hive.box<SettingsModel>(settingsBoxName);
    await box.put('settings', settings);
  }
}