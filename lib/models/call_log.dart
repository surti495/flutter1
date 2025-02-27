import 'package:intl/intl.dart';

class CallLog {
  final String channelName;
  final DateTime startTime;
  final DateTime? endTime;
  final String participants;
  final String duration;

  CallLog({
    required this.channelName,
    required this.startTime,
    this.endTime,
    required this.participants,
    required this.duration,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      channelName: json['channel_name'] as String,
      startTime: _parseDateTime(json['start_time']),
      endTime:
          json['end_time'] != null ? _parseDateTime(json['end_time']) : null,
      participants: json['participants'].toString(),
      duration: json['duration'].toString(),
    );
  }

  static DateTime _parseDateTime(String dateTimeStr) {
    try {
      // First try standard ISO format
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      try {
        // Get today's date
        final now = DateTime.now();

        // Parse the time part
        final dateFormat = DateFormat("hh:mm:ss a");
        final time = dateFormat.parse(dateTimeStr);

        // Combine today's date with the parsed time
        return DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
          time.second,
        );
      } catch (e) {
        print('Error parsing date: $dateTimeStr');
        return DateTime.now();
      }
    }
  }
}
