import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_profile.dart';
import 'auth_service.dart';

class ProfileService {
  final String baseUrl = 'https://4dkf27s7-8000.inc1.devtunnels.ms/api';
  final AuthService _authService = AuthService();

  Future<UserProfile> getUserProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile/'), // Updated endpoint
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      print('Profile Response Status: ${response.statusCode}');
      print('Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  Future<void> updateProfilePicture(String imagePath) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No auth token found');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile/'), // Updated endpoint
      );

      // Add headers
      request.headers['Authorization'] = 'Token $token';

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imagePath),
      );

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile picture: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile picture: $e');
    }
  }

  Future<UserProfile> updateProfile({required String name}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name': name}),
      );

      print('Update Profile Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Update Profile Error: $e'); // Debug log
      throw Exception('Failed to update profile: $e');
    }
  }
}
