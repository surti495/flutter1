import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'video_call_page.dart';

class HomePage extends StatelessWidget {
  final NotificationService notificationService = NotificationService();
  final AuthService _authService = AuthService();

  Future<void> _handleLogout(BuildContext context) async {
    await _authService.deleteToken();
    await _authService.saveLoginState(false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _handleStartCall(BuildContext context) async {
    try {
      // First send the notification through Firebase
      await notificationService.sendTestNotification();

      // Navigate to video call page after notification is sent
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VideoCallPage(),
        ),
      );
    } catch (e) {
      // Show error message if notification fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate call: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Icon(Icons.home, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Welcome to the Homepage!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _handleStartCall(context),
              icon: Icon(Icons.video_call, size: 24),
              label: Text('Start Call', style: TextStyle(fontSize: 18)),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.white, size: 28),
                  onPressed: () => _handleLogout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
