import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';

class VideoCallPage extends StatefulWidget {
  final Map<String, dynamic>? tokenData;

  const VideoCallPage({Key? key, this.tokenData}) : super(key: key);

  @override
  VideoCallPageState createState() => VideoCallPageState();
}

class VideoCallPageState extends State<VideoCallPage> {
  final AuthService _authService = AuthService();
  final Set<int> _remoteUsers = {};
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMicMuted = false;
  bool _isVideoEnabled = true;
  final String baseUrl = 'https://4dkf27s7-8000.inc1.devtunnels.ms/api/user';
  String? token;
  String? channelName;
  int? uid;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // If tokenData is provided, use it directly
      if (widget.tokenData != null) {
        setState(() {
          token = widget.tokenData!['token'];
          channelName = widget.tokenData!['channel'];
          uid = widget.tokenData!['uid'];
        });
      } else {
        // Otherwise, fetch a new token
        await getToken();
      }

      await initAgora();
    } catch (e) {
      print('Error initializing call: $e');
      _showError('Failed to initialize call');
    }
  }

  Future<void> getToken() async {
    final authToken = await _authService.getToken();
    if (authToken == null) {
      throw Exception('No auth token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/generate-token/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $authToken',
      },
      body: json.encode({
        'channel_name': 'default_channel',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        token = data['token'];
        channelName = data['channel'];
        uid = data['uid'];
      });
    } else {
      throw Exception('Failed to generate token');
    }
  }

  Future<void> updateCallLog(String action) async {
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) return;

      await http.post(
        Uri.parse('$baseUrl/update-call-log/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: json.encode({
          'channel_name': channelName,
          'action': action,
        }),
      );
    } catch (e) {
      debugPrint('Error updating call log: $e');
    }
  }

  // Update the RtcEngineEventHandler to handle multiple users
  Future<void> initAgora() async {
    if (token == null || channelName == null || uid == null) {
      throw Exception('Token, channel name, or UID is null');
    }

    await [Permission.microphone, Permission.camera].request();

    _engine = await createAgoraRtcEngine();

    await _engine.initialize(const RtcEngineContext(
      appId: 'a6a6fbc1b29545daa4c8d23730c97fda',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('local user ${connection.localUid} joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUsers.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUsers.remove(remoteUid);
          });
          updateCallLog('leave');
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token!,
      channelId: channelName!,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: uid!,
    );
  }

  Future<void> _toggleMicrophone() async {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    await _engine.enableLocalAudio(!_isMicMuted);
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    await _engine.enableLocalVideo(_isVideoEnabled);
  }

  Future<void> _endCall() async {
    try {
      // Update call log before ending
      await updateCallLog('end');

      // Leave Agora channel
      await _dispose();

      setState(() {
        _localUserJoined = false;
        _remoteUsers.clear();
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Error ending call: $e');
      _showError('Failed to end call properly');
    }
  }

  @override
  void dispose() {
    _dispose().then((_) {
      super.dispose();
    }).catchError((error) {
      print('Error in dispose: $error');
      super.dispose();
    });
  }

  Future<void> _dispose() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
      // Update call log after successful disposal
      await updateCallLog('leave');
    } catch (e) {
      print('Error in dispose: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update the build method to show multiple remote videos
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Video Call'),
        ),
        body: Stack(
          children: [
            // Background with blur effect
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.grey[900]!],
                ),
              ),
            ),

            // Grid of remote videos
            _remoteUsers.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for participants...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          _getGridCrossAxisCount(_remoteUsers.length),
                      childAspectRatio: 3 / 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _remoteUsers.length,
                    itemBuilder: (context, index) {
                      return _buildRemoteVideo(_remoteUsers.elementAt(index));
                    },
                  ),

            // Local video preview
            Positioned(
              right: 16,
              top: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            // Control buttons with glassmorphic design
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  // Helper method to build individual remote video
  Widget _buildRemoteVideo(int uid) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: channelName ?? ''),
          ),
        ),
      ),
    );
  }

  // Helper method to determine grid layout
  int _getGridCrossAxisCount(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    return 3;
  }

  // Move control buttons to separate method
  Widget _buildControlButtons() {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGlassmorphicButton(
            onPressed: _toggleMicrophone,
            icon: _isMicMuted ? Icons.mic_off : Icons.mic,
            color: _isMicMuted ? Colors.red : Colors.blue,
          ),
          _buildGlassmorphicButton(
            onPressed: _endCall,
            icon: Icons.call_end,
            color: Colors.red,
          ),
          _buildGlassmorphicButton(
            onPressed: _toggleVideo,
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            color: _isVideoEnabled ? Colors.blue : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}
