import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'dart:ui';

final _authService = AuthService();

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? token = data['token'];

        if (token != null) {
          await _authService.saveToken(token);
          await _authService.saveLoginState(true);

          await Future.delayed(Duration(milliseconds: 100));
          final notificationService = NotificationService();
          await notificationService.initialize();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.black.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorSnackBar('Invalid credentials. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black,
                  Colors.blueGrey.shade900,
                  Colors.indigo.shade900,
                ],
              ),
            ),
          ),
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // App Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white10,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Welcome Text
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            colors: [Colors.white, Colors.blue.shade200],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade100.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Email Field
                      _buildGlassTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_rounded,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      _buildGlassTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_rounded,
                        isPassword: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // Login Button
                      _buildGlassButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            loginUser();
                          }
                        },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Sign Up Link
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          'Don\'t have an account? Sign Up',
                          style: TextStyle(
                            color: Colors.blue.shade100.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Forgot Password Link
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/reset-password'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue.shade100.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: MaterialButton(
            onPressed: onPressed,
            height: 56,
            child: child,
          ),
        ),
      ),
    );
  }
}
