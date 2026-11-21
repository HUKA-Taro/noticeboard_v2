import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CustomPushService {
  static const topics = {
    'noticeboard_v2_alerts': 'New and updated notices',
  };

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool defaultEnabled(String topic) => topic != 'placement_v2_deadlines';

  static const _storage = FlutterSecureStorage();
  static Future<bool> enabled(String topic) async =>
      (await _storage.read(key: 'push_$topic')) != 'false';
  static Future<void> _save(String topic, bool value) =>
      _storage.write(key: 'push_$topic', value: value.toString());

  static Future<void> setEnabled(String topic, bool value) async {
    await _save(topic, value);
    await _sync(topic, value);
  }

  static Future<void> _sync(String topic, bool value) async {
    if (!supported) return;
    final messaging = FirebaseMessaging.instance;
    if (!value) {
      await messaging.unsubscribeFromTopic(topic);
      return;
    }
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      await messaging.subscribeToTopic(topic);
    }
  }

  static Future<void> initialize() async {
    if (!supported) return;
    for (final topic in topics.keys) {
      try {
        await _sync(topic, await enabled(topic));
      } catch (error) {
        debugPrint('Unable to sync notification preference for $topic: $error');
      }
    }
  }
}
