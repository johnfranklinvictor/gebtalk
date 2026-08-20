import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../utils/countries.dart';
import '../widgets/ebi_bot.dart';
import '../widgets/animations.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';
import 'group_create_screen.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';
import 'starred_messages_screen.dart';
import 'broadcast_screen.dart';
import 'community_screen.dart';
import 'newsletter_screen.dart';
import 'linked_devices_screen.dart';
import 'payment_screen.dart';
import 'archived_chats_screen.dart';
import 'calls_screen.dart';
import '../services/webrtc_service.dart';
import '../widgets/command_vault.dart';
import '../widgets/interactive_customer_card.dart';

class ChatListScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const ChatListScreen({super.key, this.onTabChanged});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _searchGlowController;
  late Animation<double> _searchGlowAnimation;

  String _sortBy = 'name'; // 'name' or 'recent'
  String? _expandedStaffId;

  @override
  void initState() {
    super.initState();

    // Search glow animation
    _searchGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _searchGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchGlowController, curve: Curves.easeInOut),
    );

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _searchGlowController.repeat(reverse: true);
      } else {
        _searchGlowController.reverse();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final contacts = appState.filteredContacts;
    final folders = appState.folders;
    final tags = appState.tags;

    Widget bodyWidget = _buildChatListView(appState, folders, tags, contacts);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Gradient App Bar ───
          _buildGradientHeader(appState),
          // ─── Body ───
          Expanded(
            child: Stack(
              children: [
                bodyWidget,
                // Universal WhatsApp Floating Action Button (Only for CEO and Manager)
                if (appState.canCreateAccounts)
                  Positioned(
                    bottom: 110,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: () => _showNewActionSheet(context, appState),
                        backgroundColor: AppColors.primary,
                        elevation: 4,
                        child: const Icon(
                          Icons.chat_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                EbiBot(
                  screen: 'chat_list',
                  onTabChanged: widget.onTabChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  GRADIENT HEADER WITH WHATSAPP 3-DOTS ACTION MENU
  // ─────────────────────────────────────────────────────────────
  Widget _buildGradientHeader(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF020408), Color(0xFF060A12), Color(0xFF0A0E18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Glowing icon with energy border
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GEBTALK',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Product Sans',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'SECURE COMMUNICATIONS',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      fontFamily: 'Product Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Camera Quick Action Button
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 22),
                tooltip: 'Camera',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CameraScreen(
                        onMediaCaptured: (path, caption) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Captured media ready: $caption')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              // Refresh Contacts Button
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
                tooltip: 'Refresh',
                onPressed: () => appState.refreshContacts(),
              ),
              // WhatsApp 3-Dots Popup Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) => _handleHeaderMenuAction(value, appState),
                itemBuilder: (context) => [
                  if (appState.canCreateAccounts)
                    const PopupMenuItem(
                      value: 'group',
                      child: Row(
                        children: [
                          Icon(Icons.group_add_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 12),
                          Text('New Group', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  if (appState.canCreateAccounts)
                    const PopupMenuItem(
                      value: 'broadcast',
                      child: Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 12),
                          Text('New Broadcast', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'communities',
                    child: Row(
                      children: [
                        Icon(Icons.groups_rounded, color: Colors.blueAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Communities', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'channels',
                    child: Row(
                      children: [
                        Icon(Icons.newspaper_rounded, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Channels & News', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'devices',
                    child: Row(
                      children: [
                        Icon(Icons.devices_rounded, color: Colors.purpleAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Linked Devices', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'calls',
                    child: Row(
                      children: [
                        Icon(Icons.call_rounded, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 12),
                        Text('Call Logs & VoIP', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'starred',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amberAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Starred Messages', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'payments',
                    child: Row(
                      children: [
                        Icon(Icons.payment_rounded, color: Colors.greenAccent, size: 20),
                        SizedBox(width: 12),
                        Text('GebTalk Payments', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded, color: Colors.white70, size: 20),
                        SizedBox(width: 12),
                        Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleHeaderMenuAction(String value, AppState appState) {
    switch (value) {
      case 'group':
        if (!appState.canCreateAccounts) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access restricted: Only CEO and Manager can create groups.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupCreateScreen()));
        break;
      case 'broadcast':
        if (!appState.canCreateAccounts) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access restricted: Only CEO and Manager can broadcast messages.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen()));
        break;
      case 'communities':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
        break;
      case 'channels':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsletterScreen()));
        break;
      case 'devices':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()));
        break;
      case 'calls':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallsScreen(
              callLogs: appState.callLogs,
              onStartCall: (contact, isVideo) {
                final webrtcService = Provider.of<WebRtcService>(context, listen: false);
                webrtcService.startCall(contact.id, contact.name, peerAvatar: contact.avatar);
              },
            ),
          ),
        );
        break;
      case 'starred':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredMessagesScreen()));
        break;
      case 'payments':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
        break;
      case 'settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  CHAT LIST VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildChatListView(AppState appState, List<Folder> folders, List<Tag> tags, List<Contact> contacts) {
    // Apply local sorting
    List<Contact> sortedContacts = List.from(contacts);
    if (_sortBy == 'name') {
      sortedContacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'recent') {
      // Sort by unread count first, then by last message ID (recent activity) descending, then by name
      sortedContacts.sort((a, b) {
        int cmp = b.unreadCount.compareTo(a.unreadCount);
        if (cmp != 0) return cmp;
        
        int bLastId = b.lastMessage?.id ?? 0;
        int aLastId = a.lastMessage?.id ?? 0;
        int timeCmp = bLastId.compareTo(aLastId);
        if (timeCmp != 0) return timeCmp;
        
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // â”€â”€â”€ Animated Search Bar â”€â”€â”€
              AnimatedBuilder(
                animation: _searchGlowAnimation,
                builder: (context, child) {
                  final glowValue = _searchGlowAnimation.value;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _searchFocusNode.hasFocus
                          ? [
                              BoxShadow(
                                color: AppColors.tealGlow.withValues(
                                  alpha: 0.15 + (glowValue * 0.12),
                                ),
                                blurRadius: 10 + (glowValue * 6),
                                spreadRadius: glowValue * 2,
                              ),
                            ]
                          : [],
                    ),
                    child: child,
                  );
                },
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontFamily: 'Product Sans',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    hintText: "Search conversations...",
                    hintStyle: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                      fontFamily: 'Product Sans',
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => appState.setSearchQuery(val),
                ),
              ),
              // ─── Folder Chips ───
              if (folders.isNotEmpty) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final allowedFolders = folders.where((f) {
                      if (appState.isCustomerRole) {
                        return f.id == 'all' || f.id == 'support';
                      }
                      if (appState.isStaffRole && !appState.isCeo && !appState.isManager) {
                        return f.id == 'all' || f.id == 'support' || f.id == 'customers';
                      }
                      return true;
                    }).toList();

                    return SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allowedFolders.length,
                        itemBuilder: (context, index) {
                          final folder = allowedFolders[index];
                          final isSelected = appState.activeFolderId == folder.id;
                          // Calculate folder unread count
                          int folderUnread = 0;
                          if (folder.id == 'all') {
                            folderUnread = appState.contacts.fold(0, (sum, c) => sum + c.unreadCount);
                          } else {
                            folderUnread = appState.contacts
                                .where((c) => c.folder == folder.id)
                                .fold(0, (sum, c) => sum + c.unreadCount);
                          }

                          return GestureDetector(
                            onTap: () => appState.setActiveFolder(folder.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppColors.primaryGradient : null,
                                color: isSelected ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? null
                                    : Border.all(color: AppColors.border),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      folder.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textMuted,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontFamily: 'Product Sans',
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (folderUnread > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.secondary.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$folderUnread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Product Sans',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              // ─── Sorting Options ───
              Row(
                children: [
                  const Text(
                    "Sort by: ",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Product Sans',
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildSortChip("Name", _sortBy == 'name', () {
                    setState(() {
                      _sortBy = 'name';
                    });
                  }),
                  const SizedBox(width: 6),
                  _buildSortChip("Recent Activity", _sortBy == 'recent', () {
                    setState(() {
                      _sortBy = 'recent';
                    });
                  }),
                ],
              ),
            ],
          ),
        ),

        // ─── Contact List / Shimmer / Empty / Staff view ───
        Expanded(
          child: appState.isLoading && contacts.isEmpty
              ? _buildShimmerList()
              : appState.activeFolderId == 'staff'
                  ? _buildStaffFolderView(appState)
                  : ListView(
                      padding: const EdgeInsets.only(left: 14, right: 14, top: 6, bottom: 110),
                      children: [
                        if (appState.archivedCount > 0)
                          InkWell(
                            onTap: () => appState.toggleShowArchived(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: appState.showArchivedChats
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: appState.showArchivedChats
                                      ? AppColors.primary.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.archive_outlined,
                                    color: appState.showArchivedChats ? AppColors.primary : Colors.white70,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    appState.showArchivedChats ? 'Showing Archived Chats' : 'Archived',
                                    style: TextStyle(
                                      color: appState.showArchivedChats ? AppColors.primary : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${appState.archivedCount}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (sortedContacts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    color: AppColors.textLight.withValues(alpha: 0.5),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    appState.showArchivedChats
                                        ? "No archived conversations"
                                        : "No conversations found",
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontFamily: 'Product Sans',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(sortedContacts.length, (index) {
                            final contact = sortedContacts[index];
                            final isPinned = appState.isPinnedChat(contact.id);
                            final isMuted = appState.isMuted(contact.id);
                            final isArchived = appState.isArchived(contact.id);

                            return AnimatedListItem(
                              index: index,
                              child: Dismissible(
                                key: Key('chat_${contact.id}'),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.endToStart) {
                                    await appState.toggleArchiveChat(contact.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isArchived
                                              ? 'Unarchived ${contact.name}'
                                              : 'Archived ${contact.name}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else if (direction == DismissDirection.startToEnd) {
                                    await appState.togglePinChat(contact.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isPinned
                                              ? 'Unpinned ${contact.name}'
                                              : 'Pinned ${contact.name}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  return false;
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isPinned ? 'Unpin' : 'Pin',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        isArchived ? 'Unarchive' : 'Archive',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    _buildContactCard(contact),
                                    if (isPinned || isMuted)
                                      Positioned(
                                        top: 12,
                                        right: 16,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isMuted)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: Icon(
                                                  Icons.volume_off_rounded,
                                                  color: Colors.white.withValues(alpha: 0.35),
                                                  size: 14,
                                                ),
                                              ),
                                            if (isPinned)
                                              Icon(
                                                Icons.push_pin_rounded,
                                                color: AppColors.primary.withValues(alpha: 0.8),
                                                size: 14,
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  SHIMMER LOADING ROWS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: 5,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 48, height: 48, borderRadius: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(width: 200, height: 10, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  CONTACT CARD (card-based tile)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildContactCard(Contact contact) {
    final appState = Provider.of<AppState>(context, listen: false);
    final canReassign = appState.isCeo || appState.isManager;

    return GestureDetector(
      onLongPress: canReassign && contact.folder == 'customers'
          ? () => _showReassignDialog(context, contact, appState)
          : null,
      child: InteractiveCustomerCard(
        contact: contact,
        onTap: () {
          appState.selectContact(contact.id);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ChatDetailScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
      ),
    );
  }

  void _showReassignDialog(BuildContext context, Contact customer, AppState appState) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can reassign targets.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    final staff = appState.contacts.where((c) => c.folder == 'staff').toList();
    String? selectedStaffId = customer.assignedStaffId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Reassign ${customer.name}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select a team member to assign this customer to:",
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.deepSpaceBlack.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStaffId ?? '',
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        items: [
                          const DropdownMenuItem<String>(value: '', child: Text("Unassigned")),
                          ...staff.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            selectedStaffId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final staffId = (selectedStaffId != null && selectedStaffId!.isNotEmpty) ? selectedStaffId : null;
                    await appState.reassignCustomer(contactId: customer.id, newStaffId: staffId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Successfully reassigned ${customer.name}"),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Reassign", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  AVATAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  PROFILE VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


  Widget _buildSortChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Product Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildStaffFolderView(AppState appState) {
    final staffMembers = appState.contacts.where((c) => c.folder == 'staff').toList();
    if (_sortBy == 'name') {
      staffMembers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'recent') {
      staffMembers.sort((a, b) {
        int cmp = b.unreadCount.compareTo(a.unreadCount);
        if (cmp != 0) return cmp;
        
        int bLastId = b.lastMessage?.id ?? 0;
        int aLastId = a.lastMessage?.id ?? 0;
        int timeCmp = bLastId.compareTo(aLastId);
        if (timeCmp != 0) return timeCmp;
        
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    final bool isCeoOrManager = appState.canCreateAccounts;
    return Column(
      children: [
        if (isCeoOrManager)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Staff Directory',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Product Sans',
                    fontSize: 16,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateStaffDialog(context, appState),
                  icon: const Icon(Icons.create_new_folder_rounded, size: 16, color: Colors.black),
                  label: const Text('Create Vault', style: TextStyle(color: Colors.black, fontFamily: 'Product Sans', fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: staffMembers.isEmpty
              ? const Center(
                  child: Text(
                    'No vaults found.',
                    style: TextStyle(color: AppColors.textMuted, fontFamily: 'Product Sans'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 14, right: 14, top: 6, bottom: 110),
                  itemCount: staffMembers.length,
                  itemBuilder: (context, index) {
                    final staff = staffMembers[index];
                    final isExpanded = _expandedStaffId == staff.id;
                    final assignedCustomers = appState.contacts
                        .where((c) => c.folder == 'customers' && c.assignedStaffId == staff.id)
                        .toList();
                    return CommandVaultWidget(
                      staff: staff,
                      assignedCustomers: assignedCustomers,
                      isExpanded: isExpanded,
                      canManage: isCeoOrManager,
                      onToggle: () {
                        setState(() {
                          _expandedStaffId = isExpanded ? null : staff.id;
                        });
                      },
                      onAddCustomer: () => _showAddCustomerDialog(context, appState, staff.id),
                      onDelete: () => _showDeleteStaffDialog(context, appState, staff),
                      onRemoveCustomer: (customer) => _showRemoveCustomerDialog(context, appState, customer),
                      onReassignCustomer: (customer) => _showReassignDialog(context, customer, appState),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddCustomerDialog(BuildContext context, AppState appState, String staffId) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can assign targets.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    String searchQuery = '';
    List<String> selectedCustomerIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allCustomers = appState.contacts.where((c) => c.folder == 'customers').toList();
            final availableCustomers = allCustomers.where((c) {
              final matchesSearch = c.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                                    c.phone.contains(searchQuery);
              final notAssignedToThisStaff = c.assignedStaffId != staffId;
              return matchesSearch && notAssignedToThisStaff;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text("Add Customers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Product Sans', color: AppColors.textMain)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search customers...",
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: AppColors.textMain),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: availableCustomers.isEmpty
                        ? const Center(child: Text("No customers available.", style: TextStyle(color: AppColors.textMuted)))
                        : ListView.builder(
                            itemCount: availableCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = availableCustomers[index];
                              final isSelected = selectedCustomerIds.contains(customer.id);
                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: AppColors.primary,
                                title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textMain)),
                                subtitle: Text(customer.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                secondary: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: customer.avatar.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            customer.avatar,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                child: const Icon(Icons.person, color: AppColors.primary),
                                              );
                                            },
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: const Icon(Icons.person, color: AppColors.primary),
                                        ),
                                ),
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedCustomerIds.add(customer.id);
                                    } else {
                                      selectedCustomerIds.remove(customer.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      children: [
                        Text("${selectedCustomerIds.length} selected", style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: selectedCustomerIds.isEmpty ? null : () async {
                            for (var id in selectedCustomerIds) {
                              await appState.moveCustomerToStaff(id, staffId);
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Assign Selected", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _showCreateStaffDialog(BuildContext context, AppState appState) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can create vaults.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    String staffName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create Staff Vault', style: TextStyle(color: Colors.white)),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Enter Name", hintStyle: TextStyle(color: AppColors.textMuted)),
            onChanged: (val) => staffName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (staffName.isNotEmpty) {
                  appState.addStaffFolder(staffName, '', 'Staff');
                }
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteStaffDialog(BuildContext context, AppState appState, Contact staff) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can delete vaults.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Vault', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this Command Vault?', style: TextStyle(color: AppColors.textLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () {
                appState.deleteStaffFolder(staff.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveCustomerDialog(BuildContext context, AppState appState, Contact customer) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can modify vault assignments.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Remove Target', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to remove this target from the vault?', style: TextStyle(color: AppColors.textLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () {
                appState.removeCustomerFromStaff(customer.id);
                Navigator.pop(context);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }


  void _showAddContactDialog(BuildContext context, AppState appState) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can add contacts.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final avatarController = TextEditingController();
    final notesController = TextEditingController();
    
    Country selectedCountry = Countries.list.firstWhere((c) => c.code == '+1', orElse: () => Countries.list[0]);
    String selectedType = 'customers'; // 'customers' or 'staff'
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      
                      const Text(
                        "Add New Contact",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: 'Product Sans',
                          color: AppColors.textMain,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "CONTACT TYPE",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'customers';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: selectedType == 'customers'
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: selectedType == 'customers'
                                      ? null
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: selectedType == 'customers'
                                      ? null
                                      : Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Text(
                                    "Customer",
                                    style: TextStyle(
                                      color: selectedType == 'customers'
                                          ? Colors.black
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Product Sans',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedType = 'staff';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: selectedType == 'staff'
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: selectedType == 'staff'
                                      ? null
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: selectedType == 'staff'
                                      ? null
                                      : Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Text(
                                    "Staff",
                                    style: TextStyle(
                                      color: selectedType == 'staff'
                                          ? Colors.black
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Product Sans',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildFormLabel("FULL NAME *"),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: AppColors.textMain),
                        decoration: _buildInputDecoration("Enter contact's full name"),
                      ),
                      const SizedBox(height: 16),

                      _buildFormLabel("PHONE NUMBER *"),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Country>(
                                  value: selectedCountry,
                                  dropdownColor: AppColors.surface,
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                                  items: Countries.list.map((Country country) {
                                    return DropdownMenuItem<Country>(
                                      value: country,
                                      child: Text(
                                        "${country.flag} ${country.code}",
                                        style: const TextStyle(color: Colors.white, fontFamily: 'Product Sans'),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (Country? val) {
                                    if (val != null) {
                                      setModalState(() {
                                        selectedCountry = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: AppColors.textMain),
                              decoration: _buildInputDecoration(selectedCountry.formatPlaceholder),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFormLabel("EMAIL ADDRESS (OPTIONAL)"),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textMain),
                        decoration: _buildInputDecoration("name@example.com"),
                      ),
                      const SizedBox(height: 16),

                      _buildFormLabel("PROFILE PICTURE URL (OPTIONAL)"),
                      TextField(
                        controller: avatarController,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(color: AppColors.textMain),
                        decoration: _buildInputDecoration("https://images.unsplash.com/..."),
                      ),
                      const SizedBox(height: 16),

                      _buildFormLabel("NOTES (OPTIONAL)"),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textMain),
                        decoration: _buildInputDecoration("Add any additional info..."),
                      ),
                      const SizedBox(height: 20),

                      if (validationError != null) ...[
                        Text(
                          validationError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Product Sans',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontFamily: 'Product Sans',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final rawPhone = phoneController.text.trim();
                                  
                                  if (name.isEmpty) {
                                    setModalState(() {
                                      validationError = "Full Name is required";
                                    });
                                    return;
                                  }
                                  if (rawPhone.isEmpty) {
                                    setModalState(() {
                                      validationError = "Phone Number is required";
                                    });
                                    return;
                                  }

                                  final phone = "${selectedCountry.code} $rawPhone";
                                  final role = selectedType == 'customers' ? 'Client' : 'Staff Member';

                                  Navigator.pop(context);
                                  
                                  final success = await appState.addContact(
                                    name: name,
                                    phone: phone,
                                    folder: selectedType,
                                    role: role,
                                    avatar: avatarController.text.trim(),
                                    email: emailController.text.trim(),
                                    notes: notesController.text.trim(),
                                    countryCode: selectedCountry.code,
                                  );

                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Contact $name added successfully!"),
                                          backgroundColor: AppColors.primaryDark,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Failed to save contact. Please try again."),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  "Save Contact",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Product Sans',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNewActionSheet(BuildContext context, AppState appState) {
    if (!appState.canCreateAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access restricted: Only CEO and Manager can access this action.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.person_add_rounded, color: AppColors.primary)),
                title: const Text('New Contact / Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Start direct conversation with a contact', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddContactDialog(context, appState);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.group_add_rounded, color: Colors.purpleAccent)),
                title: const Text('New Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a team or project group discussion', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroupCreateScreen()));
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.pink.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.lock_rounded, color: Colors.pinkAccent)),
                title: const Text('Lock App Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Enable Passcode / Biometric Security Lock', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  appState.setAppLocked(true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
