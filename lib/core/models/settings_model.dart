import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 2)
class SettingsModel extends HiveObject {
  @HiveField(0)
  String userName;

  @HiveField(1)
  String selectedAlarmSound;

  @HiveField(2)
  int snoozeMinutes;

  @HiveField(4)
  bool vibrationEnabled;

  @HiveField(5)
  double volume;

  @HiveField(6)
  bool autoModeEnabled;

  @HiveField(7)
  bool motivationalTipsEnabled;

  @HiveField(8)
  bool emojiModeEnabled;

  @HiveField(9)
  String languageCode; // 'uz', 'ru', 'en'

  SettingsModel({
    this.userName = 'User',
    this.selectedAlarmSound = 'alarm1', // Default to first custom alarm sound
    this.snoozeMinutes = 5,
    this.vibrationEnabled = true,
    this.volume = 0.8,
    this.autoModeEnabled = true,
    this.motivationalTipsEnabled = true,
    this.emojiModeEnabled = false,
    this.languageCode = 'uz', // Default to Uzbek
  });

  SettingsModel copyWith({
    String? userName,
    String? selectedAlarmSound,
    int? snoozeMinutes,
    bool? vibrationEnabled,
    double? volume,
    bool? autoModeEnabled,
    bool? motivationalTipsEnabled,
    bool? emojiModeEnabled,
    String? languageCode,
  }) {
    return SettingsModel(
      userName: userName ?? this.userName,
      selectedAlarmSound: selectedAlarmSound ?? this.selectedAlarmSound,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      volume: volume ?? this.volume,
      autoModeEnabled: autoModeEnabled ?? this.autoModeEnabled,
      motivationalTipsEnabled: motivationalTipsEnabled ?? this.motivationalTipsEnabled,
      emojiModeEnabled: emojiModeEnabled ?? this.emojiModeEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

