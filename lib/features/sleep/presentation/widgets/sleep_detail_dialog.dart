import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/sleep_record_model.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/shared_providers.dart';
import '../../../../core/utils/sleep_score_calculator.dart';
import '../../../../core/utils/sleep_advice_generator.dart';
import '../providers/sleep_provider.dart';

class SleepDetailDialog extends ConsumerStatefulWidget {
  final SleepRecordModel record;

  const SleepDetailDialog({super.key, required this.record});
  
  @override
  ConsumerState<SleepDetailDialog> createState() => _SleepDetailDialogState();
}

class _SleepDetailDialogState extends ConsumerState<SleepDetailDialog> {
  bool _isEditing = false;
  DateTime? _editedSleepStart;
  DateTime? _editedWakeTime;

  @override
  void initState() {
    super.initState();
    _editedSleepStart = widget.record.sleepStart;
    _editedWakeTime = widget.record.wakeTime;
  }
  
  Future<void> _saveEdits() async {
    if (_editedSleepStart == null || _editedWakeTime == null) return;
    
    try {
      // Use the record's date for both times
      final recordDate = widget.record.date;
      
      // Construct DateTime objects using the record's date and edited times
      final sleepStart = DateTime(
        recordDate.year,
        recordDate.month,
        recordDate.day,
        _editedSleepStart!.hour,
        _editedSleepStart!.minute,
      );
      
      final wake = DateTime(
        recordDate.year,
        recordDate.month,
        recordDate.day,
        _editedWakeTime!.hour,
        _editedWakeTime!.minute,
      );
      
      // Handle case where wake time is next day
      DateTime actualWakeTime = wake;
      if (wake.isBefore(sleepStart)) {
        actualWakeTime = wake.add(const Duration(days: 1));
      }
      
      final duration = actualWakeTime.difference(sleepStart);
      
      final updatedRecord = widget.record.copyWith(
        sleepStart: sleepStart,
        wakeTime: actualWakeTime,
        durationMinutes: duration.inMinutes,
        isManual: true, // Mark as manual since it was edited
      );
      
      // Recalculate score
      final scoreResult = await SleepScoreCalculator.calculateScore(updatedRecord);
      final finalRecord = updatedRecord.copyWith(
        score: scoreResult.score,
        warnings: scoreResult.warnings,
      );
      
      // Save to Hive
      final hiveService = ref.read(initializedHiveServiceProvider);
      await hiveService.saveSleepRecord(finalRecord);
      
      // Automatically switch to the week containing the saved record's date
      final weekDateNotifier = ref.read(weekDateProvider.notifier);
      weekDateNotifier.setWeekDate(finalRecord.date);
      
      // Invalidate providers
      ref.invalidate(weeklySleepRecordsProvider);
      ref.invalidate(allSleepRecordsProvider);
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.sleepRecordSaved ?? 'Sleep record saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final record = widget.record;
    final sleepStart = _isEditing ? _editedSleepStart : record.sleepStart;
    final wakeTime = _isEditing ? _editedWakeTime : record.wakeTime;
    final duration = Duration(minutes: record.durationMinutes);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              AppDateUtils.formatDate(record.date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            if (sleepStart != null)
              Row(
                children: [
                  Text(
                    '${l10n?.wentToSleep ?? 'Went to sleep'}: ',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (!_isEditing)
                    Text(
                      AppDateUtils.formatTime(sleepStart),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(sleepStart),
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            // Use record's date, only update hour and minute
                            final recordDate = widget.record.date;
                            _editedSleepStart = DateTime(
                              recordDate.year,
                              recordDate.month,
                              recordDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      child: Text(
                        AppDateUtils.formatTime(sleepStart),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            if (wakeTime != null) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              Row(
                children: [
                  Text(
                    '${l10n?.wakeUp ?? 'Wake up'}: ',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (!_isEditing)
                    Text(
                      AppDateUtils.formatTime(wakeTime),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(wakeTime),
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            // Use record's date, only update hour and minute
                            final recordDate = widget.record.date;
                            _editedWakeTime = DateTime(
                              recordDate.year,
                              recordDate.month,
                              recordDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      child: Text(
                        AppDateUtils.formatTime(wakeTime),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.paddingSmall),
            Row(
              children: [
                Text(
                  '${l10n?.fellAsleep ?? 'Fell asleep'}: ',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  AppDateUtils.formatDuration(duration),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (record.score > 0) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              Row(
                children: [
                  Text(
                    '${l10n?.quality ?? 'Quality'}: ',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    '${record.score}/100',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (record.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingLarge),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.glassCard,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: record.warnings.map((warning) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        warning,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            // Sleep Advice Section
            if (record.durationMinutes > 0) ...[
              const SizedBox(height: AppSizes.paddingLarge),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(
                          l10n?.sleepAdvice ?? 'Sleep Advice',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      SleepAdviceGenerator.getAdvice(record) ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSizes.paddingLarge),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                if (!_isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditing = true);
                    },
                    child: Text(
                      l10n?.editEstimatedSleepTime ?? 'Edit estimated sleep time',
                      style: const TextStyle(color: AppColors.accent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isEditing) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _editedSleepStart = record.sleepStart;
                        _editedWakeTime = record.wakeTime;
                      });
                    },
                    child: Text(
                      l10n?.cancel ?? 'Cancel',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveEdits,
                    child: Text(
                      l10n?.save ?? 'Save',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
                if (!_isEditing)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n?.close ?? 'Close',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
