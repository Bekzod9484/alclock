/// Screen State Service - DEPRECATED
/// This service is no longer used as we removed screen state monitoring.
/// Kept for compatibility but all method channel calls are disabled.
class ScreenStateService {
  /// Initialize screen state monitoring (disabled)
  Future<void> initialize() async {
    // No-op - screen state monitoring removed
    print('⚠️ Screen state service is deprecated and disabled');
  }
  
  /// Stop monitoring screen state (disabled)
  Future<void> stop() async {
    // No-op - screen state monitoring removed
  }
  
  /// Set callback for screen state changes (disabled)
  void setScreenStateListener(Function(bool isScreenOn) callback) {
    // No-op - screen state monitoring removed
  }
  
  /// Get current screen state (disabled)
  Future<bool> isScreenOn() async {
    // Always return true as default
    return true;
  }
}
