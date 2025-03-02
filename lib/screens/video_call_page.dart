import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
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
  final Set<int> _usersWithVideoOff = {};
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
            UserOfflineReasonType reason) async {
          print('Remote user $remoteUid left channel');
          setState(() => _remoteUsers.remove(remoteUid));

          // If caller left, end call for everyone
          if (_isCaller ? remoteUid == 2 : remoteUid == 1) {
            print('Main participant left, ending call for everyone');
            await _handleCallEnded();
          }
        },
        onConnectionStateChanged: (RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason) async {
          print('Connection state changed: $state, reason: $reason');

          // Handle disconnection
          if (state == ConnectionStateType.connectionStateDisconnected ||
              state == ConnectionStateType.connectionStateFailed) {
            await _handleCallEnded();
          }
        },
        onRemoteVideoStateChanged: (RtcConnection connection,
            int remoteUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed) {
          print('Remote video state changed for uid $remoteUid: $state');
          setState(() {
            if (state == RemoteVideoState.remoteVideoStateStopped) {
              _usersWithVideoOff.add(remoteUid);
            } else if (state == RemoteVideoState.remoteVideoStateDecoding) {
              _usersWithVideoOff.remove(remoteUid);
            }
          });
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
      if (_isCaller) {
        // If caller ends the call, update log as 'end'
        await updateCallLog('end');
      }

      // Handle call ending for everyone
      await _handleCallEnded();
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

  Future<void> _handleCallEnded() async {
    if (!mounted) return;

    try {
      // Update call log
      await updateCallLog('leave');

      // Leave channel and cleanup
      await _dispose();

      setState(() {
        _localUserJoined = false;
        _remoteUsers.clear();
      });

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Error handling call end: $e');
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

  /// A helper widget that creates a glassmorphic container using BackdropFilter.
  Widget _glassmorphicContainer(
      {required Widget child, double borderRadius = 16.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a gradient background for the glassmorphic effect
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 9, 5, 29), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main video views
              Positioned.fill(
                child: _remoteUsers.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _buildGridVideoView(),
              ),
              // Local video view in a glassmorphic container
              if (_localUserJoined)
                Positioned(
                  top: 20,
                  right: 20,
                  child: _glassmorphicContainer(
                    child: SizedBox(
                      width: 100,
                      height: 150,
                      child: !_isVideoEnabled
                          ? Container(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam_off,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Video Off',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : AgoraVideoView(
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
      ),
    );
  }

  Widget _buildGridVideoView() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridCrossAxisCount(_remoteUsers.length),
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _remoteUsers.length,
      itemBuilder: (context, index) {
        int remoteUid = _remoteUsers.elementAt(index);
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: _usersWithVideoOff.contains(remoteUid)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        color: Colors.white.withOpacity(0.5),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Video Off',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: remoteUid),
                      connection: RtcConnection(channelId: channelName!),
                    ),
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

  // Control buttons positioned at the bottom center
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
            color: _isMicMuted ? Colors.redAccent : Colors.blueAccent,
          ),
          _buildGlassmorphicButton(
            onPressed: _endCall,
            icon: Icons.call_end,
            color: Colors.redAccent,
          ),
          _buildGlassmorphicButton(
            onPressed: _toggleVideo,
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            color: _isVideoEnabled ? Colors.blueAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // Glassmorphic button with BackdropFilter
  Widget _buildGlassmorphicButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: _glassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
      ),
    );
  }
}
