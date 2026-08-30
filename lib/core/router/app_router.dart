import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth screens
import '../../features/auth/presentation/screens/loading_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/driver_login_screen.dart';
import '../../features/auth/presentation/screens/driver_signup_screen.dart';
import '../../features/auth/presentation/screens/driver_phone_otp_screen.dart';
import '../../features/auth/presentation/screens/admin_login_screen.dart';
import '../../features/auth/presentation/screens/admin_signup_screen.dart';

// Driver screens
import '../../features/driver/presentation/screens/driver_home_screen.dart';
import '../../features/driver/presentation/screens/driver_waiting_approval_screen.dart';
import '../../features/driver/presentation/screens/driver_unlock_otp_screen.dart';
import '../../features/driver/presentation/screens/otp_half1_screen.dart';
import '../../features/driver/presentation/screens/otp_full_entry_screen.dart';
import '../../features/driver/presentation/screens/otp_wrong_attempt_screen.dart';
import '../../features/driver/presentation/screens/carrier_hard_locked_screen.dart';
import '../../features/driver/presentation/screens/carrier_unlocked_screen.dart';
import '../../features/driver/presentation/screens/driver_alerts_screen.dart';
import '../../features/driver/presentation/screens/driver_location_screen.dart';
import '../../features/driver/presentation/screens/driver_settings_screen.dart';
import '../../features/driver/presentation/screens/driver_stats_screen.dart';

// Admin screens
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_request_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_fallback_screen.dart';
import '../../features/admin/presentation/screens/admin_hardlock_reset_screen.dart';
import '../../features/admin/presentation/screens/admin_all_drivers_screen.dart';
import '../../features/admin/presentation/screens/admin_driver_live_map_screen.dart';
import '../../features/admin/presentation/screens/admin_fleet_management_screen.dart';
import '../../features/admin/presentation/screens/admin_fleet_selection_screen.dart';
import '../../features/admin/presentation/screens/admin_create_fleet_screen.dart';
import '../../features/admin/presentation/screens/admin_history_screen.dart';
import '../../features/admin/presentation/screens/admin_history_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_alerts_screen.dart';
import '../../features/admin/presentation/screens/admin_pending_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_hard_locked_screen.dart';
import '../../features/admin/presentation/screens/admin_active_drivers_screen.dart';
import '../../features/admin/presentation/screens/admin_driver_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_hard_lock_confirm_screen.dart';

/// Route names for type-safe navigation.
class AppRoutes {
  static const String loading = '/';
  static const String splash = '/splash';

  // Auth
  static const String driverLogin = '/driver/login';
  static const String driverSignup = '/driver/signup';
  static const String adminLogin = '/admin/login';
  static const String adminSignup = '/admin/signup';

  // Driver
  static const String driverHome = '/driver/home';
  static const String otpHalf1 = '/driver/otp-half1';
  static const String otpFullEntry = '/driver/otp-entry';
  static const String otpWrongAttempt = '/driver/otp-wrong';
  static const String carrierHardLocked = '/driver/hard-locked';
  static const String carrierUnlocked = '/driver/unlocked';
  static const String driverAlerts = '/driver/alerts';
  static const String driverLocation = '/driver/location';
  static const String driverSettings = '/driver/settings';
  static const String driverUnlockOtp = '/driver/unlock-otp';
  static const String driverPhoneOtp = '/driver/phone-otp';
  static const String driverWaitingApproval = '/driver/waiting-approval';
  static const String driverStats = '/driver/stats';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminRequestDetail = '/admin/request-detail';
  static const String adminFallback = '/admin/fallback';
  static const String adminHardlockReset = '/admin/hardlock-reset';
  static const String adminAllDrivers = '/admin/all-drivers';
  static const String adminDriverLiveMap = '/admin/driver-live-map';
  static const String adminFleetSelection = '/admin/fleet-selection';
  static const String adminFleetManagement = '/admin/fleet-management';
  static const String adminCreateFleet = '/admin/create-fleet';
  static const String adminHistory = '/admin/history';
  static const String adminHistoryDetail = '/admin/history-detail';
  static const String adminAlerts = '/admin/alerts';
  static const String adminPendingRequests = '/admin/pending-requests';
  static const String adminHardLocked = '/admin/hard-locked-devices';
  static const String adminActiveDrivers = '/admin/active-drivers';
  static const String adminDriverDetail = '/admin/driver-detail';
  static const String adminHardLockConfirm = '/admin/hard-lock-confirm';
}

/// GoRouter configuration with all routes.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.loading,
  debugLogDiagnostics: true,
  routes: [
    // ─── Auth Routes ─────────────────────────────────────
    GoRoute(
      path: AppRoutes.loading,
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverLogin,
      builder: (context, state) => const DriverLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverSignup,
      builder: (context, state) => const DriverLoginScreen(), // unified
    ),
    GoRoute(
      path: AppRoutes.driverPhoneOtp,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return DriverPhoneOtpScreen(
          verificationId: extra['verificationId'] ?? '',
          phone: extra['phone'] ?? '',
          name: extra['name'] ?? '',
          fleetId: extra['fleetId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.driverWaitingApproval,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return DriverWaitingApprovalScreen(
          pendingAuthId: extra['pendingAuthId'] ?? '',
          driverUid: extra['driverUid'] ?? '',
          fleetId: extra['fleetId'] ?? '',
          driverName: extra['driverName'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminLogin,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminSignup,
      builder: (context, state) => const AdminSignupScreen(),
    ),

    // ─── Driver Routes ───────────────────────────────────
    GoRoute(
      path: AppRoutes.driverHome,
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.otpHalf1,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpHalf1Screen(
          requestId: extra?['requestId'] ?? '',
          half1: extra?['half1'] ?? '',
          expiresAt: extra?['expiresAt'] ?? '',
          driverId: extra?['driverId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.otpFullEntry,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpFullEntryScreen(
          requestId: extra?['requestId'] ?? '',
          half1: extra?['half1'] ?? '',
          half2: extra?['half2'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.otpWrongAttempt,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpWrongAttemptScreen(
          requestId: extra?['requestId'] ?? '',
          attempts: extra?['attempts'] ?? 0,
          half1: extra?['half1'] ?? '',
          half2: extra?['half2'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.carrierHardLocked,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CarrierHardLockedScreen(
          deviceId: extra?['deviceId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.carrierUnlocked,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CarrierUnlockedScreen(
          deviceId: extra?['deviceId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.driverAlerts,
      builder: (context, state) => const DriverAlertsScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverLocation,
      builder: (context, state) => const DriverLocationScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverSettings,
      builder: (context, state) => const DriverSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverUnlockOtp,
      builder: (context, state) => const DriverUnlockOtpScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverStats,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DriverStatsScreen(
          title: extra?['title'] ?? 'Stats',
          statKey: extra?['statKey'] ?? '',
          fleetStats: extra?['fleetStats'] ?? {},
        );
      },
    ),

    // ─── Admin Routes ────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminDashboard,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminRequestDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdminRequestDetailScreen(
          requestId: extra?['requestId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminFallback,
      builder: (context, state) => const AdminFallbackScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminHardlockReset,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdminHardlockResetScreen(
          deviceId: extra?['deviceId'] ?? '',
          driverId: extra?['driverId'] ?? '',
          fleetId: extra?['fleetId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminAllDrivers,
      builder: (context, state) => const AdminAllDriversScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminDriverLiveMap,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdminDriverLiveMapScreen(
          driverId: extra?['driverId'] ?? '',
          driverName: extra?['driverName'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminFleetSelection,
      builder: (context, state) => const AdminFleetSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminFleetManagement,
      builder: (context, state) => const AdminFleetManagementScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminCreateFleet,
      builder: (context, state) => const AdminCreateFleetScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminHistory,
      builder: (context, state) => const AdminHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminHistoryDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdminHistoryDetailScreen(
          historyDoc: extra?['historyDoc'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminAlerts,
      builder: (context, state) => const AdminAlertsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminPendingRequests,
      builder: (context, state) => const AdminPendingRequestsScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminHardLocked,
      builder: (context, state) => const AdminHardLockedScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminActiveDrivers,
      builder: (context, state) => const AdminActiveDriversScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminDriverDetail,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdminDriverDetailScreen(
          driverId: extra?['driverId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminHardLockConfirm,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AdminHardLockConfirmScreen(
          driverId: extra?['driverId'] ?? '',
          driverName: extra?['driverName'] ?? '',
          fleetId: extra?['fleetId'] ?? '',
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF0F0F0D),
    body: Center(
      child: Text(
        'Page not found',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
);
