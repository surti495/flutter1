// lib/screens/verification_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerificationPage extends StatefulWidget {
  final String? token;

  const VerificationPage({Key? key, this.token}) : super(key: key);

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool isLoading = true;
  String verificationMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _handleVerification(widget.token!);
    } else {
      setState(() {
        verificationMessage = 'No verification token found';
        isLoading = false;
      });
    }
  }

  Future<void> _handleVerification(String token) async {
    try {
      final response = await ApiService.verifyEmail(token);

      if (response.statusCode == 200) {
        setState(() {
          verificationMessage = 'Email successfully verified!';
        });
      } else {
        setState(() {
          verificationMessage = 'Verification failed. Invalid token.';
        });
      }
    } catch (e) {
      setState(() {
        verificationMessage = 'An error occurred. Please try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Email Verification')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(verificationMessage),
                  if (verificationMessage == 'Email successfully verified!')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: Text('Go to Login'),
                    ),
                ],
              ),
      ),
    );
  }
}
