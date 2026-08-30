import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';

/// Screen shown when the device is successfully unlocked.
class CarrierUnlockedScreen extends StatelessWidget {
  final String deviceId;

  const CarrierUnlockedScreen({
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
              // Success Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.greenDim,
                  border: Border.all(color: AppColors.greenBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: AppColors.green, size: 40),
              ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 500.ms,
                  curve: Curves.elasticOut),

              SizedBox(height: sh * 0.03),

              Text('CARRIER UNLOCKED',
                      style: AppTextStyles.screenTitle
                          .copyWith(color: AppColors.green, fontSize: 22))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Access granted. The carrier will automatically lock again when the door is closed.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              SizedBox(height: sh * 0.04),

              CarrierLockCard(
                type: CardType.green,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.green, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DEVICE ID',
                                style: AppTextStyles.sectionLabel
                                    .copyWith(color: AppColors.green)),
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

              SizedBox(height: sh * 0.08),

              GoldButton(
                label: 'Done',
                icon: Icons.check_rounded,
                onPressed: () => context.go(AppRoutes.driverHome),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
