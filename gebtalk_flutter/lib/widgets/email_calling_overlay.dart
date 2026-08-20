import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/api_service.dart';
import '../services/webrtc_service.dart';
import '../theme/colors.dart';

class EmailCallingOverlay extends StatefulWidget {
  final String meetingId;
  final String recipientEmail;
  final String? recipientName;
  final String? subject;
  final String callType;
  final String joinUrl;
  final String pin;

  const EmailCallingOverlay({
    super.key,
    required this.meetingId,
    required this.recipientEmail,
    this.recipientName,
    this.subject,
    required this.callType,
    required this.joinUrl,
    required this.pin,
  });

  static Future<void> show(
    BuildContext context, {
    required String meetingId,
    required String recipientEmail,
    String? recipientName,
    String? subject,
    required String callType,
    required String joinUrl,
    required String pin,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => EmailCallingOverlay(
        meetingId: meetingId,
        recipientEmail: recipientEmail,
        recipientName: recipientName,
        subject: subject,
        callType: callType,
        joinUrl: joinUrl,
        pin: pin,
      ),
    );
  }

  @override
  State<EmailCallingOverlay> createState() => _EmailCallingOverlayState();
}

class _EmailCallingOverlayState extends State<EmailCallingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _statusCheckTimer;
  String _callStatus = 'ringing'; // 'ringing', 'connected', 'ended'
  bool _isCopied = false;
  bool _isResending = false;
  int _elapsedSeconds = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });

    _startMeetingStatusPolling();
  }

  void _startMeetingStatusPolling() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final info = await ApiService.getEmailMeetingInfo(widget.meetingId);
      if (!mounted) return;
      if (info != null) {
        final status = info['status'] as String?;
        if (status == 'connected' && _callStatus != 'connected') {
          setState(() => _callStatus = 'connected');
          
          // Connect webrtc call
          final webrtcService = Provider.of<WebRtcService>(context, listen: false);
          webrtcService.startCall(widget.meetingId, widget.recipientName ?? widget.recipientEmail);
        } else if (status == 'completed' || status == 'ended') {
          _endCall();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusCheckTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: widget.joinUrl));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    await ApiService.startEmailCall(
      recipientEmail: widget.recipientEmail,
      recipientName: widget.recipientName,
      subject: widget.subject,
      callType: widget.callType,
    );
    if (!mounted) return;
    setState(() => _isResending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email invite resent to ${widget.recipientEmail}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _endCall() {
    _statusCheckTimer?.cancel();
    ApiService.endEmailMeeting(widget.meetingId);
    Navigator.of(context, rootNavigator: true).pop();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (widget.recipientName != null && widget.recipientName!.isNotEmpty)
        ? widget.recipientName!
        : widget.recipientEmail.split('@')[0].toUpperCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _callStatus == 'connected' ? Colors.greenAccent : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _callStatus == 'connected'
                        ? '🟢 CLIENT CONNECTED (${_formatDuration(_elapsedSeconds)})'
                        : '⚡ CALLING VIA EMAIL (${_formatDuration(_elapsedSeconds)})',
                    style: TextStyle(
                      color: _callStatus == 'connected' ? Colors.greenAccent : AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Pulsing Avatar Radar
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(3, (index) {
                        final waveVal = (_pulseController.value + (index / 3.0)) % 1.0;
                        return Container(
                          width: 100 + waveVal * 80,
                          height: 100 + waveVal * 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: (1.0 - waveVal) * 0.4),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recipient Info
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.recipientEmail,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (widget.subject != null && widget.subject!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '“${widget.subject}”',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Live Calling Steps
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildStatusRow(
                    icon: Icons.mark_email_read_rounded,
                    title: 'Email Invitation Sent',
                    subtitle: 'Direct Google Meet-style link dispatched',
                    isDone: true,
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStatusRow(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Waiting for Client to Open Link',
                    subtitle: 'Works instantly on PC, iOS & Android',
                    isDone: _callStatus == 'connected',
                    isLoading: _callStatus == 'ringing',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Meeting ID & Direct Link Copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.joinUrl,
                      style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _copyLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isCopied ? Colors.green : AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isCopied ? 'Copied!' : 'Copy Link',
                        style: TextStyle(
                          color: _isCopied ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Resend Email Button
                IconButton(
                  onPressed: _isResending ? null : _resendEmail,
                  icon: const Icon(Icons.replay_rounded, color: Colors.white70),
                  tooltip: 'Resend Email Invite',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(14),
                  ),
                ),

                // End Call Button (Big Red)
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),

                // Copy Link Button
                IconButton(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                  tooltip: 'Copy Meeting Link',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isLoading = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDone ? Colors.greenAccent : AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          )
        else if (isDone)
          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
      ],
    );
  }
}
