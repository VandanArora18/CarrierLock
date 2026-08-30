import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Animated pulsing GPS indicator — three expanding rings with a solid center dot.
class LivePulse extends StatefulWidget {
  final Color color;
  final double size;

  const LivePulse({
    super.key,
    this.color = AppColors.green,
    this.size = 24,
  });

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding rings
              ...List.generate(3, (i) {
                final delay = i * 0.33;
                final progress =
                    ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1.0 + progress * 1.5,
                  child: Opacity(
                    opacity: (1 - progress) * 0.5,
                    child: Container(
                      width: widget.size * 0.5,
                      height: widget.size * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                      ),
                    ),
                  ),
                );
              }),
              // Solid center dot
              Container(
                width: widget.size * 0.33,
                height: widget.size * 0.33,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
