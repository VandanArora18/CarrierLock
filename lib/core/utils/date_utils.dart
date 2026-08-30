import 'package:intl/intl.dart';

/// Date/time formatting utilities for CarrierLock.
class AppDateUtils {
  AppDateUtils._();

  /// Format: "12 Jun, 2:45 PM"
  static String formatDateTime(DateTime dt) {
    return DateFormat('d MMM, h:mm a').format(dt);
  }

  /// Format: "12 Jun 2026"
  static String formatDate(DateTime dt) {
    return DateFormat('d MMM yyyy').format(dt);
  }

  /// Format: "2:45 PM"
  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  /// Format: "2m ago", "1h ago", "3d ago"
  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('d MMM').format(dt);
  }

  /// Format: "5:00" countdown timer
  static String formatCountdown(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if timestamp has expired
  static bool isExpired(DateTime expiresAt) {
    return DateTime.now().isAfter(expiresAt);
  }
}
