import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class GuestMeetScreen extends StatefulWidget {
  final String meetingId;

  const GuestMeetScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<GuestMeetScreen> createState() => _GuestMeetScreenState();
}

class _GuestMeetScreenState extends State<GuestMeetScreen> {
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _meetingInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // Pre-join media state
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isJoining = false;
  bool _isInMeeting = false;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  int _meetingDuration = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _fetchMeetingInfo();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _startLocalMedia();
  }

  Future<void> _startLocalMedia() async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        }
      };

      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = stream;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error starting media: $e');
    }
  }

  Future<void> _fetchMeetingInfo() async {
    final info = await ApiService.getEmailMeetingInfo(widget.meetingId);
    if (!mounted) return;
    if (info != null) {
      setState(() {
        _meetingInfo = info;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Meeting not found or has expired.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final enabled = !videoTracks.first.enabled;
        videoTracks.first.enabled = enabled;
        setState(() => _isCameraOn = enabled);
      }
    }
  }

  void _toggleMic() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final enabled = !audioTracks.first.enabled;
        audioTracks.first.enabled = enabled;
        setState(() => _isMicOn = enabled);
      }
    }
  }

  Future<void> _joinMeeting() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to join the call')),
      );
      return;
    }

    setState(() => _isJoining = true);

    final res = await ApiService.joinEmailMeeting(
      meetingId: widget.meetingId,
      guestName: name,
    );

    if (!mounted) return;
    setState(() => _isJoining = false);

    if (res != null && res['success'] == true) {
      setState(() {
        _isInMeeting = true;
      });

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _meetingDuration++);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join meeting room')),
      );
    }
  }

  void _leaveMeeting() {
    ApiService.endEmailMeeting(widget.meetingId);
    setState(() {
      _isInMeeting = false;
      _meetingDuration = 0;
    });
    _durationTimer?.cancel();
    Navigator.of(context).pushReplacementNamed('/');
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E18),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E18),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isInMeeting) {
      return _buildMeetingRoom();
    }

    return _buildLobbyScreen();
  }

  // Pre-join Lobby View
  Widget _buildLobbyScreen() {
    final hostName = _meetingInfo?['host_name'] ?? 'GebTalk Staff Member';
    final subject = _meetingInfo?['subject'] ?? 'GebTalk HD Video Meeting';
    final callType = _meetingInfo?['call_type'] ?? 'video';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E18),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.electric_bolt_rounded, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GEBTALK MEET',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meeting Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${callType.toUpperCase()} MEETING',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'ID: ${widget.meetingId}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subject,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Host: $hostName',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Camera Preview Container
                  Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isCameraOn && _localStream != null)
                          RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.videocam_off_rounded, color: AppColors.primary, size: 32),
                              ),
                              const SizedBox(height: 10),
                              const Text('Camera is Off', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),

                        // Floating Media Controls
                        Positioned(
                          bottom: 12,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _toggleMic,
                                icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                                color: _isMicOn ? Colors.white : Colors.redAccent,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                onPressed: _toggleCamera,
                                icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                                color: _isCameraOn ? Colors.white : Colors.redAccent,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Input Field
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Enter your name to join...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Join Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinMeeting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.meeting_room, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Join Meeting Now',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Active Meeting Room View
  Widget _buildMeetingRoom() {
    final hostName = _meetingInfo?['host_name'] ?? 'GebTalk Staff Member';
    final subject = _meetingInfo?['subject'] ?? 'GebTalk HD Video Meeting';

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video Fullscreen / Grid
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            hostName.isNotEmpty ? hostName[0].toUpperCase() : 'H',
                            style: const TextStyle(color: Colors.black, fontSize: 44, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hostName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '🟢 HD Encrypted Stream Active',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Duration: ${_formatDuration(_meetingDuration)}',
                            style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.greenAccent, size: 12),
                          SizedBox(width: 4),
                          Text('E2EE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Local PiP Window
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _isCameraOn && _localStream != null
                    ? RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                    : const Center(
                        child: Icon(Icons.person, color: Colors.white38, size: 32),
                      ),
              ),
            ),

            // Bottom In-Call Controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic
                  IconButton(
                    onPressed: _toggleMic,
                    icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                    color: _isMicOn ? Colors.white : Colors.redAccent,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  // End Call (Red)
                  GestureDetector(
                    onTap: _leaveMeeting,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent, blurRadius: 16, spreadRadius: 1),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.call_end, color: Colors.white, size: 28),
                      ),
                    ),
                  ),

                  // Camera
                  IconButton(
                    onPressed: _toggleCamera,
                    icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                    color: _isCameraOn ? Colors.white : Colors.redAccent,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
