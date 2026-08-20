import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../theme/colors.dart';
import '../widgets/titan_glass_panel.dart';
import '../services/api_service.dart';
import 'status_creator_screen.dart';
import 'camera_screen.dart';
import 'newsletter_screen.dart';

class StatusScreen extends StatefulWidget {
  final List<UserStatus> statuses;
  final UserProfile? userProfile;
  final Function(String text, String? mediaUrl)? onCreateStatus;

  const StatusScreen({
    super.key,
    required this.statuses,
    this.userProfile,
    this.onCreateStatus,
  });

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  void _openStatusViewer(UserStatus userStatus, bool isMyStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => _WhatsAppStatusViewerModal(
        userStatus: userStatus,
        isMyStatus: isMyStatus,
        onReply: (replyText) {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.openChat(userStatus.contactId);
          appState.sendMessage('Replying to status: $replyText');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply sent!')),
          );
        },
      ),
    );
  }

  void _openTextStatusCreator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusCreatorScreen(
          onStatusCreated: (text, mediaUrl, bgColor, fontStyle) {
            widget.onCreateStatus?.call(text, mediaUrl);
          },
        ),
      ),
    );
  }

  void _openCameraStatusCreator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          onMediaCaptured: (path, caption) {
            widget.onCreateStatus?.call(caption, path);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Build personal status object if user has status items
    final myStatus = widget.statuses.firstWhere(
      (s) => s.contactId == (widget.userProfile?.id ?? 'me'),
      orElse: () => UserStatus(
        contactId: widget.userProfile?.id ?? 'me',
        userName: widget.userProfile?.name ?? 'My Status',
        userAvatar: widget.userProfile?.avatar ?? '',
        items: [],
      ),
    );

    final contactStatuses = widget.statuses.where((s) => s.contactId != (widget.userProfile?.id ?? 'me')).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pencil Text Status FAB
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: 'fab_text_status',
                backgroundColor: AppColors.surface,
                elevation: 3,
                onPressed: _openTextStatusCreator,
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ),
            // Camera Status FAB
            FloatingActionButton(
              heroTag: 'fab_camera_status',
              backgroundColor: AppColors.primary,
              elevation: 4,
              onPressed: _openCameraStatusCreator,
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 24),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Updates',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: Colors.white70),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
                    onPressed: _openCameraStatusCreator,
                  ),
                ],
              ),
            ),

            // My Status Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: InkWell(
                onTap: () {
                  if (myStatus.items.isNotEmpty) {
                    _openStatusViewer(myStatus, true);
                  } else {
                    _openTextStatusCreator();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: TitanGlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: myStatus.items.isNotEmpty
                                  ? Border.all(color: AppColors.primary, width: 2.5)
                                  : null,
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundImage: widget.userProfile?.avatar != null && widget.userProfile!.avatar.isNotEmpty
                                  ? NetworkImage(ApiService.resolveUrl(widget.userProfile!.avatar))
                                  : null,
                              backgroundColor: AppColors.primary,
                              child: widget.userProfile?.avatar == null || widget.userProfile!.avatar.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white, size: 26)
                                  : null,
                            ),
                          ),
                          if (myStatus.items.isEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.black, size: 18),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              myStatus.items.isNotEmpty
                                  ? 'Tap to view your status update'
                                  : 'Tap to add status update',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (myStatus.items.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                          onPressed: () => _openStatusViewer(myStatus, true),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Recent Updates Label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Recent Updates',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Contact Statuses List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  if (contactStatuses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No recent updates from contacts',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                        ),
                      ),
                    ),
                  ...contactStatuses.map((status) {
                    final latestItem = status.items.isNotEmpty ? status.items.first : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _openStatusViewer(status, false),
                        borderRadius: BorderRadius.circular(16),
                        child: TitanGlassPanel(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2.5),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: status.userAvatar.isNotEmpty
                                      ? NetworkImage(ApiService.resolveUrl(status.userAvatar))
                                      : null,
                                  backgroundColor: AppColors.primary,
                                  child: status.userAvatar.isEmpty
                                      ? Text(status.userName.isNotEmpty ? status.userName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      status.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      latestItem?.contentText ?? 'Photo/Video Status',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                latestItem?.createdAt ?? 'Recent',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // WhatsApp Channels Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Channels',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsletterScreen()));
                        },
                        child: const Text(
                          'Explore >',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Demo Channels List Cards
                  _buildChannelCard('Tech Insider Global', '14.2K Followers', '⚡ Quantum WebRTC protocol live update...', 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=150&q=80'),
                  const SizedBox(height: 10),
                  _buildChannelCard('GebTalk Official Channel', '89.2K Followers', '🎉 GebTalk v3.0 release is now live!', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=150&q=80'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(String name, String followers, String lastPost, String avatar) {
    bool isFollowing = false;
    return StatefulBuilder(
      builder: (context, setCardState) {
        return TitanGlassPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(lastPost, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isFollowing ? Colors.grey : AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () {
                  setCardState(() {
                    isFollowing = !isFollowing;
                  });
                },
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(color: isFollowing ? Colors.grey : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full WhatsApp-Style Story Viewer Modal with Progress Bar, Hold-to-Pause, Reply, and Viewers Sheet
class _WhatsAppStatusViewerModal extends StatefulWidget {
  final UserStatus userStatus;
  final bool isMyStatus;
  final Function(String replyText)? onReply;

  const _WhatsAppStatusViewerModal({
    required this.userStatus,
    required this.isMyStatus,
    this.onReply,
  });

  @override
  State<_WhatsAppStatusViewerModal> createState() => _WhatsAppStatusViewerModalState();
}

class _WhatsAppStatusViewerModalState extends State<_WhatsAppStatusViewerModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentIndex = 0;
  bool _isPaused = false;
  final TextEditingController _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _recordView();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  void _recordView() {
    if (!widget.isMyStatus && widget.userStatus.items.isNotEmpty) {
      final item = widget.userStatus.items[_currentIndex];
      final appState = Provider.of<AppState>(context, listen: false);
      appState.recordStatusView(item.id);
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.userStatus.items.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _recordView();
      _animController.reset();
      _animController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _recordView();
      _animController.reset();
      _animController.forward();
    } else {
      _animController.reset();
      _animController.forward();
    }
  }

  void _pause() {
    setState(() => _isPaused = true);
    _animController.stop();
  }

  void _resume() {
    setState(() => _isPaused = false);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.userStatus.items;
    final currentItem = items.isNotEmpty ? items[_currentIndex] : null;

    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Media / Text Main Display
              Positioned.fill(
                child: Center(
                  child: currentItem?.mediaUrl != null && currentItem!.mediaUrl!.isNotEmpty
                      ? Image.network(
                          ApiService.resolveUrl(currentItem.mediaUrl!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38, size: 64),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            currentItem?.contentText ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ),
                ),
              ),

              // Top Multi-Segment Progress Bars
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(items.length, (idx) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            double fillVal = 0.0;
                            if (idx < _currentIndex) {
                              fillVal = 1.0;
                            } else if (idx == _currentIndex) {
                              fillVal = _animController.value;
                            }
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: fillVal,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Header Row (Avatar, Name, Time, Close)
              Positioned(
                top: 24,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      backgroundImage: widget.userStatus.userAvatar.isNotEmpty
                          ? NetworkImage(ApiService.resolveUrl(widget.userStatus.userAvatar))
                          : null,
                      child: widget.userStatus.userAvatar.isEmpty
                          ? Text(widget.userStatus.userName.isNotEmpty ? widget.userStatus.userName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userStatus.userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            currentItem?.createdAt ?? 'Just now',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Bottom Section: Reply Bar (for contact status) OR Viewer Count (for my status)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: widget.isMyStatus
                    ? InkWell(
                        onTap: () => _showViewersSheet(context, currentItem?.id ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Swipe up to see viewers',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _replyCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    widget.onReply?.call(val.trim());
                                    Navigator.pop(context);
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Reply...',
                                  hintStyle: TextStyle(color: Colors.white60),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                              onPressed: () {
                                if (_replyCtrl.text.trim().isNotEmpty) {
                                  widget.onReply?.call(_replyCtrl.text.trim());
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewersSheet(BuildContext context, String statusId) async {
    _pause();
    final appState = Provider.of<AppState>(context, listen: false);
    final viewers = await appState.getStatusViews(statusId);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.remove_red_eye_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Viewed by ${viewers.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No views yet', style: TextStyle(color: Colors.white54))),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final v = viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        backgroundImage: v['viewer_avatar'] != null ? NetworkImage(ApiService.resolveUrl(v['viewer_avatar'])) : null,
                        child: v['viewer_avatar'] == null ? Text(v['viewer_name'] != null ? v['viewer_name'][0].toUpperCase() : 'U') : null,
                      ),
                      title: Text(v['viewer_name'] ?? 'GebTalk User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(v['viewed_at'] ?? 'Recently', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ).whenComplete(() => _resume());
  }
}

