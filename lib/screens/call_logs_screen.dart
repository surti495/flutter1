import 'package:flutter/material.dart';
import '../models/call_log.dart';
import '../services/call_service.dart';

class CallLogsScreen extends StatefulWidget {
  @override
  _CallLogsScreenState createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  final CallService _callService = CallService();
  bool _isLoading = true;
  List<CallLog> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() => _isLoading = true);
      final logs = await _callService.getCallLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildLogCard(CallLog log) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.1),
      child: ListTile(
        title: Text(
          'Channel: ${log.channelName}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants: ${log.participants}', // Removed .join(", ")
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Duration: ${log.duration}', // Using duration string directly
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Started: ${_formatDateTime(log.startTime)}',
              style: TextStyle(color: Colors.white70),
            ),
            if (log.endTime != null)
              Text(
                'Ended: ${_formatDateTime(log.endTime!)}',
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Logs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.blueGrey.shade900],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!, style: TextStyle(color: Colors.red)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) =>
                          _buildLogCard(_logs[index]),
                    ),
                  ),
      ),
    );
  }
}
