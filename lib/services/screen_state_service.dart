import 'dart:async';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter/services.dart';

/// Screen State Service - Monitors screen ON/OFF state
class ScreenStateService {
  static const MethodChannel _channel = MethodChannel('alclock/screen_state');
  
  StreamController<bool>? _screenStateController;
  Stream<bool>? _screenStateStream;
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  bool _lastScreenState = true; // Assume screen is ON by default

  /// Get stream of screen state changes
  Stream<bool> get screenStateStream {
    _screenStateController ??= StreamController<bool>.broadcast();
    _screenStateStream ??= _screenStateController!.stream;
    return _screenStateStream!;
  }

  /// Initialize screen state monitoring
  Future<void> initialize() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _screenStateController ??= StreamController<bool>.broadcast();
    
    // Start periodic monitoring
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkScreenState();
    });
    
    // Initial check
    await _checkScreenState();
    
    print('✅ Screen state service initialized');
  }

  /// Check current screen state
  Future<void> _checkScreenState() async {
    try {
      final brightness = await ScreenBrightness().current;
      final isScreenOn = brightness > 0.01;
      
      if (isScreenOn != _lastScreenState) {
        _lastScreenState = isScreenOn;
        _screenStateController?.add(isScreenOn);
        print('📱 Screen state changed: ${isScreenOn ? "ON" : "OFF"}');
      }
    } catch (e) {
      print('❌ Error checking screen state: $e');
      // Try platform channel as fallback
      try {
        final result = await _channel.invokeMethod<bool>('isScreenOn');
        if (result != null && result != _lastScreenState) {
          _lastScreenState = result;
          _screenStateController?.add(result);
        }
      } catch (e2) {
        print('❌ Error with platform channel: $e2');
      }
    }
  }

  /// Get current screen state
  Future<bool> isScreenOn() async {
    try {
      final brightness = await ScreenBrightness().current;
      return brightness > 0.01;
    } catch (e) {
      try {
        final result = await _channel.invokeMethod<bool>('isScreenOn');
        return result ?? true;
      } catch (e2) {
        print('❌ Error getting screen state: $e2');
        return true; // Default to ON
      }
    }
  }

  /// Stop monitoring
  Future<void> stop() async {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    await _screenStateController?.close();
    _screenStateController = null;
    _screenStateStream = null;
    print('✅ Screen state service stopped');
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}
