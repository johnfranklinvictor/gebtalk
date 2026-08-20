import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/email_models.dart';
import '../models/chat_models.dart';
import '../providers/app_state.dart';
import '../theme/colors.dart';
import '../widgets/email_compose_modal.dart';
import 'email_detail_screen.dart';
import 'chat_detail_screen.dart';

class EmailInboxScreen extends StatefulWidget {
  const EmailInboxScreen({super.key});

  @override
  State<EmailInboxScreen> createState() => _EmailInboxScreenState();
}

class _EmailInboxScreenState extends State<EmailInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFolder = 'inbox';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.fetchEmails(folder: _activeFolder);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFolderChanged(String folder) {
    setState(() => _activeFolder = folder);
    final appState = Provider.of<AppState>(context, listen: false);
    appState.fetchEmails(folder: folder, search: _searchController.text.trim());
  }

  void _onSearchChanged(String query) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.fetchEmails(folder: _activeFolder, search: query.trim(), silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final emails = appState.emails;
    final counts = appState.emailFolderCounts;
    final isLoading = appState.isLoadingEmails;

    final folders = [
      {'id': 'inbox', 'label': 'Inbox', 'icon': Icons.inbox_rounded, 'count': counts['inbox'] ?? 0},
      {'id': 'sent', 'label': 'Sent', 'icon': Icons.send_rounded, 'count': counts['sent'] ?? 0},
      {'id': 'starred', 'label': 'Starred', 'icon': Icons.star_rounded, 'count': counts['starred'] ?? 0},
      {'id': 'drafts', 'label': 'Drafts', 'icon': Icons.drafts_rounded, 'count': counts['drafts'] ?? 0},
      {'id': 'trash', 'label': 'Trash', 'icon': Icons.delete_outline_rounded, 'count': counts['trash'] ?? 0},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mail_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Email Inbox',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            if (appState.unreadEmailCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${appState.unreadEmailCount} new',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: () => appState.fetchEmails(folder: _activeFolder, search: _searchController.text.trim()),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search emails, senders, keywords...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Folder Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: folders.map((f) {
                final isSelected = f['id'] == _activeFolder;
                final count = f['count'] as int;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          f['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white24 : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    onSelected: (_) => _onFolderChanged(f['id'] as String),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Email List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : emails.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mark_email_read_rounded, color: Colors.white30, size: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No emails in ${_activeFolder.toUpperCase()}',
                              style: const TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your mailbox is up to date',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => appState.fetchEmails(folder: _activeFolder, search: _searchController.text.trim()),
                        color: const Color(0xFF3B82F6),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: emails.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final email = emails[i];
                            return _buildEmailCard(context, email, appState);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => EmailComposeModal.show(context),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('Compose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildEmailCard(BuildContext context, EmailMessage email, AppState appState) {
    final isUnread = !email.isRead;
    final senderInitial = email.fromName.isNotEmpty ? email.fromName[0].toUpperCase() : '?';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => EmailDetailScreen(emailId: email.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFF1E293B)
              : const Color(0xFF131D2E).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isUnread
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                  : const Color(0xFF334155),
              child: Text(
                senderInitial,
                style: TextStyle(
                  color: isUnread ? const Color(0xFF60A5FA) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name + Time
                  Row(
                    children: [
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          email.fromName,
                          style: TextStyle(
                            color: isUnread ? Colors.white : Colors.white70,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        email.receivedAt.split(',').last.trim(),
                        style: TextStyle(
                          color: isUnread ? const Color(0xFF60A5FA) : Colors.white38,
                          fontSize: 11,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Subject
                  Text(
                    email.subject,
                    style: TextStyle(
                      color: isUnread ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Body snippet
                  Text(
                    email.bodyText.replaceAll('\n', ' '),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Badges (Attachments + Quick Chat)
                  Row(
                    children: [
                      if (email.hasAttachments)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file_rounded, color: Colors.white70, size: 12),
                              SizedBox(width: 4),
                              Text('Attachment', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const Spacer(),

                      // 1-Tap Chat Shortcut
                      InkWell(
                        onTap: () async {
                          final res = await appState.convertEmailToChat(email.id);
                          if (context.mounted && res != null && res['contact'] != null) {
                            final contact = Contact.fromJson(res['contact']);
                            appState.selectContact(contact.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const ChatDetailScreen(),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 12),
                              SizedBox(width: 3),
                              Text('Chat', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Star Button
                      GestureDetector(
                        onTap: () => appState.toggleEmailStar(email.id),
                        child: Icon(
                          email.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: email.isStarred ? const Color(0xFFF59E0B) : Colors.white30,
                          size: 18,
                        ),
                      ),
                    ],
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
