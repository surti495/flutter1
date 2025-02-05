import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:ui';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> signupUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.signup(
        _emailController.text,
        _nameController.text,
        _passwordController.text,
        _password2Controller.text,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Signup successful! A verification email has been sent.'),
            backgroundColor: Colors.black.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context);
      } else {
        _showErrorSnackBar(
            'Email already exists or invalid input. Please try again.');
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
                      const SizedBox(height: 20),
                      // Back Button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          Icons.person_add,
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
                          'Create Account',
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
                        'Sign up to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade100.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Name Field
                      _buildGlassTextField(
                        controller: _nameController,
                        label: 'Name',
                        icon: Icons.person_rounded,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
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
                        passwordVisibility: _isPasswordVisible,
                        onTogglePasswordVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password Field
                      _buildGlassTextField(
                        controller: _password2Controller,
                        label: 'Confirm Password',
                        icon: Icons.lock_rounded,
                        isPassword: true,
                        passwordVisibility: _isConfirmPasswordVisible,
                        onTogglePasswordVisibility: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // Signup Button
                      _buildGlassButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            signupUser();
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
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Login Link
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Login',
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
    bool? passwordVisibility,
    VoidCallback? onTogglePasswordVisibility,
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
            obscureText: isPassword && !(passwordVisibility ?? false),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        passwordVisibility ?? false
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: onTogglePasswordVisibility,
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
