import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';

/// WhatsApp Archived Chats Screen
class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final archivedIds = appState.chatPreferences.archived;
    final archivedContacts = appState.contacts.where((c) => archivedIds.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Archived Chats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: archivedContacts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.archive_outlined, color: AppColors.primary, size: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text('No archived chats', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Chats you archive will stay hidden from your main chat list until you unarchive them.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: archivedContacts.length,
              itemBuilder: (context, index) {
                final contact = archivedContacts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      backgroundImage: contact.avatar.isNotEmpty ? NetworkImage(ApiService.resolveUrl(contact.avatar)) : null,
                      child: contact.avatar.isEmpty ? Text(contact.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                    ),
                    title: Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text(
                      contact.lastMessage?.text ?? 'No messages yet',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.unarchive_rounded, color: AppColors.primary, size: 22),
                      tooltip: 'Unarchive Chat',
                      onPressed: () async {
                        await appState.toggleArchiveChat(contact.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unarchived ${contact.name}')),
                          );
                        }
                      },
                    ),
                    onTap: () {
                      appState.openChat(contact.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDetailScreen()));
                    },
                  ),
                );
              },
            ),
    );
  }
}
