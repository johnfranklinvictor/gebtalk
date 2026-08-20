import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../theme/colors.dart';
import '../widgets/titan_glass_panel.dart';
import '../widgets/email_call_modal.dart';

class CallsScreen extends StatefulWidget {
  final List<CallLog> callLogs;
  final Function(Contact contact, bool isVideo)? onStartCall;

  const CallsScreen({
    super.key,
    required this.callLogs,
    this.onStartCall,
  });

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  String _selectedFilter = 'all'; // 'all' or 'missed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchCallLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final logsSource = appState.callLogs.isNotEmpty ? appState.callLogs : widget.callLogs;
    final displayedLogs = _selectedFilter == 'missed'
        ? logsSource.where((log) => log.direction == 'missed' || log.direction == 'declined').toList()
        : logsSource;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 4,
          onPressed: () => _showNewCallContactPicker(context, appState),
          child: const Icon(Icons.add_call, color: Colors.black, size: 24),
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
                    'Calls',
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
                ],
              ),
            ),

            // Email Video Call Banner Card (Google Meet Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: InkWell(
                onTap: () => EmailCallModal.show(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0C2A24),
                        Color(0xFF0F172A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.video_camera_front_rounded, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Email Video Call',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'MEET',
                                    style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Call clients with 1-click Google Meet email invite',
                              style: TextStyle(color: AppColors.primaryLight, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Create Call Link Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: InkWell(
                onTap: () => _showCreateCallLinkDialog(context, appState),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create call link',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Share a link for your GebTalk audio or video call',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter Chips Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterChip('All', _selectedFilter == 'all', () {
                    setState(() => _selectedFilter = 'all');
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Missed', _selectedFilter == 'missed', () {
                    setState(() => _selectedFilter = 'missed');
                  }),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Call History Section Label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Recent',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: displayedLogs.isEmpty
                  ? Center(
                      child: Text(
                        _selectedFilter == 'missed' ? 'No missed calls' : 'No call history yet',
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 120.0),
                      itemCount: displayedLogs.length,
                      itemBuilder: (context, index) {
                        final log = displayedLogs[index];
                        final isMissed = log.direction == 'missed';
                        final isOutgoing = log.direction == 'outgoing';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TitanGlassPanel(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: log.contactAvatar.isNotEmpty
                                      ? NetworkImage(log.contactAvatar)
                                      : null,
                                  backgroundColor: AppColors.primary,
                                  child: log.contactAvatar.isEmpty
                                      ? Text(log.contactName.isNotEmpty ? log.contactName[0].toUpperCase() : 'C',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.contactName,
                                        style: TextStyle(
                                          color: isMissed ? Colors.redAccent : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isOutgoing
                                                ? Icons.call_made
                                                : (isMissed ? Icons.call_missed : Icons.call_received),
                                            size: 14,
                                            color: isMissed
                                                ? Colors.redAccent
                                                : (isOutgoing ? AppColors.primaryLight : Colors.green),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${log.timeStr} ${log.duration != null ? "• ${log.duration}" : ""}',
                                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    log.callType == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    final contact = Contact(
                                      id: log.contactId,
                                      name: log.contactName,
                                      phone: '',
                                      role: '',
                                      avatar: log.contactAvatar,
                                      status: 'Online',
                                      folder: 'all',
                                      unreadCount: 0,
                                      tags: [],
                                    );
                                    widget.onStartCall?.call(contact, log.callType == 'video');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showCreateCallLinkDialog(BuildContext context, AppState appState) async {
    final linkResult = await appState.createCallLink(callType: 'video', linkName: 'GebTalk Meeting');
    final callUrl = linkResult?['call_url'] ?? 'https://gebtalk.app/call/link_123';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Call Link Created', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anyone with GebTalk can use this link to join your video or voice call.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      callUrl,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.black),
            label: const Text('Copy Link', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNewCallContactPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Contact to Call', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: appState.contacts.length,
                itemBuilder: (context, index) {
                  final c = appState.contacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(c.role, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_rounded, color: AppColors.primary, size: 22),
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onStartCall?.call(c, false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 22),
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onStartCall?.call(c, true);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

