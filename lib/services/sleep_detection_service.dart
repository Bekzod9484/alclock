import 'dart:async';
import '../core/models/sleep_record_model.dart';
import '../core/utils/sleep_score_calculator.dart';
import '../core/utils/app_date_utils.dart';
import 'hive_service.dart';
import 'screen_state_service.dart';

/// Automatic Sleep Detection Service
/// Tracks sleep based on screen state events
class SleepDetectionService {
  final HiveService _hiveService;
  final ScreenStateService _screenStateService;
  
  // Tracking window: 22:00 → 12:00 (next day)
  static const int trackingStartHour = 22;
  static const int trackingEndHour = 12;
  
  // Sleep confirmation: screen OFF for at least 2 hours
  static const Duration sleepConfirmationDuration = Duration(hours: 2);
  
  // Short wake: screen ON < 5 minutes (ignore)
  static const Duration shortWakeThreshold = Duration(minutes: 5);
  
  // Real wake: screen ON ≥ 10 minutes
  static const Duration realWakeThreshold = Duration(minutes: 10);
  
  // Stop tracking at 12:00 if no wake detected
  static const int stopTrackingHour = 12;
  
  StreamSubscription<bool>? _screenStateSubscription;
  Timer? _confirmationTimer;
  Timer? _wakeTimer;
  Timer? _dailyResetTimer;
  
  DateTime? _potentialSleepStart;
  DateTime? _confirmedSleepStart;
  DateTime? _screenOnTime;
  bool _isTracking = false;
  bool _isInActiveWindow = false;

  SleepDetectionService(this._hiveService, this._screenStateService);

  /// Start sleep tracking
  Future<void> startTracking() async {
    if (_isTracking) return;
    
    _isTracking = true;
    
    // Initialize screen state service
    await _screenStateService.initialize();
    
    // Listen to screen state changes
    _screenStateSubscription = _screenStateService.screenStateStream.listen(
      _onScreenStateChanged,
      onError: (error) => print('❌ Screen state stream error: $error'),
    );
    
    // Start daily reset timer (check every hour)
    _dailyResetTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkDailyReset();
    });
    
    // Check if we're in active window
    _checkActiveWindow();
    
    print('✅ Sleep detection service started');
  }

  /// Stop sleep tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    
    await _screenStateSubscription?.cancel();
    _screenStateSubscription = null;
    
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    
    _wakeTimer?.cancel();
    _wakeTimer = null;
    
    _dailyResetTimer?.cancel();
    _dailyResetTimer = null;
    
    await _screenStateService.stop();
    
    print('✅ Sleep detection service stopped');
  }

  /// Check if we're in active tracking window (22:00 → 12:00)
  void _checkActiveWindow() {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Active window: 22:00 → 12:00 (next day)
    final inActiveWindow = currentHour >= trackingStartHour || currentHour < trackingEndHour;
    
    if (inActiveWindow != _isInActiveWindow) {
      _isInActiveWindow = inActiveWindow;
      
      if (!_isInActiveWindow) {
        // Outside active window - reset tracking
        _resetTracking();
      }
    }
  }

  /// Handle screen state changes
  void _onScreenStateChanged(bool isScreenOn) {
    if (!_isInActiveWindow) {
      // Outside tracking window - ignore
      return;
    }
    
    final now = DateTime.now();
    
    if (isScreenOn) {
      _onScreenTurnedOn(now);
    } else {
      _onScreenTurnedOff(now);
    }
  }

  /// Handle screen turned OFF
  void _onScreenTurnedOff(DateTime timestamp) {
    final currentHour = timestamp.hour;
    
    // Only track if after 22:00
    if (currentHour < trackingStartHour && currentHour >= trackingEndHour) {
      return; // Outside active window
    }
    
    // If we have a confirmed sleep start, this might be a short wake
    if (_confirmedSleepStart != null) {
      // Screen turned off again - might be going back to sleep
      // Cancel wake timer if it exists
      _wakeTimer?.cancel();
      _wakeTimer = null;
      _screenOnTime = null;
      print('🌙 Screen turned OFF again - continuing sleep');
      return;
    }
    
    // New potential sleep start
    if (_potentialSleepStart == null) {
      _potentialSleepStart = timestamp;
      print('🌙 Potential sleep start: ${_formatTime(timestamp)}');
      
      // Start confirmation timer (2 hours)
      _confirmationTimer?.cancel();
      _confirmationTimer = Timer(sleepConfirmationDuration, () {
        _confirmSleepStart();
      });
    }
  }

  /// Handle screen turned ON
  void _onScreenTurnedOn(DateTime timestamp) {
    final currentHour = timestamp.hour;
    
    // Stop tracking after 12:00
    if (currentHour >= stopTrackingHour) {
      _handleEndOfTrackingWindow(timestamp);
      return;
    }
    
    // If we have a potential sleep start but not confirmed
    if (_potentialSleepStart != null && _confirmedSleepStart == null) {
      // Screen turned on before confirmation
      _screenOnTime = timestamp;
      
      // Start timer to check if this is a long wake (cancel sleep)
      _wakeTimer?.cancel();
      _wakeTimer = Timer(shortWakeThreshold, () {
        // Screen has been ON for 5+ minutes - user did NOT sleep
        _cancelPotentialSleep();
      });
      
      print('📱 Screen turned ON before sleep confirmation');
      return;
    }
    
    // If we have a confirmed sleep start, check for real wake
    if (_confirmedSleepStart != null) {
      _screenOnTime = timestamp;
      
      // Start timer to check if this is a real wake (≥10 minutes)
      _wakeTimer?.cancel();
      _wakeTimer = Timer(realWakeThreshold, () {
        _detectRealWake(timestamp);
      });
      
      print('📱 Screen turned ON - checking for real wake');
    }
  }

  /// Confirm sleep start (screen OFF for 2+ hours)
  void _confirmSleepStart() async {
    if (_potentialSleepStart == null) return;
    
    // Check if screen is still OFF
    final isScreenOn = await _screenStateService.isScreenOn();
    if (isScreenOn) {
      // Screen is ON - don't confirm
      return;
    }
    
    _confirmedSleepStart = _potentialSleepStart;
    _potentialSleepStart = null;
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    
    print('✅ Sleep confirmed: ${_formatTime(_confirmedSleepStart!)}');
    
    // Save sleep start to Hive
    await _saveSleepStart(_confirmedSleepStart!);
  }

  /// Cancel potential sleep (screen ON for 5+ minutes before confirmation)
  void _cancelPotentialSleep() {
    if (_potentialSleepStart == null) return;
    
    print('❌ Sleep cancelled - screen ON for 5+ minutes');
    
    _potentialSleepStart = null;
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _wakeTimer?.cancel();
    _wakeTimer = null;
    _screenOnTime = null;
  }

  /// Detect real wake (screen ON for 10+ minutes)
  void _detectRealWake(DateTime wakeTime) async {
    if (_confirmedSleepStart == null) return;
    
    // Check if screen is still ON
    final isScreenOn = await _screenStateService.isScreenOn();
    if (!isScreenOn) {
      // Screen turned OFF again - not a real wake
      return;
    }
    
    print('✅ Real wake detected: ${_formatTime(wakeTime)}');
    
    // Calculate duration
    final duration = wakeTime.difference(_confirmedSleepStart!);
    
    // Save complete sleep record
    await _saveCompleteSleep(_confirmedSleepStart!, wakeTime, duration);
    
    // Reset tracking
    _resetTracking();
  }

  /// Handle end of tracking window (12:00)
  void _handleEndOfTrackingWindow(DateTime timestamp) async {
    if (_confirmedSleepStart != null && _screenOnTime == null) {
      // Sleep was confirmed but no wake detected - use 12:00 as wake time
      print('⏰ End of tracking window - using 12:00 as wake time');
      
      final wakeTime = DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
        stopTrackingHour,
        0,
      );
      
      final duration = wakeTime.difference(_confirmedSleepStart!);
      await _saveCompleteSleep(_confirmedSleepStart!, wakeTime, duration);
    }
    
    _resetTracking();
  }

  /// Check for daily reset (at 12:00)
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.hour == stopTrackingHour && now.minute == 0) {
      _handleEndOfTrackingWindow(now);
    }
    
    // Check active window
    _checkActiveWindow();
  }

  /// Reset tracking state
  void _resetTracking() {
    _potentialSleepStart = null;
    _confirmedSleepStart = null;
    _screenOnTime = null;
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _wakeTimer?.cancel();
    _wakeTimer = null;
    
    print('🔄 Tracking reset');
  }

  /// Save sleep start to Hive
  Future<void> _saveSleepStart(DateTime sleepStart) async {
    try {
      final date = DateTime(sleepStart.year, sleepStart.month, sleepStart.day);
      final existingRecord = await _hiveService.getSleepRecordByDate(date);
      
      if (existingRecord == null || existingRecord.sleepStart == null) {
        await _hiveService.saveSleepRecord(
          SleepRecordModel(
            id: date.millisecondsSinceEpoch.toString(),
            date: date,
            sleepStart: sleepStart,
            isManual: false,
            durationMinutes: 0,
            score: 0,
            warnings: [],
          ),
        );
        print('💾 Sleep start saved: ${_formatTime(sleepStart)}');
      }
    } catch (e) {
      print('❌ Error saving sleep start: $e');
    }
  }

  /// Save complete sleep record to Hive
  Future<void> _saveCompleteSleep(
    DateTime sleepStart,
    DateTime wakeTime,
    Duration duration,
  ) async {
    try {
      final date = DateTime(sleepStart.year, sleepStart.month, sleepStart.day);
      
      // Handle wake time on next day
      DateTime actualWakeTime = wakeTime;
      if (wakeTime.isBefore(sleepStart)) {
        actualWakeTime = wakeTime.add(const Duration(days: 1));
      }
      
      final durationMinutes = duration.inMinutes;
      
      final record = SleepRecordModel(
        id: date.millisecondsSinceEpoch.toString(),
        date: date,
        sleepStart: sleepStart,
        wakeTime: actualWakeTime,
        durationMinutes: durationMinutes,
        isManual: false,
        score: 0,
        warnings: [],
      );
      
      // Calculate score
      final scoreResult = await SleepScoreCalculator.calculateScore(record);
      
      final finalRecord = record.copyWith(
        score: scoreResult.score,
        warnings: scoreResult.warnings,
      );
      
      await _hiveService.saveSleepRecord(finalRecord);
      
      print('💾 Complete sleep record saved:');
      print('   Sleep: ${_formatTime(sleepStart)}');
      print('   Wake: ${_formatTime(actualWakeTime)}');
      print('   Duration: ${AppDateUtils.formatDurationFromMinutes(durationMinutes)}');
      print('   Score: ${scoreResult.score}');
    } catch (e) {
      print('❌ Error saving complete sleep: $e');
    }
  }

  /// Format time for logging
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
