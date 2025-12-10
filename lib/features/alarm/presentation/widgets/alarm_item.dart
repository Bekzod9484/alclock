import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/alarm_model.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/alarm_provider.dart';
import 'add_alarm_dialog.dart';

class AlarmItem extends ConsumerWidget {
  final AlarmModel alarm;

  const AlarmItem({super.key, required this.alarm});

  String _getRepeatDaysText(BuildContext context, List<int> days) {
    final l10n = AppLocalizations.of(context);
    if (days.isEmpty) return l10n?.once ?? 'Once';
    if (days.length == 7) return l10n?.everyDay ?? 'Every day';

    final dayNames = [
      l10n?.monday ?? 'Mon',
      l10n?.tuesday ?? 'Tue',
      l10n?.wednesday ?? 'Wed',
      l10n?.thursday ?? 'Thu',
      l10n?.friday ?? 'Fri',
      l10n?.saturday ?? 'Sat',
      l10n?.sunday ?? 'Sun',
    ];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                // Open edit dialog when tapping the alarm content
                showDialog(
                  context: context,
                  builder: (context) => AddAlarmDialog(existingAlarm: alarm),
                );
              },
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatTime(alarm.time),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRepeatDaysText(context, alarm.repeatDays),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (alarm.note != null && alarm.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alarm.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Switch(
            value: alarm.isEnabled,
            onChanged: (value) {
              // ONLY toggle alarm - no dialogs, no navigation
              final controller = ref.read(alarmListProvider.notifier);
              controller.toggleAlarm(alarm.id, value);
            },
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
