import 'dart:ui';
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

  // Wraps the child widget in a glassmorphic container.
  Widget _glassmorphicContainer(
      {required Widget child, double borderRadius = 16.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLogCard(CallLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _glassmorphicContainer(
        child: ListTile(
          title: Text(
            'Channel: ${log.channelName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants: ${log.participants}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Duration: ${log.duration}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Started: ${_formatDateTime(log.startTime)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (log.endTime != null)
                Text(
                  'Ended: ${_formatDateTime(log.endTime!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          isThreeLine: true,
        ),
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
        title: const Text('Call Logs'),
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
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
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
