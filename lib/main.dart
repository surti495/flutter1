import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/verification_page.dart';
import 'screens/home_page.dart';
import 'screens/PasswordResetRequest.dart';
import 'screens/PasswordResetConfirmation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize FCM permissions here
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/reset-password': (context) => PasswordResetRequestPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/verify-email/') ?? false) {
          final token = settings.name!.split('/verify-email/')[1];
          return MaterialPageRoute(
            builder: (context) => VerificationPage(token: token),
          );
        }
        if (settings.name?.startsWith('/reset-password-confirm/') ?? false) {
          final uri = Uri.parse(settings.name!);
          final pathSegments = uri.pathSegments;

          if (pathSegments.length >= 3) {
            final uid = pathSegments[1];
            final token = pathSegments[2];

            return MaterialPageRoute(
              builder: (context) => PasswordResetPage(uid: uid, token: token),
            );
          }
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

      // Add a small delay to show the loading indicator
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
            : Container(), // Empty container when not loading
      ),
    );
  }
}
