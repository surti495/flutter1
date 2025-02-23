import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/call_log.dart';

class CallService {
  final String baseUrl = 'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user';
  final AuthService _authService = AuthService();

  Future<List<CallLog>> getCallLogs({String? channelName}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No auth token found');

      String url = '$baseUrl/update-call-log/';
      if (channelName != null) {
        url += '?channel_name=$channelName';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Raw response data: $responseData'); // Debug print

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('call_logs')) {
            final data = responseData['call_logs'];
            if (data is List) {
              return data.map((json) {
                // Convert numeric values to strings if needed
                json['participants'] = json['participants']?.toString() ?? '0';
                json['duration'] = json['duration']?.toString() ?? '0';
                return CallLog.fromJson(json);
              }).toList();
            }
          }
        }
        throw Exception('Invalid response format: ${response.body}');
      } else {
        throw Exception('Failed to fetch call logs: ${response.body}');
      }
    } catch (e) {
      print('Error in getCallLogs: $e');
      throw Exception('Error fetching call logs: $e');
    }
  }
}
