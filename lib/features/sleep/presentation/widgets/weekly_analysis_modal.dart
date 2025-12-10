import 'package:flutter/material.dart';
import 'package:alclock/l10n/app_localizations.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/models/sleep_record_model.dart';
import '../../../../core/widgets/glass_card.dart';
import '../utils/weekly_advice_generator.dart';

/// Modal bottom sheet showing comprehensive weekly sleep analysis
class WeeklyAnalysisModal extends StatelessWidget {
  final List<SleepRecordModel> weeklyRecords;

  const WeeklyAnalysisModal({
    super.key,
    required this.weeklyRecords,
  });

  static void show(BuildContext context, List<SleepRecordModel> weeklyRecords) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeeklyAnalysisModal(weeklyRecords: weeklyRecords),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final report = WeeklyAdviceGenerator.generateWeeklyReport(weeklyRecords);
    final formattedText = report.toFormattedText();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.gradientStart.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
                vertical: AppSizes.paddingMedium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.weeklySleepAnalysis ?? 'Haftalik uyqu tahlili',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: AppColors.glassCard,
            ),

            // Analysis content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    child: Text(
                      formattedText,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n?.close ?? 'Yopish',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

