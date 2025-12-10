import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/sleep_record_model.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../../../core/utils/sleep_score_calculator.dart';
import '../../../../core/utils/weekly_sleep_quality_calculator.dart';
import '../providers/sleep_provider.dart';
import '../widgets/sleep_score_indicator.dart';
import '../widgets/sleep_stats_card.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/weekly_analysis_modal.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  Future<void> _showManualEntryDialog() async {
    DateTime? selectedDate;
    TimeOfDay? sleepStartTime;
    TimeOfDay? wakeTime;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.gradientStart,
          title: Text(
            AppLocalizations.of(context)?.manualSleepEntry ?? 'Manual Sleep Entry',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)?.date ?? 'Date',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    selectedDate != null
                        ? AppDateUtils.formatDate(selectedDate!)
                        : (AppLocalizations.of(context)?.selectDate ?? 'Select date'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.accent),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                // Sleep start time picker
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)?.sleepStart ?? 'Sleep Start',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    sleepStartTime != null
                        ? AppDateUtils.formatTimeOfDay(sleepStartTime!)
                        : (AppLocalizations.of(context)?.selectTime ?? 'Select time'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.bedtime, color: AppColors.accent),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        sleepStartTime = picked;
                      });
                    }
                  },
                ),
                // Wake time picker
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)?.wakeTime ?? 'Wake Time',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    wakeTime != null
                        ? AppDateUtils.formatTimeOfDay(wakeTime!)
                        : (AppLocalizations.of(context)?.selectTime ?? 'Select time'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.wb_sunny, color: AppColors.accent),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        wakeTime = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)?.cancel ?? 'Cancel',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (selectedDate != null && sleepStartTime != null && wakeTime != null) {
                  Navigator.of(context).pop({
                    'date': selectedDate,
                    'sleepStart': sleepStartTime,
                    'wakeTime': wakeTime,
                  });
                }
              },
              child: Text(
                AppLocalizations.of(context)?.save ?? 'Save',
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _saveManualEntry(result);
    }
  }

  Future<void> _saveManualEntry(Map<String, dynamic> data) async {
    try {
      final date = data['date'] as DateTime;
      final sleepStartTime = data['sleepStart'] as TimeOfDay;
      final wakeTime = data['wakeTime'] as TimeOfDay;

      final dateOnly = DateTime(date.year, date.month, date.day);
      final sleepStart = DateTime(
        date.year,
        date.month,
        date.day,
        sleepStartTime.hour,
        sleepStartTime.minute,
      );
      final wake = DateTime(
        date.year,
        date.month,
        date.day,
        wakeTime.hour,
        wakeTime.minute,
      );

      // Handle case where wake time is next day
      DateTime actualWake = wake;
      if (wake.isBefore(sleepStart)) {
        actualWake = wake.add(const Duration(days: 1));
      }

      final duration = actualWake.difference(sleepStart);
      final record = SleepRecordModel(
        id: dateOnly.millisecondsSinceEpoch.toString(),
        date: dateOnly,
        sleepStart: sleepStart,
        wakeTime: actualWake,
        durationMinutes: duration.inMinutes,
        isManual: true,
      );

      // Calculate score and advice
      final scoreResult = await SleepScoreCalculator.calculateScore(record);
      final updatedRecord = record.copyWith(
        score: scoreResult.score,
        warnings: scoreResult.warnings,
      );

      // Save to Hive
      final hiveService = ref.read(initializedHiveServiceProvider);
      await hiveService.saveSleepRecord(updatedRecord);

      // Automatically switch to the week containing the saved record's date
      final weekDateNotifier = ref.read(weekDateProvider.notifier);
      weekDateNotifier.setWeekDate(date);

      // Invalidate provider to refresh
      ref.invalidate(weeklySleepRecordsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.sleepRecordSaved ?? 'Sleep record saved'),
          ),
        );
      }
    } catch (e) {
      print('Error saving manual entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Calculate weekly average sleep time (bedtime)
  /// Converts sleep times to minutes-from-midnight and averages them
  /// Only includes records with actual sleep data (sleepStart, wakeTime, and duration > 0)
  /// If bedtime is past midnight (00:00-06:00), treats it as 24:30 (adds 24 hours) for averaging
  DateTime? _calculateAvgBedtime(List<SleepRecordModel> records) {
    // Filter to only records with actual sleep data
    final validRecords = records.where((r) => 
      r.sleepStart != null && 
      r.wakeTime != null && 
      r.durationMinutes > 0
    ).toList();
    
    if (validRecords.isEmpty) return null;

    int totalMinutes = 0;
    for (var record in validRecords) {
      final sleepStart = record.sleepStart!;
      int minutes = sleepStart.hour * 60 + sleepStart.minute;
      
      // Optional improvement: If bedtime is past midnight (00:00-06:00), 
      // treat it as 24:30 (add 24 hours) for averaging to avoid skew
      // This handles cases where someone sleeps at 00:30, 01:00, etc.
      if (sleepStart.hour >= 0 && sleepStart.hour < 6) {
        // Treat as next day (add 24 hours = 1440 minutes)
        minutes += 1440;
      }
      
      totalMinutes += minutes;
    }

    // Calculate arithmetic mean
    final avgMinutes = (totalMinutes / validRecords.length).round();
    
    // Handle case where average is >= 24 hours (1440 minutes)
    final normalizedMinutes = avgMinutes % 1440;
    
    final avgHour = normalizedMinutes ~/ 60;
    final avgMinute = normalizedMinutes % 60;
    
    return DateTime(2000, 1, 1, avgHour, avgMinute);
  }

  /// Calculate weekly average wake time
  /// Converts wake times to minutes-from-midnight and averages them
  /// Only includes records with actual sleep data (sleepStart, wakeTime, and duration > 0)
  DateTime? _calculateAvgWakeTime(List<SleepRecordModel> records) {
    // Filter to only records with actual sleep data
    final validRecords = records.where((r) => 
      r.sleepStart != null && 
      r.wakeTime != null && 
      r.durationMinutes > 0
    ).toList();
    
    if (validRecords.isEmpty) return null;

    int totalMinutes = 0;
    for (var record in validRecords) {
      final wakeTime = record.wakeTime!;
      // Convert wake time to minutes from midnight
      // Wake times are typically in the morning (06:00-12:00), so no adjustment needed
      totalMinutes += wakeTime.hour * 60 + wakeTime.minute;
    }

    // Calculate arithmetic mean
    final avgMinutes = (totalMinutes / validRecords.length).round();
    
    final avgHour = avgMinutes ~/ 60;
    final avgMinute = avgMinutes % 60;
    
    return DateTime(2000, 1, 1, avgHour, avgMinute);
  }

  /// Calculate weekly sleep quality score using scientifically validated algorithm
  int _calculateWeeklyScore(
    List<SleepRecordModel> weeklyRecords,
    List<SleepRecordModel> allRecords,
  ) {
    return WeeklySleepQualityCalculator.calculateWeeklyQuality(
      weeklyRecords,
      allRecords,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklyRecordsAsync = ref.watch(weeklySleepRecordsProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.statistics ?? 'Statistics',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.textPrimary),
              onPressed: _showManualEntryDialog,
              tooltip: AppLocalizations.of(context)?.addManualEntry ?? 'Add Manual Entry',
            ),
          ],
        ),
        body: weeklyRecordsAsync.when(
          data: (weeklyRecords) {
            // Get all records for accurate averages
            final allRecordsAsync = ref.watch(allSleepRecordsProvider);
            return allRecordsAsync.when(
              data: (allRecords) {
                // Use weeklyRecords for weekly averages (current week's data only)
                final avgBedtime = _calculateAvgBedtime(weeklyRecords);
                final avgWakeTime = _calculateAvgWakeTime(weeklyRecords);
                final weeklyScore = _calculateWeeklyScore(weeklyRecords, allRecords);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekly Score
                  Center(
                    child: SleepScoreIndicator(
                      score: weeklyScore,
                      onTap: () {
                        WeeklyAnalysisModal.show(context, weeklyRecords);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Row 1: Two small cards side-by-side
                  // Left: Average Sleep Time | Right: Average Wake Time
                  Row(
                    children: [
                      Expanded(
                        child: SleepStatsCard(
                          title: AppLocalizations.of(context)?.avgBedtime ?? 'Weekly average sleep time',
                          value: avgBedtime != null
                              ? AppDateUtils.formatTime(avgBedtime)
                              : '--:--',
                          icon: Icons.nightlight,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: SleepStatsCard(
                          title: AppLocalizations.of(context)?.avgWakeTime ?? 'Weekly average wake time',
                          value: avgWakeTime != null
                              ? AppDateUtils.formatTime(avgWakeTime)
                              : '--:--',
                          icon: Icons.wb_sunny,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Row 2: Large card with weekly sleep duration chart (full width)
                  GlassCard(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week navigation and title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)?.weeklySleepDuration ?? 'Weekly sleep duration',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Week navigation buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                                  onPressed: () {
                                    ref.read(weekDateProvider.notifier).goToPreviousWeek();
                                  },
                                  tooltip: 'Previous week',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.today, color: AppColors.textPrimary),
                                  onPressed: () {
                                    ref.read(weekDateProvider.notifier).goToCurrentWeek();
                                  },
                                  tooltip: 'Current week',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                                  onPressed: () {
                                    ref.read(weekDateProvider.notifier).goToNextWeek();
                                  },
                                  tooltip: 'Next week',
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Week range display
                        Builder(
                          builder: (context) {
                            final weekDate = ref.watch(weekDateProvider);
                            final weekDates = AppDateUtils.getWeekDates(weekDate);
                            final monday = weekDates[0];
                            final sunday = weekDates[6];
                            final mondayStr = '${monday.day}/${monday.month}';
                            final sundayStr = '${sunday.day}/${sunday.month}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                              child: Text(
                                '$mondayStr - $sundayStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Builder(
                          builder: (context) {
                            final weekDate = ref.watch(weekDateProvider);
                            final weekDates = AppDateUtils.getWeekDates(weekDate);
                            return WeeklyChart(records: weeklyRecords, weekDates: weekDates);
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Center(
                          child: Text(
                            AppLocalizations.of(context)?.tapBarToSeeDetails ?? 'Tap a bar to see details',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
