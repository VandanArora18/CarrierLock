import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// OTP box visual state.
enum OtpBoxState { empty, driverFilled, adminFilled, error, disabled }

/// 3D keycap-style OTP digit box — responsive sizing.
/// Used for both 4-digit half displays and the full 8-digit entry.
class OtpBox extends StatelessWidget {
  final String? digit;
  final OtpBoxState state;
  final bool isFocused;

  const OtpBox({
    super.key,
    this.digit,
    this.state = OtpBoxState.empty,
    this.isFocused = false,
  });

  Color _getFillColor() {
    switch (state) {
      case OtpBoxState.driverFilled:
        return AppColors.goldDim;
      case OtpBoxState.adminFilled:
        return AppColors.tealDim;
      case OtpBoxState.error:
        return AppColors.redDim;
      case OtpBoxState.disabled:
        return Colors.white.withValues(alpha: 0.03);
      case OtpBoxState.empty:
        return Colors.white.withValues(alpha: 0.06);
    }
  }

  Color _getBorderColor() {
    if (isFocused) return AppColors.gold;
    switch (state) {
      case OtpBoxState.driverFilled:
        return AppColors.goldBorder;
      case OtpBoxState.adminFilled:
        return AppColors.tealBorder;
      case OtpBoxState.error:
        return AppColors.redBorder;
      case OtpBoxState.disabled:
        return Colors.white.withValues(alpha: 0.05);
      case OtpBoxState.empty:
        return Colors.white.withValues(alpha: 0.12);
    }
  }

  Color _getGlowColor() {
    switch (state) {
      case OtpBoxState.driverFilled:
        return AppColors.gold;
      case OtpBoxState.adminFilled:
        return AppColors.teal;
      case OtpBoxState.error:
        return AppColors.red;
      default:
        return Colors.transparent;
    }
  }

  Color _getDigitColor() {
    switch (state) {
      case OtpBoxState.disabled:
        return AppColors.textDimmer;
      default:
        return AppColors.white; // Always use white so it contrasts with any background rendering bugs
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = screenWidth * 0.11;
    final boxHeight = boxWidth * 1.17;

    return Container(
      width: 44,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _getFillColor(),
        border: Border.all(color: _getBorderColor(), width: isFocused ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        (digit != null && digit!.trim().isNotEmpty) ? digit! : '8',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _getDigitColor(),
        ),
      ),
    );
  }
}
