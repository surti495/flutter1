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

  // Add method to update other profile fields
  Future<UserProfile> updateProfile({
    String? name,
    // Add other fields as needed
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          // Add other fields as needed
        }),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
