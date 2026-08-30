import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Red dots indicator showing OTP attempt count (0-3).
class AttemptDots extends StatelessWidget {
  final int attemptsUsed;
  final int maxAttempts;

  const AttemptDots({
    super.key,
    required this.attemptsUsed,
    this.maxAttempts = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxAttempts, (i) {
        final used = i < attemptsUsed;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: used ? AppColors.red : Colors.white.withValues(alpha: 0.12),
            border: used
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: used
                ? [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
