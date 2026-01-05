import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/hive_service.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'services/screen_state_service.dart';
import 'services/sleep_detection_service.dart';
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

Future<void> main() async {
  runZonedGuarded(
    () async {
      // Barcha ishlar bitta zone ichida
      WidgetsFlutterBinding.ensureInitialized();

      // Global Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('❌ Flutter Error: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      };

      try {
        // 1. HiveService init
        final hiveService = HiveService();
        await hiveService.init();
        debugPrint('✅ HiveService initialized');

        // 2. ScreenStateService init
        final screenStateService = ScreenStateService();
        await screenStateService.initialize();
        debugPrint('✅ ScreenStateService initialized');

        NotificationService? notificationService;
        AlarmService? alarmService;
        SleepDetectionService? sleepDetectionService;

        // 3. NotificationService init (faqat real device)
        if (!isSimulator) {
          debugPrint('📱 Running on REAL DEVICE → Initializing services');

          notificationService = NotificationService(hiveService);
          await notificationService.initialize();
          debugPrint('✅ NotificationService initialized');
          // NOTE: NotificationService.initialize() already sets up notification tap handling
          // When user taps notification on iOS, it will navigate to alarm ring page via AlarmNavigationService

          // 4. AlarmService init (uses real AlarmManager, not notification service)
          alarmService = AlarmService(hiveService);
          await alarmService.initialize();
          debugPrint('✅ AlarmService initialized (using real AlarmManager)');

          // 5. SleepDetectionService start (faqat real device)
          sleepDetectionService = SleepDetectionService(
            hiveService,
            screenStateService,
          );
          await sleepDetectionService.startTracking();
          debugPrint('✅ SleepDetectionService started');

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
                debugPrint('📱 iOS requested openAlarm: ${call.arguments}');
              }
            } catch (e) {
              debugPrint('❌ Error in method channel: $e');
            }
          });
        } else {
          // SIMULATOR MODE
          debugPrint('🖥 Running on SIMULATOR → Services DISABLED');
        }

        // 6. RUN APP with initialized services
        runApp(
          ProviderScope(
            overrides: [hiveServiceProvider.overrideWithValue(hiveService)],
            child: const App(),
          ),
        );
      } catch (e, stack) {
        debugPrint('❌ Critical initialization error: $e');
        debugPrint(stack.toString());

        // Error case - show error screen
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
                ? [hiveServiceProvider.overrideWithValue(errorHiveService)]
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    },
    (error, stack) {
      debugPrint('❌ GLOBAL ERROR: $error');
      debugPrint(stack.toString());
    },
  );
}
