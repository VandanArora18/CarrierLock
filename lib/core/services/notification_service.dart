/// Notification service placeholder.
/// Implement your own push notification logic here.
class NotificationService {
  static Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    // TODO: Implement your push notification service
    throw UnimplementedError('Push notification service not configured');
  }
}
