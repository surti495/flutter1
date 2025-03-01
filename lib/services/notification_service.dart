import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/call_action_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

    if (message.data.containsKey('token') &&
        message.data.containsKey('channelName')) {
      // Show incoming call screen
      if (_navigatorKey?.currentState != null) {
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => CallActionScreen(
              callData: {
                'token': message.data['token'],
                'channelName': message.data['channelName'],
                'uid': int.parse(message.data['uid'] ?? '2'),
                'caller_uid': int.parse(message.data['caller_uid'] ?? '1'),
                'is_caller': false,
              },
            ),
          ),
        );
      }
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message received - Starting navigation process');

    try {
      // Extract call details from the message data
      Map<String, dynamic> callData = message.data;

      // Ensure uid is parsed correctly
      int uidValue = int.tryParse(callData['uid'] ?? '0') ?? 0;

      // Add a slight delay to ensure context is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_navigatorKey?.currentContext != null) {
          Navigator.pushReplacementNamed(
            _navigatorKey!.currentContext!,
            '/call-action',
            arguments: {
              'token': callData['token'],
              'channelName': callData['channelName'],
              'uid': uidValue,
              'is_caller': false, // This person is receiving the call
            },
          );
        }
      });
    } catch (e) {
      print('Background navigation exception: $e');
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse details) async {
    print('=== Notification Tap Handling ===');
    try {
      if (details.payload == null) {
        print('ERROR: No payload in notification');
        return;
      }

      // Parse and verify payload
      Map<String, dynamic> payload = json.decode(details.payload!);
      print('Parsed notification payload: $payload');

      if (!payload.containsKey('channelName') ||
          !payload.containsKey('token')) {
        print('ERROR: Missing required call data in payload');
        return;
      }

      // Navigate to call action screen
      if (_navigatorKey?.currentContext != null) {
        await Navigator.pushReplacement(
          _navigatorKey!.currentContext!,
          MaterialPageRoute(
            builder: (context) => CallActionScreen(
              callData: {
                'token': payload['token'],
                'channelName': payload['channelName'],
                'uid': 2, // Fixed UID for receiver
                'is_caller': false,
              },
            ),
          ),
        );
        print('Navigation to call action screen completed');
      } else {
        print('ERROR: Navigator context is null');
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  Future<void> sendCallNotification({
    required String token,
    required String channelName,
    required int uid,
    required int callerUid,
  }) async {
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) throw Exception('No auth token available');

      print('Sending notification with data:');
      print('Channel: $channelName');
      print('Receiver UID: $uid');
      print('Caller UID: $callerUid');

      final response = await http.post(
        Uri.parse(
            'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user/trigger-call/'),
        headers: {
          'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'channelName': channelName,
          'uid': uid,
          'caller_uid': callerUid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }
}
