import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Card type determines the border/fill accent color.
enum CardType { standard, gold, green, red, amber, fleet, teal }

/// Glassmorphic card component with backdrop blur and optional breathing border.
/// The signature container for all CarrierLock UI surfaces.
class CarrierLockCard extends StatelessWidget {
  final Widget child;
  final CardType type;
  final bool breathing;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CarrierLockCard({
    super.key,
    required this.child,
    this.type = CardType.standard,
    this.breathing = false,
    this.padding,
    this.onTap,
  });

  Color _getFillColor() {
    switch (type) {
      case CardType.gold:
        return AppColors.goldDim;
      case CardType.green:
        return AppColors.greenDim;
      case CardType.red:
        return AppColors.redDim;
      case CardType.amber:
        return AppColors.amberDim;
      case CardType.teal:
        return AppColors.tealDim;
      case CardType.fleet:
        return AppColors.goldDim;
      case CardType.standard:
        return AppColors.cardSurface;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case CardType.gold:
        return AppColors.goldBorder;
      case CardType.green:
        return AppColors.greenBorder;
      case CardType.red:
        return AppColors.redBorder;
      case CardType.amber:
        return AppColors.amberBorder;
      case CardType.teal:
        return AppColors.tealBorder;
      case CardType.fleet:
        return AppColors.goldBorder;
      case CardType.standard:
        return AppColors.borderFaint;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: _getFillColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _getBorderColor(), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );

    if (breathing) {
      card = _BreathingBorder(borderColor: _getBorderColor(), child: card);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Animated breathing border effect — pulsates the border opacity.
class _BreathingBorder extends StatefulWidget {
  final Color borderColor;
  final Widget child;

  const _BreathingBorder({required this.borderColor, required this.child});

  @override
  State<_BreathingBorder> createState() => _BreathingBorderState();
}

class _BreathingBorderState extends State<_BreathingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor
                    .withValues(alpha: _animation.value * 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
