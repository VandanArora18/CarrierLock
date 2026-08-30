/// Time-of-day greeting utilities.
class GreetingUtils {
  GreetingUtils._();

  /// Returns "Good morning", "Good afternoon", or "Good evening"
  /// based on the current hour.
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Returns a greeting emoji based on time of day.
  static String getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '🌙';
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 20) return '🌆';
    return '🌙';
  }
}
