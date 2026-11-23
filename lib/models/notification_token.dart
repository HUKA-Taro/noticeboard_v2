import 'dart:math';

class NotificationToken {
  String? token;
  String? clientIdentifier;

  NotificationToken(String? token, {String? clientIdentifier}) {
    this.token = token;
    this.clientIdentifier = clientIdentifier ?? genClientIdentifier();
  }

  String genClientIdentifier() {
    return getRandomString(50);
  }

  String getRandomString(int length) {
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  dynamic retrievePayload() {
    return {
      "client_identifier": this.clientIdentifier,
      "token": this.token,
    };
  }
}
