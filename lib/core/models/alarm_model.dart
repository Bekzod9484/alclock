import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime time;

  @HiveField(2)
  bool isEnabled;

  @HiveField(3)
  List<int> repeatDays; // 1–7 (Mon–Sun)

  @HiveField(4)
  String? soundName;

  @HiveField(5)
  bool isVibrationEnabled;

  @HiveField(6)
  double volume;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  String? note;

  @HiveField(9)
  bool mathLockEnabled; // PLAN HARD mode - requires math equation to stop alarm

  AlarmModel({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.repeatDays = const [],
      this.soundName = 'alarm1', // Default custom alarm sound
    this.isVibrationEnabled = true,
    this.volume = 0.8,
    this.isActive = true,
    this.note,
    this.mathLockEnabled = false, // Default: PLAN HARD is OFF
  });

  AlarmModel copyWith({
    String? id,
    DateTime? time,
    bool? isEnabled,
    List<int>? repeatDays,
    String? soundName,
    bool? isVibrationEnabled,
    double? volume,
    bool? isActive,
    String? note,
    bool? mathLockEnabled,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      soundName: soundName ?? this.soundName,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      volume: volume ?? this.volume,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      mathLockEnabled: mathLockEnabled ?? this.mathLockEnabled,
    );
  }
}