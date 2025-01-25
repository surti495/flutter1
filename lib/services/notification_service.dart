import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBacgroundHandler(RemoteMessage message) async {
  print('Handling background message:${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBacgroundHandler);
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      String? token = await _firebaseMessaging.getToken();
      await sendTokenToServer(token);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(sendTokenToServer);

      // Handle incoming messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        _handleNotificationTap(details);
      },
    );
  }

  Future<String?> getAuthToken() async {
    return await _authService.getToken();
  }

  Future<void> sendTokenToServer(String? token) async {
    if (token == null) return;

    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        print('No auth token available');
        return;
      }
      print('Sending FCM token to server: $token'); // Debug log
      print('Using auth token: $authToken');

      final response = await http.post(
        Uri.parse(
            'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user/save-fcm-token/'),
        headers: {
          'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        print('FCM token successfully saved: ${responseData['message']}');
      } else {
        print('Failed to save FCM token: ${responseData['error']}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  Future<void> sendTestNotification() async {
    try {
      final authToken = await getAuthToken();
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

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: json.encode(message.data),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Handling background message: ${message.messageId}');
    // Handle background message - typically navigation
    _handleNotificationTap(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: json.encode(message.data),
      ),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      ),
      payload: payload,
    );
  }

  void _handleNotificationTap(NotificationResponse details) {
    if (details.payload != null) {
      try {
        final data = json.decode(details.payload!);
        // Handle navigation or other actions based on notification data
        print('Notification tapped with data: $data');
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }
}
