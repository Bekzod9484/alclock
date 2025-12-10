import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/widgets/glass_card.dart';

class SleepStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool fullWidth;

  const SleepStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height for all cards to ensure consistency (increased by 8px to prevent overflow)
    const double cardHeight = 148.0;
    const double iconSize = 28.0; // Slightly reduced
    const double valueFontSize = 19.0; // Reduced by 1px
    const double titleFontSize = 11.0; // Reduced by 1px
    const double iconSpacing = 6.0; // Reduced spacing
    const double valueSpacing = 3.0; // Reduced spacing

    Widget card = GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: 12.0, // Reduced vertical padding
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered icon
          Icon(
            icon,
            color: AppColors.accent,
            size: iconSize,
          ),
          SizedBox(height: iconSpacing),
          // Centered value
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: valueSpacing),
          // Centered title
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: titleFontSize,
                color: AppColors.textSecondary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Wrap in SizedBox to ensure consistent height
    return SizedBox(
      height: cardHeight,
      width: fullWidth ? double.infinity : null,
      child: card,
    );
  }
}

