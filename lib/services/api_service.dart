// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl =
      'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user/';

  static final AuthService _authService = AuthService();

  // Login API call
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse(baseUrl + 'login/');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<String?> getToken() async {
    return await _authService.getToken();
  }

  // Save token
  static Future<void> saveToken(String token) async {
    await _authService.saveToken(token);
  }

  // Clear token (for logout)
  static Future<void> logout() async {
    await _authService.deleteToken();
  }

  // Signup API call
  static Future<http.Response> signup(
    String email,
    String name,
    String password,
    String password2,
  ) async {
    final url = Uri.parse(baseUrl + 'register/');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'name': name,
        'password': password,
        'password2': password2,
      }),
    );
  }

  // Email verification API call
  static Future<http.Response> verifyEmail(String token) async {
    final url = Uri.parse(
        'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user/verify-email/$token');
    return await http.get(url);
  }

  // Reset Password

  static Future<http.Response> changePassword(
    String oldPassword,
    String password,
    String password2,
    AuthService authService,
  ) async {
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('No auth token found');
    }

    final url = Uri.parse(baseUrl + 'changepassword/');

    return await http.put(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'old_password': oldPassword,
        'password': password,
        'password2': password2,
      }),
    );
  }

  static Future<http.Response> sendPasswordResetOTP(String email) async {
    final url = Uri.parse(baseUrl + 'send-reset-password-email/');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
      }),
    );
  }

  static Future<http.Response> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String password,
    required String password2,
  }) async {
    final url = Uri.parse(baseUrl + 'verify-otp/');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'otp': otp,
        'password': password,
        'password2': password2,
      }),
    );
  }
}
