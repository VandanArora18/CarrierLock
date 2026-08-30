import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/widgets/attempt_dots.dart';
import '../../../../core/router/app_router.dart';

/// Screen shown when the driver enters the wrong OTP on the hardware lock.
class OtpWrongAttemptScreen extends StatelessWidget {
  final String requestId;
  final int attempts;
  final String half1;
  final String half2;

  const OtpWrongAttemptScreen({
    super.key,
    required this.requestId,
    required this.attempts,
    required this.half1,
    required this.half2,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    final remaining = 3 - attempts;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.redDim,
                  border: Border.all(color: AppColors.redBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.red, size: 40),
              ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.easeOutBack),

              SizedBox(height: sh * 0.03),

              Text('Incorrect OTP',
                      style: AppTextStyles.screenTitle
                          .copyWith(color: AppColors.red))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text('The OTP entered on the device was incorrect.',
                      style: AppTextStyles.body, textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 300.ms),

              SizedBox(height: sh * 0.04),

              CarrierLockCard(
                type: CardType.red,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('ATTEMPTS USED',
                          style: AppTextStyles.sectionLabel
                              .copyWith(color: AppColors.red)),
                      const SizedBox(height: 12),
                      AttemptDots(attemptsUsed: attempts, maxAttempts: 3),
                      const SizedBox(height: 16),
                      Text(
                        '$remaining attempts remaining',
                        style:
                            AppTextStyles.label.copyWith(color: AppColors.red),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

              SizedBox(height: sh * 0.06),

              GoldButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  if (attempts >= 3) {
                    context.go(AppRoutes.carrierHardLocked,
                        extra: {'deviceId': 'DEV-042'});
                  } else {
                    context.pushReplacement(AppRoutes.otpFullEntry, extra: {
                      'requestId': requestId,
                      'half1': half1,
                      'half2': half2,
                    });
                  }
                },
              ).animate().fadeIn(delay: 500.ms),

              SizedBox(height: sh * 0.02),

              GoldButton(
                label: 'Cancel Request',
                outlined: true,
                onPressed: () => context.go(AppRoutes.driverHome),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
