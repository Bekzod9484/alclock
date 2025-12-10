import 'package:flutter/material.dart';
import '../features/alarm/presentation/pages/alarm_ring_page.dart';

/// Global navigation service for opening alarm pages from notifications
class AlarmNavigationService {
  /// Global navigator key for navigation from anywhere in the app
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Opens the alarm ring page full-screen
  /// This is called automatically when an alarm notification is received
  static void openAlarmPage(String alarmId, {String? soundName}) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      print('⚠️ Navigator key is not ready yet. Alarm page will not open.');
      return;
    }

    // Check if alarm page is already open to avoid duplicates
    final context = navigator.context;
    final modalRoute = ModalRoute.of(context);
    if (modalRoute?.isCurrent == true && 
        modalRoute?.settings.name?.contains('AlarmRingPage') == true) {
      print('ℹ️ Alarm page is already open. Skipping navigation.');
      return;
    }

    print('🔔 Opening alarm ring page for alarm: $alarmId');
    
    navigator.push(
      MaterialPageRoute(
        builder: (context) => AlarmRingPage(
          alarmId: alarmId,
          soundName: soundName,
        ),
        fullscreenDialog: true, // Full-screen modal
      ),
    );
  }
}

