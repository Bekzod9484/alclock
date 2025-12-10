import 'package:flutter/services.dart';

/// CallKit wrapper for iOS full-screen alarm UI
class AlarmKit {
  static const MethodChannel _channel = MethodChannel('alarm_channel');

  /// Shows the full-screen CallKit incoming call UI
  static Future<void> showCallUI({required String soundName}) async {
    try {
      await _channel.invokeMethod('triggerCallKitAlarm', {
        'soundName': soundName,
      });
      print('✅ CallKit alarm UI triggered with sound: $soundName');
    } catch (e) {
      print('❌ Error triggering CallKit alarm: $e');
    }
  }
}
