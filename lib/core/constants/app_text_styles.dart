import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system — dual-font strategy:
///   • Space Grotesk → OTP digits, titles, numbers, hero text
///   • Inter → body, labels, buttons, captions
class AppTextStyles {
  AppTextStyles._();

  // ─── Space Grotesk — Hardware UI Elements ─────────────────

  /// Large OTP digit display (responsive — see OtpBox for scaled version)
  static TextStyle otpDigit = GoogleFonts.spaceGrotesk(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: 14,
  );

  /// Screen title / section headers
  static TextStyle screenTitle = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: -0.4,
  );

  /// Large stat numbers (e.g. "24" active drivers)
  static TextStyle statNumber = GoogleFonts.spaceGrotesk(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  /// Fleet ID tag text
  static TextStyle fleetId = GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: 1.5,
  );

  /// App name / branding text
  static TextStyle appName = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.gold,
    letterSpacing: -0.5,
  );

  /// Large hero title (splash, loading)
  static TextStyle heroTitle = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: -0.8,
  );

  /// Greeting name ("Hey, Arjun")
  static TextStyle greetName = GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: -0.3,
  );

  // ─── Inter — Functional UI ────────────────────────────────

  /// Body text (primary)
  static TextStyle body = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Body text (larger variant)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Label / secondary info
  static TextStyle label = GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Button text
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.base,
  );

  /// Section label (e.g. "RECENT ALERTS")
  static TextStyle sectionLabel = GoogleFonts.inter(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    color: AppColors.textDimmer,
    letterSpacing: 1.5,
  );

  /// Caption / timestamp
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 8,
    fontWeight: FontWeight.w400,
    color: AppColors.textDimmer,
  );

  /// Greeting subtitle ("Good morning")
  static TextStyle greetSub = GoogleFonts.inter(
    fontSize: 8,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Input field text
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Input hint text
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textDimmer,
  );

  /// Error text
  static TextStyle error = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.red,
  );

  /// Link / tappable text
  static TextStyle link = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
  );
}
