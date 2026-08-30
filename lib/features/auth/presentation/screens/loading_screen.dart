import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

/// Loading screen — animated logo + shimmer, then navigates to splash or home.
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final minDelay = Future.delayed(const Duration(milliseconds: 2500));
    
    // Check auth state
    final authNotifier = ref.read(authProvider.notifier);
    
    try {
      await authNotifier.checkAuthState().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Auth Check Failed: $e');
    }
    
    await minDelay;
    
    if (mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user.isAdmin) {
          context.go(AppRoutes.adminDashboard);
        } else {
          context.go(AppRoutes.driverHome);
        }
      } else {
        context.go(AppRoutes.splash);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Lock Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldDim,
                border: Border.all(color: AppColors.goldBorder, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppColors.gold,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 2500.ms,
                  color: AppColors.gold.withValues(alpha: 0.4),
                  angle: 0.5,
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms,
                  curve: Curves.easeInOutSine,
                )
                .then()
                .scale(
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(0.95, 0.95),
                  duration: 1500.ms,
                  curve: Curves.easeInOutSine,
                ),

            SizedBox(height: sh * 0.05),

            // Text
            Text(
              'CARRIERLOCK',
              style: AppTextStyles.appName.copyWith(fontSize: 28),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.2, end: 0, duration: 800.ms),

            const SizedBox(height: 12),

            Text(
              'INITIALIZING SECURE SESSION...',
              style: AppTextStyles.greetSub.copyWith(
                color: AppColors.gold,
                letterSpacing: 2,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fade(
                  begin: 0.4,
                  end: 1.0,
                  duration: 1000.ms,
                )
                .then()
                .fade(
                  begin: 1.0,
                  end: 0.4,
                  duration: 1000.ms,
                ),

            const SizedBox(height: 24),

            // Subtle progress indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
