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
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      participants: json['participants'].toString(),
      duration: json['duration'].toString(),
    );
  }
}
