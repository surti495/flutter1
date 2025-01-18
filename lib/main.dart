import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/verification_page.dart';
import 'screens/home_page.dart';
import 'screens/PasswordResetRequest.dart';
import 'screens/PasswordResetConfirmation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
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
