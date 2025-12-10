import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../providers/alarm_provider.dart';
import '../widgets/add_alarm_dialog.dart';
import '../widgets/alarm_item.dart';

class AlarmPage extends ConsumerWidget {
  const AlarmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmListProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.alarm ?? 'Alarm',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: alarms.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm_add,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      AppLocalizations.of(context)?.noAlarms ?? 'No alarms',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      AppLocalizations.of(context)?.addYourFirstAlarm ?? 'Add your first alarm',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarms[index];
                  return Dismissible(
                    key: Key(alarm.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSizes.paddingLarge),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    onDismissed: (direction) {
                      // Non-blocking delete - controller handles everything
                      final controller = ref.read(alarmListProvider.notifier);
                      controller.deleteAlarm(alarm.id);
                    },
                    child: AlarmItem(alarm: alarm),
                  );
                },
              ),
        floatingActionButton: NeumorphicButton(
          width: 64,
          height: 64,
          borderRadius: 32,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddAlarmDialog(),
            );
          },
          color: AppColors.accent,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
