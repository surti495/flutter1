import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'video_call_page.dart';
import 'profile_screen.dart';

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
      await notificationService.sendTestNotification();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VideoCallPage(),
        ),
      );
    } catch (e) {
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header with profile preview
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.person),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
                SizedBox(height: 40),

                // Dashboard Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildDashboardItem(
                        context,
                        'Profile',
                        Icons.person,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        ),
                      ),
                      _buildDashboardItem(
                        context,
                        'Video Call',
                        Icons.video_call,
                        () => _handleStartCall(context),
                      ),
                      _buildDashboardItem(
                        context,
                        'Settings',
                        Icons.settings,
                        () {}, // TODO: Add settings functionality
                      ),
                      _buildDashboardItem(
                        context,
                        'Help',
                        Icons.help,
                        () {}, // TODO: Add help functionality
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
