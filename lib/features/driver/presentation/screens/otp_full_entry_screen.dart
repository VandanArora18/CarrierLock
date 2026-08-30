import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/otp_box.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';

/// Driver Full OTP Entry screen — admin has approved, driver enters the full 8-digit OTP on the hardware lock.
class OtpFullEntryScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String half1;
  final String half2;

  const OtpFullEntryScreen({
    super.key,
    required this.requestId,
    required this.half1,
    required this.half2,
  });

  @override
  ConsumerState<OtpFullEntryScreen> createState() => _OtpFullEntryScreenState();
}

class _OtpFullEntryScreenState extends ConsumerState<OtpFullEntryScreen> {
  bool _isVerifying = false;

  void _verifyOtp() {
    setState(() {
      _isVerifying = true;
    });

    // Simulate verification delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        // For demonstration, randomly succeed or fail
        // In a real app, this would call the Cloud Function
        final bool isSuccess = DateTime.now().second % 2 == 0;

        if (isSuccess) {
          context.pushReplacement(AppRoutes.carrierUnlocked, extra: {
            'deviceId': 'DEV-042',
          });
        } else {
          context.pushReplacement(AppRoutes.otpWrongAttempt, extra: {
            'requestId': widget.requestId,
            'attempts': 1,
            'half1': widget.half1,
            'half2': widget.half2,
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.04;

    final half1Digits = widget.half1.padRight(4, ' ').split('');
    final half2Digits = widget.half2.padRight(4, ' ').split('');

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: sh * 0.02),

              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('Admin Approved',
                      style: AppTextStyles.screenTitle
                          .copyWith(color: AppColors.teal)),
                ],
              ),

              SizedBox(height: sh * 0.03),

              // Step indicator
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              SizedBox(height: sh * 0.04),

              // Info card
              CarrierLockCard(
                type: CardType.teal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tealDim,
                          border: Border.all(color: AppColors.tealBorder),
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Request approved. Enter the full 8-digit OTP on the physical carrier lock.',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              SizedBox(height: sh * 0.06),

              // OTP Display
              Text('FULL 8-DIGIT OTP', style: AppTextStyles.sectionLabel)
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              // Wrap in a FittedBox to ensure the 8 boxes fit on smaller screens
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Half 1
                    ...List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: OtpBox(
                          digit: half1Digits[i],
                          state: OtpBoxState.driverFilled,
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    // Half 2
                    ...List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: OtpBox(
                          digit: half2Digits[i],
                          state: OtpBoxState.adminFilled,
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).scale(
                  begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

              const Spacer(),

              // Verify Button
              GoldButton(
                label: 'Confirm Unlock',
                icon: Icons.lock_open_rounded,
                isLoading: _isVerifying,
                onPressed: _verifyOtp,
              ).animate().fadeIn(delay: 600.ms),

              SizedBox(height: sh * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
