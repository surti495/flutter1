import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
// import '../screens/video_call_page.dart';
// import '../screens/call_action_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription =
      'Channel for video call notifications';

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      await _initializeLocalNotifications();
      await _setupNotificationChannels();

      // Get and save FCM token
      String? token = await _firebaseMessaging.getToken();
      await sendTokenToServer(token);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(sendTokenToServer);

      // Handle incoming messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check for initial message (app was terminated)
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    }
  }

  Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> sendTokenToServer(String? token) async {
    if (token == null) return;

    try {
      final authToken = await _authService.getToken();
      if (authToken == null) {
        print('No auth token available');
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user/save-fcm-token/'),
        headers: {
          'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('FCM token saved: ${responseData['message']}');
      } else {
        print('Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message in foreground!');
    print('Message data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode({'type': 'video_call'}),
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('===============================');
    print('Background message received - Starting navigation process');

    try {
      // Add a slight delay to ensure context is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_navigatorKey?.currentContext != null) {
          print('Attempting to navigate from background message');
          Navigator.pushReplacementNamed(
            _navigatorKey!.currentContext!,
            '/call-action',
          ).then((_) {
            print('Background navigation completed successfully');
          }).catchError((error) {
            print('Background navigation error: $error');
          });
        } else {
          print('ERROR: No context available for background navigation');
        }
      });
    } catch (e) {
      print('Background navigation exception: $e');
    }
    print('===============================');
  }

  void _handleNotificationTap(NotificationResponse details) {
    print('===============================');
    print('Notification tapped - Starting navigation process');

    if (_navigatorKey?.currentContext == null) {
      print('ERROR: No valid context available');
      return;
    }

    try {
      // Add a slight delay to ensure context is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        print('Attempting to navigate to call action screen');
        print('Navigator Key: $_navigatorKey');
        print('Current Context: ${_navigatorKey!.currentContext}');
        print('Route Name: /call-action');

        Navigator.pushReplacementNamed(
          _navigatorKey!.currentContext!,
          '/call-action',
        ).then((_) {
          print('Navigation completed successfully');
        }).catchError((error) {
          print('Navigation error: $error');
        });
      });
    } catch (e) {
      print('Background navigation exception: $e');
    }
    print('===============================');
  }

  void navigateToCallActionScreen() {
    if (_navigatorKey?.currentContext == null) {
      print('No valid context available for navigation');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(_navigatorKey!.currentContext!)
          .pushReplacementNamed('/call-action');
    });
  }

  Future<void> sendTestNotification() async {
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) {
        print('No auth token available');
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user/trigger-call/'),
        headers: {
          'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Test notification sent successfully');
      } else {
        print('Failed to send test notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
