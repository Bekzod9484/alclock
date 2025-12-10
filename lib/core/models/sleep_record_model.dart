import 'package:hive/hive.dart';

part 'sleep_record_model.g.dart';

@HiveType(typeId: 1)
class SleepRecordModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  DateTime? sleepStart;

  @HiveField(3)
  DateTime? wakeTime;

  @HiveField(4)
  int durationMinutes;

  @HiveField(5)
  int score;

  @HiveField(6)
  bool isManual;

  @HiveField(7)
  List<String> warnings;

  SleepRecordModel({
    required this.id,
    required this.date,
    this.sleepStart,
    this.wakeTime,
    this.durationMinutes = 0,
    this.score = 0,
    this.isManual = false,
    this.warnings = const [],
  });

  SleepRecordModel copyWith({
    String? id,
    DateTime? date,
    DateTime? sleepStart,
    DateTime? wakeTime,
    int? durationMinutes,
    int? score,
    bool? isManual,
    List<String>? warnings,
  }) {
    return SleepRecordModel(
      id: id ?? this.id,
      date: date ?? this.date,
      sleepStart: sleepStart ?? this.sleepStart,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      score: score ?? this.score,
      isManual: isManual ?? this.isManual,
      warnings: warnings ?? this.warnings,
    );
  }
}

