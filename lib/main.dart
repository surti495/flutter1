// main.dart
import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/verification_page.dart';
import 'screens/home_page.dart';
import 'screens/video_call_page.dart';
import 'screens/password_reset_page.dart';
import 'screens/call_action_screen.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

// Create a global navigator key
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  //  Initialize NotificationService
  final notificationService = NotificationService();
  notificationService.setNavigatorKey(_navigatorKey);
  await notificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // Use the global navigator key
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: AuthCheckPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => HomePage(),
        '/reset-password': (context) => PasswordResetPage(),
        '/call-action': (context) => CallActionScreen(
              onAccept: () {
                Navigator.pushReplacementNamed(context, '/video-call');
              },
              onReject: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
        '/video-call': (context) => VideoCallPage(), // Add video call route
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/verify-email/') ?? false) {
          final token = settings.name!.split('/verify-email/')[1];
          return MaterialPageRoute(
            builder: (context) => VerificationPage(token: token),
          );
        }
        return null;
      },
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  @override
  _AuthCheckPageState createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _authService.getToken();
      final isLoggedIn = await _authService.getLoginState();

      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      if (token != null && isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Auth check error: $e');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              )
            : Container(),
      ),
    );
  }
}
