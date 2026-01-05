import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hive_service.dart';
import 'screen_state_service.dart';
import 'sleep_detection_service.dart';

/// Automatic sleep tracking service
/// Wraps SleepDetectionService and provides provider integration
class AutomaticSleepTracker {
  final SleepDetectionService _sleepDetectionService;
  
  bool _isTracking = false;
  
  AutomaticSleepTracker(HiveService hiveService, ScreenStateService screenStateService, [Ref? ref])
      : _sleepDetectionService = SleepDetectionService(hiveService, screenStateService);
  
  /// Start automatic sleep tracking
  Future<void> start() async {
    if (_isTracking) return;
    
    _isTracking = true;
    await _sleepDetectionService.startTracking();
    
    print('✅ Automatic sleep tracker started');
  }
  
  /// Stop automatic sleep tracking
  Future<void> stop() async {
    if (!_isTracking) return;
    
    _isTracking = false;
    await _sleepDetectionService.stopTracking();
    
    print('✅ Automatic sleep tracker stopped');
  }
  
  /// Check if tracking is active
  bool get isTracking => _isTracking;
  
  /// Dispose resources
  void dispose() {
    stop();
    _sleepDetectionService.dispose();
  }
}
