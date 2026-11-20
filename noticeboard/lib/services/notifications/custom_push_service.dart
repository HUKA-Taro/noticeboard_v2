import 'package:firebase_messaging/firebase_messaging.dart';

/// Receives alerts sent by the private Azure checker through our Firebase
/// project. Topics contain only public notice/result update announcements.
class CustomPushService {
  static const String topic = 'noticeboard_v2_alerts';

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      await messaging.subscribeToTopic(topic);
    }
  }
}
