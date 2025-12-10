import 'package:flutter/services.dart';

/// Handles playing and stopping alarm audio on native platforms
class AlarmPlayer {
  static const MethodChannel _channel = MethodChannel('alclock/alarm_player');

  /// Start playing alarm sound
  static Future<void> startAlarm(String soundName) async {
    try {
      final soundId = soundName; // e.g., 'alarm1', 'alarm2', etc.
      await _channel.invokeMethod('startAlarm', {'soundName': soundId});
      print('✅ Started playing alarm: $soundId');
    } catch (e) {
      print('❌ Error starting alarm: $e');
      rethrow;
    }
  }

  /// Stop playing alarm sound
  static Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
      print('✅ Stopped alarm');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }

  /// Check if alarm is currently playing
  static Future<bool> isPlaying() async {
    try {
      final result = await _channel.invokeMethod('isPlaying');
      return result as bool? ?? false;
    } catch (e) {
      print('❌ Error checking alarm status: $e');
      return false;
    }
  }
}

