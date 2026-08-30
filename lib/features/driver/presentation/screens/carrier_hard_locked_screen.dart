import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';

/// Screen shown when the device is hard-locked due to max failed attempts or remote lock.
class CarrierHardLockedScreen extends StatelessWidget {
  final String deviceId;

  const CarrierHardLockedScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.redDim,
                  border: Border.all(color: AppColors.redBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppColors.red, size: 40),
              ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 500.ms,
                  curve: Curves.elasticOut),

              SizedBox(height: sh * 0.03),

              Text('CARRIER HARD LOCKED',
                      style: AppTextStyles.screenTitle
                          .copyWith(color: AppColors.red, fontSize: 22))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Maximum OTP attempts exceeded. The carrier is now fully locked for security.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              SizedBox(height: sh * 0.04),

              CarrierLockCard(
                type: CardType.red,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: AppColors.red, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DEVICE ID',
                                style: AppTextStyles.sectionLabel
                                    .copyWith(color: AppColors.red)),
                            const SizedBox(height: 4),
                            Text(deviceId,
                                style: AppTextStyles.fleetId
                                    .copyWith(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

              SizedBox(height: sh * 0.06),

              Text(
                'Please contact your fleet admin immediately. They must issue a reset command from the dashboard.',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),

              SizedBox(height: sh * 0.04),

              GoldButton(
                label: 'Return to Dashboard',
                icon: Icons.home_rounded,
                onPressed: () => context.go(AppRoutes.driverHome),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
