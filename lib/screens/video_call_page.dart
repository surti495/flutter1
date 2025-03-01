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
  bool _isCaller = false;

  @override
  void initState() {
    super.initState();
    print('VideoCallPage initialized with tokenData: ${widget.tokenData}');
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      print('Initializing call with tokenData: ${widget.tokenData}');

      if (widget.tokenData != null) {
        // Parse uid as int explicitly
        final receivedUid = widget.tokenData!['uid'];
        setState(() {
          token = widget.tokenData!['token'];
          channelName = widget.tokenData!['channelName'];
          uid = receivedUid is String ? int.parse(receivedUid) : receivedUid;
          _isCaller = widget.tokenData!['is_caller'] ?? false;
        });

        print('Call initialization details:');
        print('Token: ${token?.substring(0, 20)}...');
        print('Channel: $channelName');
        print('UID: $uid');
        print('Is Caller: $_isCaller');

        await initAgora();

        // Update call log based on role
        if (!_isCaller) {
          await updateCallLog('join');
        }
      } else {
        throw Exception('No token data provided');
      }
    } catch (e) {
      print('Error initializing call: $e');
      _showError('Failed to initialize call: ${e.toString()}');
    }
  }

  Future<void> updateCallLog(String action) async {
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) return;

      print('Updating call log - Action: $action, Channel: $channelName');

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

  Future<void> initAgora() async {
    try {
      // Request permissions first
      await [Permission.microphone, Permission.camera].request();

      // Initialize Agora engine
      _engine = await createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: 'a6a6fbc1b29545daa4c8d23730c97fda',
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set event handlers before joining channel
      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print(
              'Local user ${connection.localUid} joined channel ${connection.channelId}');
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print(
              'Remote user $remoteUid joined channel ${connection.channelId}');
          setState(() => _remoteUsers.add(remoteUid));
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print('Remote user $remoteUid left channel');
          setState(() => _remoteUsers.remove(remoteUid));
        },
      ));

      // Enable video and start preview
      await _engine.enableVideo();
      await _engine.startPreview();

      // Join channel with specific options
      await _engine.joinChannel(
        token: token!,
        channelId: channelName!,
        uid: uid!,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      print('Successfully initialized Agora with:');
      print('Channel: $channelName');
      print('UID: $uid');
      print('Is Caller: $_isCaller');

      // Update call log for receiver
      if (!_isCaller) {
        await updateCallLog('join');
      }
    } catch (e) {
      print('Error in initAgora: $e');
      _showError('Failed to initialize video call: $e');
    }
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
      // Update call log with 'end' only if this is the caller
      // Otherwise, just use 'leave'
      await updateCallLog(_isCaller ? 'end' : 'leave');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main video views
            _remoteUsers.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _buildGridVideoView(),

            // Local video view
            if (_localUserJoined)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

            // Control buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridVideoView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridCrossAxisCount(_remoteUsers.length),
      ),
      itemCount: _remoteUsers.length,
      itemBuilder: (context, index) {
        int remoteUid = _remoteUsers.elementAt(index);
        return Container(
          padding: const EdgeInsets.all(2),
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: remoteUid),
              connection: RtcConnection(channelId: channelName!),
            ),
          ),
        );
      },
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
