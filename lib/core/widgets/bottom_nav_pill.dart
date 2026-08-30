import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Navigation item data.
class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

/// Floating pill-shaped bottom navigation bar with backdrop blur.
class BottomNavPill extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const BottomNavPill({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 2 + bottomPadding,
      left: 16,
      right: 16,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: AppColors.goldBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Row(
              children: List.generate(
                items.length,
                (i) => Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 18,
                            color: i == currentIndex
                                ? AppColors.gold
                                : AppColors.textDimmer,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              color: i == currentIndex
                                  ? AppColors.gold
                                  : AppColors.textDimmer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
