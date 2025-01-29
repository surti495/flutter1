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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoCallPage(),
                  ),
                );
              },
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
                  onPressed: () => _handleLogout(context), // Update this line
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
