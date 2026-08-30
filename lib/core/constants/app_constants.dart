/// String constants and configuration values for CarrierLock.
class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────────────
  static const String appName = 'CarrierLock';
  static const String appTagline = 'Smart Logistics Access System';
  static const String appVersion = '1.0.0';

  // ─── Roles ────────────────────────────────────────────────
  static const String roleDriver = 'driver';
  static const String roleAdmin = 'admin';

  // ─── OTP Configuration ────────────────────────────────────
  static const int otpLength = 8;
  static const int otpHalfLength = 4;
  static const int maxOtpAttempts = 3;
  static const int otpExpiryMinutes = 5;

  // ─── Device Statuses ──────────────────────────────────────
  static const String deviceLocked = 'locked';
  static const String deviceUnlocked = 'unlocked';
  static const String deviceHardLocked = 'hard_locked';

  // ─── Request Statuses ─────────────────────────────────────
  static const String requestPending = 'pending';
  static const String requestApproved = 'approved';
  static const String requestDenied = 'denied';
  static const String requestCompleted = 'completed';
  static const String requestFailed = 'failed';
  static const String requestExpired = 'expired';

  // ─── Alert Types ──────────────────────────────────────────
  static const String alertNewUnlockRequest = 'new_unlock_request';
  static const String alertOtpHalf2Sent = 'otp_half2_sent';
  static const String alertCarrierUnlocked = 'carrier_unlocked';
  static const String alertAttemptWarning = 'attempt_warning';
  static const String alertMaxAttemptsHardlock = 'max_attempts_hardlock';
  static const String alertOtpDenied = 'otp_denied';
  static const String alertDeviceReset = 'device_reset';
  static const String alertFallbackUsed = 'fallback_used';
  static const String alertRemoteLock = 'remote_lock';

  // ─── Alert Severities ─────────────────────────────────────
  static const String severityInfo = 'info';
  static const String severityWarning = 'warning';
  static const String severityCritical = 'critical';

  // ─── Firestore Collections ────────────────────────────────
  static const String usersCollection = 'users';
  static const String fleetsCollection = 'fleets';
  static const String devicesCollection = 'devices';
  static const String unlockRequestsCollection = 'unlock_requests';
  static const String alertsCollection = 'alerts';
  static const String auditLogsCollection = 'audit_logs';

  // ─── Locked Reasons ───────────────────────────────────────
  static const String lockedTripComplete = 'trip_complete';
  static const String lockedMaxAttempts = 'max_attempts';
  static const String lockedRemoteLock = 'remote_lock';

  // ─── Audit Event Types ────────────────────────────────────
  static const String auditOtpSuccess = 'otp_success';
  static const String auditOtpFailed = 'otp_failed';
  static const String auditHardLock = 'hard_lock';
  static const String auditFallback = 'fallback';
  static const String auditRemoteLock = 'remote_lock';
  static const String auditDeviceReset = 'device_reset';

  // ─── Fleet Statuses ───────────────────────────────────────
  static const String fleetActive = 'active';
  static const String fleetPending = 'pending';

  // ─── Shared Prefs Keys ────────────────────────────────────
  static const String prefUserRole = 'user_role';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefBiometricEnabled = 'biometric_enabled';

  // ─── Animation Durations ──────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 800);
  static const Duration animPulse = Duration(seconds: 2);
}
