import 'dart:convert';
import '../device_registry.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:noticeboard/models/notification_token.dart';
import 'package:noticeboard/models/user_profile.dart';
import '../endpoints/urls.dart';
import 'package:http/http.dart' as http;
import '../../models/user_tokens.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final storage = new FlutterSecureStorage();

  Future<void> initHandle() async {
    AccessToken accessTokenObj = await fetchAccessTokenFromRefresh();
    await storeAccessToken(accessTokenObj);
  }

  Future<RefreshToken> fetchUserTokens(dynamic obj) async {
    try {
      final http.Response postResponse = await http.post(
          Uri.parse(BASE_URL + EP_REFRESH_TOKEN),
          headers: {CONTENT_TYPE_KEY: CONTENT_TYPE},
          body: jsonEncode(obj));
      if (postResponse.statusCode == 200) {
        return RefreshToken.fromJSON(jsonDecode(postResponse.body));
      } else {
        throw Exception('Login Failed');
      }
    } catch (e) {
      throw Exception('Login Failed');
    }
  }

  Future storeRefreshToken(RefreshToken userRefreshToken) async {
    await storage.write(
        key: "refreshToken", value: userRefreshToken.refreshToken);
  }

  Future storeAccessToken(AccessToken userAccessToken) async {
    await storage.write(key: "accessToken", value: userAccessToken.accessToken);
  }

  Future storeProfile(UserProfile userProfile,
      {String? enrollmentNumber}) async {
    if (userProfile.picUrl != null) {
      await storage.write(key: "picUrl", value: BASE_URL + userProfile.picUrl!);
    } else {
      await storage.write(key: "picUrl", value: "");
    }
    await storage.write(key: "fullName", value: userProfile.fullName);
    await storage.write(key: "degreeName", value: userProfile.degreeName);
    await storage.write(key: "currentYear", value: userProfile.currentYear);
    await storage.write(key: "branchName", value: userProfile.branchName);
    if (enrollmentNumber != null && enrollmentNumber.trim().isNotEmpty) {
      await storage.write(
          key: "registryEnrollmentNumber", value: enrollmentNumber.trim());
    }
  }

  Future storeNotificationIdentifier(String? notificationIdentifier) async {
    await storage.write(
        key: "notificationIdentifier", value: notificationIdentifier);
  }

  Future<UserProfile> fetchProfileFromStorage() async {
    String? picUrl = await storage.read(key: "picUrl");
    String? fullName = await storage.read(key: "fullName");
    String? degreeName = await storage.read(key: "degreeName");
    String? currentYear = await storage.read(key: "currentYear");
    String? branchName = await storage.read(key: "branchName");
    UserProfile userProfile = UserProfile(
        picUrl: picUrl,
        fullName: fullName,
        degreeName: degreeName,
        currentYear: currentYear,
        branchName: branchName);
    return userProfile;
  }

  Future<RefreshToken> fetchRefreshToken() async {
    String? refreshToken = await storage.read(key: "refreshToken");

    return RefreshToken(refreshToken: refreshToken);
  }

  Future<String?> fetchNotificationIdentifier() async {
    String? notificationIdentifier =
        await storage.read(key: "notificationIdentifier");
    return notificationIdentifier;
  }

  Future<AccessToken> fetchAccessToken() async {
    String? accessToken = await storage.read(key: "accessToken");

    return AccessToken(accessToken: accessToken);
  }

  Future deleteRefreshToken() async {
    DeviceRegistry.instance.endSession();
    await storage.deleteAll();
  }

  Future<AccessToken> fetchAccessTokenFromRefresh() async {
    try {
      RefreshToken refreshTokenObj = await fetchRefreshToken();

      var refreshObj = {"refresh": refreshTokenObj.refreshToken};
      final http.Response postResponse = await http.post(
          Uri.parse(BASE_URL + EP_ACCESS_TOKEN),
          headers: {CONTENT_TYPE_KEY: CONTENT_TYPE},
          body: jsonEncode(refreshObj));

      if (postResponse.statusCode == 200) {
        return AccessToken.fromJSON(jsonDecode(postResponse.body));
      } else {
        throw Exception('Unable to Access');
      }
    } catch (e) {
      throw Exception('Unable to Access');
    }
  }

  Future<DeviceRegistryIdentity?> loadDeviceRegistryIdentity() async {
    final enrollmentNumber =
        await storage.read(key: "registryEnrollmentNumber");
    final name = await storage.read(key: "fullName");
    if (enrollmentNumber == null ||
        !RegExp(r'^\d{8}$').hasMatch(enrollmentNumber.trim()) ||
        name == null ||
        name.trim().isEmpty) {
      return null;
    }
    return DeviceRegistryIdentity(
      name: name.trim(),
      enrollmentNumber: enrollmentNumber.trim(),
    );
  }

  Future<void> reportDeviceActivityOpened() async {
    try {
      final identity = await loadDeviceRegistryIdentity();
      await DeviceRegistry.instance.opened(identity);
    } catch (_) {
      // Device activity reporting must not affect app startup or navigation.
    }
  }

  Future<UserProfile> fetchUserProfile() async {
    //AccessToken accessTokenObj = await fetchAccessTokenFromRefresh();
    try {
      AccessToken accessTokenObj = await fetchAccessToken();
      final http.Response userProfileResponse = await http
          .get(Uri.parse(BASE_URL + EP_WHO_AM_I), headers: {
        AUTHORIZAION_KEY: AUTHORIZATION_PREFIX + accessTokenObj.accessToken!
      });

      if (userProfileResponse.statusCode == 200) {
        return UserProfile.fromJSON(jsonDecode(userProfileResponse.body));
      } else {
        throw Exception('Unable to fetch profile of user');
      }
    } catch (e) {
      throw Exception('Unable to fetch profile of user');
    }
  }

  Future registerNotificationToken({String? token}) async {
    try {
      AccessToken accessTokenObj =
          // await _authService.fetchAccessTokenFromRefresh();
          await fetchAccessToken();
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('[push] permission=${permission.authorizationStatus.name}');
      token ??= await FirebaseMessaging.instance.getToken();
      print('[push] FCM token available=${token != null && token.isNotEmpty}');
      if (token == null) {
        throw Exception('FCM token unavailable');
      }
      String? clientIdentifier = await fetchNotificationIdentifier();
      NotificationToken notificationToken = NotificationToken(
        token,
        clientIdentifier: clientIdentifier,
      );
      await storeNotificationIdentifier(notificationToken.clientIdentifier);
      final http.Response postResponse =
          await http.post(Uri.parse(BASE_URL + NOTIFICATION_EP),
              headers: {
                AUTHORIZAION_KEY:
                    AUTHORIZATION_PREFIX + accessTokenObj.accessToken!,
                CONTENT_TYPE_KEY: CONTENT_TYPE
              },
              body: jsonEncode(notificationToken.retrievePayload()));
      print('[push] registration HTTP ${postResponse.statusCode}');
      if (postResponse.statusCode != 201) {
        throw Exception(
            'Notification registration HTTP ${postResponse.statusCode}');
      }
      print("SUCCESSFULLY REGISTERED");
    } catch (e) {
      print('[push] registration failed (${e.runtimeType})');
      rethrow;
    }
  }

  void listenForNotificationTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await registerNotificationToken(token: token);
      } catch (e) {
        print('Unable to register refreshed notification token: $e');
      }
    });
  }

  Future deRegisterNotificationToken() async {
    try {
      AccessToken accessTokenObj =
          // await _authService.fetchAccessTokenFromRefresh();
          await fetchAccessToken();
      String? notificationIdentifier = await fetchNotificationIdentifier();

      final request =
          http.Request("DELETE", Uri.parse(BASE_URL + NOTIFICATION_EP));
      request.headers.addAll(<String, String>{
        AUTHORIZAION_KEY: AUTHORIZATION_PREFIX + accessTokenObj.accessToken!,
        CONTENT_TYPE_KEY: CONTENT_TYPE
      });
      request.body = jsonEncode(
          {"client_identifier": notificationIdentifier, "token": "token"});

      final response = await request.send();
      if (response.statusCode != 204) {
        throw Exception('Failure');
      }
      print("SUCCESSFULLY DEREGISTERED");
    } catch (e) {
      print(e.toString());
      throw Exception('Failure');
    }
  }
}
