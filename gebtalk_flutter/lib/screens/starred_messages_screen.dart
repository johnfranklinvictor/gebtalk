import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';

/// WhatsApp Starred Messages Screen
class StarredMessagesScreen extends StatefulWidget {
  const StarredMessagesScreen({super.key});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  List<Message> _starredMessages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStarred();
  }

  Future<void> _fetchStarred() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final msgs = await appState.getStarredMessages();
    if (mounted) {
      setState(() {
        _starredMessages = msgs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Starred Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          : _starredMessages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _starredMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _starredMessages[index];
                    return _buildStarredMessageCard(msg, appState);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'No starred messages',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap and hold on any message in a chat and tap the star icon to bookmark it here for quick reference.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarredMessageCard(Message msg, AppState appState) {
    final contactMatch = appState.contacts.firstWhere(
      (c) => c.id == msg.contactId,
      orElse: () => Contact(id: msg.contactId, name: msg.contactId, phone: '', role: '', avatar: '', status: '', folder: '', unreadCount: 0, tags: []),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Contact Name & Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(contactMatch.name.isNotEmpty ? contactMatch.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.isUser ? 'You ➔ ${contactMatch.name}' : contactMatch.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        msg.time,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 20),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Message Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.isFile && msg.fileName != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Expanded(child: Text(msg.fileName!, style: const TextStyle(color: Colors.white, fontSize: 13))),
                        Text(msg.fileSize ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  )
                else if (msg.isAudio)
                  Row(
                    children: [
                      const Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Voice Note (${msg.duration ?? "0:30"})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  )
                else
                  Text(
                    msg.text,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                  ),
              ],
            ),
          ),

          // Jump to Chat Action
          InkWell(
            onTap: () {
              appState.openChat(msg.contactId);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDetailScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jump to conversation', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary.withValues(alpha: 0.9), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
