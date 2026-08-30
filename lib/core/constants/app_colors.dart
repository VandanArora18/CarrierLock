import 'package:flutter/material.dart';

/// Complete color palette for the CarrierLock design system.
/// "Obsidian Amber Industrial" — deep matte black with brass gold accents.
class AppColors {
  AppColors._();

  // ─── Backgrounds ──────────────────────────────────────────
  static const Color base = Color(0xFF0F0F0D);
  static const Color surface1 = Color(0xFF1A1A16);
  static const Color surface2 = Color(0xFF242420);
  static const Color surface3 = Color(0xFF2E2E28);

  // ─── Primary Gold ─────────────────────────────────────────
  static const Color gold = Color(0xFFF5C518);
  static const Color goldDim = Color(0x1FF5C518); // 12% opacity
  static const Color goldBorder = Color(0x38F5C518); // 22% opacity
  static const Color goldGlow = Color(0x59F5C518); // 35% opacity

  // ─── White / Text ─────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFF2F2EE);
  static const Color textSecondary = Color(0xFFA8A89A);
  static const Color textDimmer = Color(0xFF6B6B5E);

  // ─── Status Colors ────────────────────────────────────────
  static const Color green = Color(0xFF22D47A);
  static const Color greenDim = Color(0x1F22D47A);
  static const Color greenBorder = Color(0x4D22D47A);
  static const Color greenGlow = Color(0x3322D47A);

  static const Color red = Color(0xFFFF4F6B);
  static const Color redDim = Color(0x1FFF4F6B);
  static const Color redBorder = Color(0x4DFF4F6B);
  static const Color redGlow = Color(0x33FF4F6B);

  static const Color amber = Color(0xFFFFAA00);
  static const Color amberDim = Color(0x1FFFAA00);
  static const Color amberBorder = Color(0x4DFFAA00);
  static const Color amberGlow = Color(0x33FFAA00);

  static const Color teal = Color(0xFF00E5CC);
  static const Color tealDim = Color(0x1F00E5CC);
  static const Color tealBorder = Color(0x4D00E5CC);
  static const Color tealGlow = Color(0x3300E5CC);

  // ─── Borders ──────────────────────────────────────────────
  static const Color borderFaint = Color(0x14FFFFFF); // 8%
  static const Color borderMid = Color(0x21FFFFFF); // 13%
  static const Color rowDivider = Color(0x0DFFFFFF); // 5%

  // ─── Card Surface ─────────────────────────────────────────
  static const Color cardSurface = Color(0x0FFFFFFF); // 6%
  static const Color cardSurfaceHover = Color(0x18FFFFFF); // 9%

  // ─── Gradients ────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5C518), Color(0xFFE5A500)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A16), Color(0xFF0F0F0D)],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4F6B), Color(0xFFE03050)],
  );
}
