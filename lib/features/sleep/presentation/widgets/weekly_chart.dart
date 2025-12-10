import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/sleep_record_model.dart';
import '../../../../core/utils/app_date_utils.dart';
import 'sleep_detail_dialog.dart';

class WeeklyChart extends StatelessWidget {
  final List<SleepRecordModel> records;
  final List<DateTime> weekDates;

  const WeeklyChart({
    super.key,
    required this.records,
    required this.weekDates,
  });

  Color _getBarColor(double hours) {
    if (hours >= 7) return AppColors.idealSleep;
    if (hours >= 6) return AppColors.mediumSleep;
    return AppColors.poorSleep;
  }

  @override
  Widget build(BuildContext context) {
    final maxHours = 10.0;
    
    // Match records to week dates by actual date (not by index)
    final weeklyHours = List.generate(7, (index) {
      final targetDate = weekDates[index];
      // Find record that matches this date
      final record = records.firstWhere(
        (r) => AppDateUtils.isSameDay(r.date, targetDate),
        orElse: () => SleepRecordModel(
          id: targetDate.millisecondsSinceEpoch.toString(),
          date: targetDate,
        ),
      );
      return record.durationMinutes > 0 ? record.durationMinutes / 60.0 : 0.0;
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxHours,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.glassCard,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final record = records.firstWhere(
                  (r) => AppDateUtils.isSameDay(r.date, weekDates[groupIndex]),
                  orElse: () => SleepRecordModel(
                    id: weekDates[groupIndex].millisecondsSinceEpoch.toString(),
                    date: weekDates[groupIndex],
                  ),
                );
                final durationText = record.durationMinutes > 0
                    ? AppDateUtils.formatDurationFromMinutes(record.durationMinutes)
                    : '0h 0m';
                return BarTooltipItem(
                  durationText,
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
                final spot = barTouchResponse!.spot;
                final index = spot?.touchedBarGroupIndex ?? -1;
                if (index >= 0 && index < weekDates.length) {
                  final targetDate = weekDates[index];
                  // Find record that matches this date
                  final record = records.firstWhere(
                    (r) => AppDateUtils.isSameDay(r.date, targetDate),
                    orElse: () => SleepRecordModel(
                      id: targetDate.millisecondsSinceEpoch.toString(),
                      date: targetDate,
                    ),
                  );
                  // Show dialog even if duration is 0 (to show empty record info)
                  final ctx = context;
                  if (ctx.mounted) {
                    showDialog(
                      context: ctx,
                      builder: (dialogContext) => SleepDetailDialog(record: record),
                    );
                  }
                }
              }
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < weekDates.length) {
                    return Text(
                      AppDateUtils.getDayName(weekDates[value.toInt()]),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1, // Show only integer hours
                getTitlesWidget: (value, meta) {
                  // Only show integer values (0, 1, 2, 3, etc.)
                  if (value == value.toInt()) {
                    return Text(
                      '${value.toInt()}h',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.glassCard,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final hours = weeklyHours[index];

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: hours,
                  color: _getBarColor(hours),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

