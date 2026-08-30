import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';

/// Splash / Role Picker — user selects Driver or Admin.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldDim,
                  border: Border.all(color: AppColors.goldBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldGlow.withValues(alpha: 0.25),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 30,
                  color: AppColors.gold,
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                  ),

              SizedBox(height: sh * 0.03),

              // App name
              Text('CARRIERLOCK', style: AppTextStyles.appName)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 6),

              Text(
                'Smart Logistics Access System',
                style: AppTextStyles.greetSub.copyWith(letterSpacing: 1.5),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const Spacer(flex: 1),

              // Role selection
              Text(
                'SELECT YOUR ROLE',
                style: AppTextStyles.sectionLabel.copyWith(fontSize: 9),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

              SizedBox(height: sh * 0.02),

              // Driver card
              CarrierLockCard(
                type: CardType.gold,
                breathing: true,
                onTap: () => context.go(AppRoutes.driverLogin),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldDim,
                          border: Border.all(color: AppColors.goldBorder),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I\'m a Driver',
                              style: AppTextStyles.screenTitle
                                  .copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Request OTP · Unlock carrier · Track trips',
                              style: AppTextStyles.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms).slideX(
                    begin: -0.1,
                    end: 0,
                    delay: 700.ms,
                    duration: 500.ms,
                  ),

              SizedBox(height: sh * 0.015),

              // Admin card
              CarrierLockCard(
                type: CardType.teal,
                onTap: () => context.go(AppRoutes.adminLogin),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tealDim,
                          border: Border.all(color: AppColors.tealBorder),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I\'m an Admin',
                              style: AppTextStyles.screenTitle.copyWith(
                                fontSize: 15,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Approve requests · Manage fleets · Monitor drivers',
                              style: AppTextStyles.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms).slideX(
                    begin: 0.1,
                    end: 0,
                    delay: 900.ms,
                    duration: 500.ms,
                  ),

              const Spacer(flex: 3),

              // Footer
              Text(
                'v1.0.0 · Secure Split-OTP System',
                style: AppTextStyles.caption,
              ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),

              SizedBox(height: sh * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
