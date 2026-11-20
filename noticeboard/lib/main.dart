import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:noticeboard/services/notifications/custom_push_service.dart';
import './routes/routing_constants.dart';
import './routes/routing.dart';
import 'global/global_constants.dart';

@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[push] background message received; notification=${message.notification != null}; dataFields=${message.data.length}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(notificationBackgroundHandler);
  try {
    await CustomPushService.initialize();
  } catch (error) {
    debugPrint('[push] setup failed; app will continue without push: $error');
  }
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    const notifications = MethodChannel('noticeboard/notifications');
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('[push] foreground message received; notification=${message.notification != null}; dataFields=${message.data.length}');
      final notification = message.notification;
      if (notification == null) return;
      try {
        await notifications.invokeMethod('show', {
          'title': notification.title,
          'body': notification.body,
        });
      } on PlatformException catch (error) {
        debugPrint('Unable to display notification: ${error.code}');
      }
    });
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentScope = FocusScope.of(context);
        if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
          FocusManager.instance.primaryFocus!.unfocus();
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false,
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: MyRouter.generateRoute,
        onGenerateInitialRoutes: (initialRoute) => [
          MyRouter.generateRoute(
            RouteSettings(name: initialRoute),
          ),
        ],
        initialRoute: launchingRoute,
        scaffoldMessengerKey: snackKey,
        navigatorKey: navigatorKey,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
