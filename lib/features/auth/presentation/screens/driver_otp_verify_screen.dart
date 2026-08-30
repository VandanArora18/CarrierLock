import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/otp_box.dart';

/// Driver OTP verification screen (phone auth).
/// Placeholder — will integrate with Firebase Phone Auth.
class DriverOtpVerifyScreen extends StatelessWidget {
  const DriverOtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 30),
              const Icon(Icons.phone_android_rounded,
                  size: 48, color: AppColors.gold),
              const SizedBox(height: 16),
              Text('Verify Phone', style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to your phone',
                style: AppTextStyles.label.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OtpBox(state: OtpBoxState.empty),
                  );
                }),
              ),
              const SizedBox(height: 32),
              GoldButton(label: 'Verify', onPressed: () {}),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: Text('Resend code', style: AppTextStyles.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
