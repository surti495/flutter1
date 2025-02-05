import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(VideoCallPage());

const appId = "a6a6fbc1b29545daa4c8d23730c97fda";
const token =
    "007eJxTYBAX0dq4pUVf9fsVucS7XwS3lP+Y5f15j63zdrcU1eVv9u1VYEg0SzRLS0o2TDKyNDUxTUlMNEm2SDEyNjc2SLY0T0tJfDBrYXpDICND3cZGJkYGCATxuRl8KxUCivKzUpNLDBkYAKsNI+o=";
const channel = "My Project1";

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({Key? key}) : super(key: key);

  @override
  VideoCallPageState createState() => VideoCallPageState();
}

class VideoCallPageState extends State<VideoCallPage> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMicMuted = false;
  bool _isVideoEnabled = true;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = await createAgoraRtcEngine();

    await _engine.initialize(const RtcEngineContext(
      appId: appId,
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
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
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
    await _dispose();
    setState(() {
      _localUserJoined = false;
      _remoteUid = null;
    });
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

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

            // Remote video
            Center(
              child: _remoteVideo(),
            ),

            // Local video preview
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
            ),

            // Control buttons with glassmorphic design
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
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
                      icon:
                          _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: _isVideoEnabled ? Colors.blue : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 18),
      );
    }
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
