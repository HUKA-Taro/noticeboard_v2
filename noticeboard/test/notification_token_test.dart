import 'package:flutter_test/flutter_test.dart';
import 'package:noticeboard/models/notification_token.dart';

void main() {
  test('uses the client identifier separately from the FCM token', () {
    final notificationToken = NotificationToken(
      'fcm-token',
      clientIdentifier: 'device-identifier',
    );

    expect(notificationToken.retrievePayload(), {
      'client_identifier': 'device-identifier',
      'token': 'fcm-token',
    });
  });
}
