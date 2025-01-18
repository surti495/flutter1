// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

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

      final response = await http.post(
        Uri.parse(
            'https://4dkf27s7-8000.inc1.devtunnels.ms/user/api/save-fcm-token/'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      // ... rest of the code
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
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      // ... rest of the code
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
