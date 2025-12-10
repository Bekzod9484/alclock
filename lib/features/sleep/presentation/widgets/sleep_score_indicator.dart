import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class SleepScoreIndicator extends StatelessWidget {
  final int score;
  final VoidCallback? onTap;

  const SleepScoreIndicator({
    super.key,
    required this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                backgroundColor: AppColors.glassCard,
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 80
                      ? AppColors.idealSleep
                      : score >= 60
                          ? AppColors.mediumSleep
                          : AppColors.poorSleep,
                ),
              ),
            ),
            Text(
              '$score%',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

