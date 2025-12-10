class AlarmSoundModel {
  final String id;
  final String title;
  final String assetPath;

  const AlarmSoundModel({
    required this.id,
    required this.title,
    required this.assetPath,
  });

  static const List<AlarmSoundModel> availableSounds = [
    AlarmSoundModel(
      id: 'alarm1',
      title: 'Sunrise Bell',
      assetPath: 'assets/sounds/alarm1.wav',
    ),
    AlarmSoundModel(
      id: 'alarm2',
      title: 'Digital Alarm',
      assetPath: 'assets/sounds/alarm2.wav',
    ),
    AlarmSoundModel(
      id: 'alarm3',
      title: 'Soft Piano',
      assetPath: 'assets/sounds/alarm3.wav',
    ),
    AlarmSoundModel(
      id: 'alarm4',
      title: 'Bird Morning',
      assetPath: 'assets/sounds/alarm4.wav',
    ),
    AlarmSoundModel(
      id: 'alarm5',
      title: 'Ocean Waves',
      assetPath: 'assets/sounds/alarm5.wav',
    ),
  ];

  static AlarmSoundModel? getById(String id) {
    try {
      return availableSounds.firstWhere((sound) => sound.id == id);
    } catch (e) {
      return null;
    }
  }

  static String getTitleById(String id) {
    return getById(id)?.title ?? id;
  }

  /// Get asset path for a sound ID (for Flutter asset playback)
  static String getAssetPathById(String id) {
    return getById(id)?.assetPath ?? 'assets/sounds/alarm1.wav';
  }

  /// Get iOS sound file name for notifications (with extension)
  /// iOS notification sounds must be in the app bundle (e.g., ios/Runner/AlarmSounds)
  /// Format: 'alarm1.wav'
  static String getIOSSoundName(String id) {
    // Return the file name with extension for iOS notifications
    // iOS expects: 'alarm1.wav'
    return '$id.wav';
  }

  /// Get Android raw resource name (without extension)
  /// Android uses .mp3 files in res/raw/
  static String getAndroidSoundName(String id) {
    // Android uses .mp3 files in res/raw/
    // Map sound IDs to Android resource names (alarm1 -> alarm1)
    return id;
  }
}
