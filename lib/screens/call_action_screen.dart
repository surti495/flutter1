import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
import 'video_call_page.dart';

class CallActionScreen extends StatefulWidget {
  final Map<String, dynamic>? callData;

  const CallActionScreen({Key? key, this.callData}) : super(key: key);

  @override
  CallActionScreenState createState() => CallActionScreenState();
}

class CallActionScreenState extends State<CallActionScreen> {
  @override
  void initState() {
    super.initState();
    print('CallActionScreen initialized with data: ${widget.callData}');
  }

  @override
  Widget build(BuildContext context) {
    final callData = widget.callData ??
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (callData == null) {
      print('ERROR: No call data provided');
      return Scaffold(
        appBar: AppBar(title: const Text('Call Error')),
        body: const Center(child: Text('No call data provided')),
      );
    }

    print('Building CallActionScreen with data: $callData');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Incoming Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icons.call_end,
                      color: Colors.red,
                      label: 'Decline',
                    ),
                    _buildActionButton(
                      onPressed: () async {
                        try {
                          print('Accepting call with data: $callData');
                          await Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoCallPage(
                                tokenData: {
                                  'token': callData['token'],
                                  'channelName': callData['channelName'],
                                  'uid': int.parse(callData['uid'].toString()),
                                  'caller_uid': int.parse(
                                      callData['caller_uid'].toString()),
                                  'is_caller': false,
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error joining call: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to join call: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icons.call,
                      color: Colors.green,
                      label: 'Accept',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed,
            iconSize: 30,
            padding: const EdgeInsets.all(15),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
