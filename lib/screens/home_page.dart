// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart'; // Make sure to create this file

class HomePage extends StatelessWidget {
  final NotificationService notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Clear any stored credentials here
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the Homepage!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20), // Add some spacing
            ElevatedButton(
              onPressed: () => notificationService.sendTestNotification(),
              child: Text('Send Test Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
