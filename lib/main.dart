import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/hive_service.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'core/providers/shared_providers.dart';

/// Simulator aniqlash
bool get isSimulator {
  try {
    if (Platform.isIOS &&
        Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
      return true;
    }
  } catch (_) {}
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('❌ Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  runZonedGuarded(() async {
    try {
      // 1) HIVE INIT — har doim ishlaydi
      final hiveService = HiveService();
      await hiveService.init();

      NotificationService? notificationService;
      AlarmService? alarmService;

      // 2️⃣ SIMULATORDA QOTADIGAN JOYLAR → SKIP
      if (!isSimulator) {
        print('📱 Running on REAL DEVICE → Notifications & Alarms enabled');

        // Notifications
        notificationService = NotificationService(hiveService);
        await notificationService.initialize();

        // Alarms
        alarmService = AlarmService(hiveService, notificationService);
        await alarmService.initialize();

        // Method channel — faqat real device
        const MethodChannel channel = MethodChannel('alclock/alarm_actions');
        channel.setMethodCallHandler((call) async {
          try {
            if (call.method == 'snooze') {
              final alarmId = call.arguments as String? ?? '';
              await alarmService?.scheduleSnooze(alarmId);
            } else if (call.method == 'stop') {
              final alarmId = call.arguments as String? ?? '';
              await alarmService?.stopAlarm(alarmId);
            } else if (call.method == 'openAlarm') {
              print('📱 iOS requested openAlarm: ${call.arguments}');
            }
          } catch (e) {
            print('❌ Error in method channel: $e');
          }
        });
      } else {
        // SIMULATOR MODE
        print('🖥 Running on SIMULATOR → Notifications & Alarms DISABLED');
      }

      // RUN APP with initialized HiveService
      // Override hiveServiceProvider with the initialized instance
      runApp(
        ProviderScope(
          overrides: [
            hiveServiceProvider.overrideWithValue(hiveService),
          ],
          child: App(),
        ),
      );
    } catch (e, stack) {
      print('❌ Critical initialization error: $e');
      print(stack);

      // Even in error case, try to create a basic HiveService for the error screen
      // This prevents provider errors when showing the error screen
      HiveService? errorHiveService;
      try {
        errorHiveService = HiveService();
        // Don't await init - just create instance for provider override
      } catch (_) {
        // If even creating HiveService fails, we'll handle it
      }

      runApp(
        ProviderScope(
          overrides: errorHiveService != null
              ? [
                  hiveServiceProvider.overrideWithValue(errorHiveService),
                ]
              : [],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Ilova yuklanishda xatolik yuz berdi',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    print('❌ Uncaught zone error: $error');
    print(stack);
  });
}
