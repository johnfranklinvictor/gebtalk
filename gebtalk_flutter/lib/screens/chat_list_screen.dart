import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../utils/countries.dart';
import '../widgets/ebi_bot.dart';
import '../widgets/animations.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';
import 'broadcast_screen.dart';
import '../widgets/command_vault.dart';
import '../widgets/interactive_customer_card.dart';

class ChatListScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const ChatListScreen({Key? key, this.onTabChanged}) : super(key: key);

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

  void _navigateToChatDetail(BuildContext context, String contactId) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.selectContact(contactId);

    if (mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ChatDetailScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ).then((_) {
        appState.closeConversation();
      });
    }
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
                if (appState.activeFolderId == 'customers')
                  Positioned(
                    bottom: 110,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: () => _showAddContactDialog(context, appState),
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 28,
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  GRADIENT HEADER
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildGradientHeader(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Teal glowing icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'GEBTALK CHAT',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Product Sans',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => appState.refreshContacts(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
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

        // â”€â”€â”€ Contact List / Shimmer / Empty / Staff view â”€â”€â”€
        Expanded(
          child: appState.isLoading && contacts.isEmpty
              ? _buildShimmerList()
              : appState.activeFolderId == 'staff'
                  ? _buildStaffFolderView(appState)
                  : (contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                color: AppColors.textLight.withValues(alpha: 0.5),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No conversations found",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontFamily: 'Product Sans',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 14, right: 14, top: 6, bottom: 110),
                          itemCount: sortedContacts.length,
                          itemBuilder: (context, index) {
                            final contact = sortedContacts[index];
                            return AnimatedListItem(
                              index: index,
                              child: _buildContactCard(contact),
                            );
                          },
                        )),
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
            child: Row(
              children: [
                const ShimmerBox(width: 48, height: 48, borderRadius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
    return InteractiveCustomerCard(
      contact: contact,
      onTap: () {
        Provider.of<AppState>(context, listen: false).selectContact(contact.id);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing orange glow behind
        PulsingDot(color: AppColors.orangeGlow, size: 22),
        // Count text on top
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Product Sans',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  AVATAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAvatar(Contact contact) {
    if (contact.avatar.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.psychology, color: Colors.white, size: 24),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(contact.avatar),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  PROFILE VIEW
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildProfileView(AppState appState) {
    final profile = !appState.isAdmin
        ? {
            'name': 'Sarah Jenkins',
            'role': 'Project Lead | Staff',
            'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80'
          }
        : (appState.userProfile ?? {
            'name': 'Marcus Sterling',
            'role': 'Executive VP | Global EB Tech',
            'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80'
          });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // â”€â”€â”€ Gradient profile header â”€â”€â”€
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 32, bottom: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDark.withValues(alpha: 0.08),
                  AppColors.tealGlow.withValues(alpha: 0.04),
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundImage: NetworkImage(profile['avatar']!),
                    backgroundColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
                // Name with gradient overlay effect
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Text(
                    profile['name']!,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Product Sans',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile['role']!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Product Sans',
                  ),
                ),
              ],
            ),
          ),

          // â”€â”€â”€ Settings card â”€â”€â”€
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingRow(Icons.security_rounded, "Security Settings"),
                  const Divider(color: AppColors.borderLight),
                  _buildSettingRow(Icons.notifications_active_rounded, "Notification Filters"),
                  const Divider(color: AppColors.borderLight),
                  _buildSettingRow(Icons.color_lens_rounded, "Accent Preferences"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // â”€â”€â”€ Developer Settings card â”€â”€â”€
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Developer Settings",
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Product Sans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Admin Mode",
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 14,
                          fontFamily: 'Product Sans',
                        ),
                      ),
                      Switch(
                        value: appState.isAdmin,
                        onChanged: (val) {
                          appState.toggleAdminMode();
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.isAdmin 
                        ? "Current Role: Admin (Marcus Sterling)" 
                        : "Current Role: Staff (Sarah Jenkins)",
                    style: TextStyle(
                      color: appState.isAdmin ? AppColors.primary : AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Product Sans',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title) {
    return TapScaleWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 14,
                fontFamily: 'Product Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textLight, size: 12),
          ],
        ),
      ),
    );
  }

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
    return Column(
      children: [
        if (appState.isAdmin)
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
                      onToggle: () {
                        setState(() {
                          _expandedStaffId = isExpanded ? null : staff.id;
                        });
                      },
                      onAddCustomer: () => _showAddCustomerDialog(context, appState, staff.id),
                      onDelete: () => _showDeleteStaffDialog(context, appState, staff),
                      onRemoveCustomer: (customer) => _showRemoveCustomerDialog(context, appState, customer),
                      onReassignCustomer: (customer) => _showReassignDialog(context, appState, customer),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddCustomerDialog(BuildContext context, AppState appState, String staffId) {
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
                                secondary: CircleAvatar(
                                  backgroundImage: customer.avatar.isNotEmpty ? NetworkImage(customer.avatar) : null,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: customer.avatar.isEmpty ? const Icon(Icons.person, color: AppColors.primary) : null,
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

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
    void _showCreateStaffDialog(BuildContext context, AppState appState) {
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
                  final newStaff = Contact(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: staffName,
                    phone: '',
                    role: 'Staff',
                    avatar: '',
                    status: 'online',
                    folder: 'staff',
                    unreadCount: 0,
                    tags: [],
                  );
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

  void _showReassignDialog(BuildContext context, AppState appState, Contact customer) {
    // Basic reassign stub
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reassign feature not fully implemented in Gamified mode.')));
  }

  void _showAddContactDialog(BuildContext context, AppState appState) {
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
