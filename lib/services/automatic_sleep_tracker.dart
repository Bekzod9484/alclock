import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hive_service.dart';
import 'screen_state_service.dart';

/// Automatic sleep tracking service
/// NOTE: Screen state monitoring has been removed, so this service is now disabled
class AutomaticSleepTracker {
  final HiveService _hiveService;
  final ScreenStateService _screenStateService;
  Ref? _ref;
  
  bool _isTracking = false;
  
  AutomaticSleepTracker(this._hiveService, this._screenStateService, [this._ref]);
  
  /// Set ref for provider invalidation
  void setRef(Ref ref) {
    _ref = ref;
  }
  
  /// Start automatic sleep tracking (disabled - screen state monitoring removed)
  Future<void> start() async {
    if (_isTracking) return;
    
    _isTracking = true;
    
    // Screen state monitoring has been removed
    // This service is kept for compatibility but does not track sleep
    print('⚠️ Automatic sleep tracking is disabled (screen state monitoring removed)');
  }
  
  /// Stop automatic sleep tracking
  Future<void> stop() async {
    _isTracking = false;
    print('✅ Automatic sleep tracking stopped');
  }
}
