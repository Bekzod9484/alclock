import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/alarm_sound_model.dart';

/// Provider that lists available alarm sounds
/// These correspond to:
/// - assets/alarms/<soundname>.mp3 (for Flutter assets - preview only)
/// - android/app/src/main/res/raw/<soundname>.mp3 (for Android)
/// - ios/Runner/AlarmSounds/<soundname>.wav (for iOS)
final alarmSoundsProvider = Provider<List<AlarmSoundModel>>((ref) {
  return AlarmSoundModel.availableSounds;
});

