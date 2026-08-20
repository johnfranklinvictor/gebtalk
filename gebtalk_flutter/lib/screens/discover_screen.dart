import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/app_state.dart';
import '../theme/colors.dart';
import '../widgets/titan_glass_panel.dart';
import '../widgets/titan_background.dart';
import '../widgets/create_account_modal.dart';
import 'command_center_screen.dart';
import 'email_inbox_screen.dart';
import 'community_screen.dart';
import 'newsletter_screen.dart';
import 'payment_screen.dart';
import 'broadcast_screen.dart';
import 'guest_meet_screen.dart';
import 'starred_messages_screen.dart';

/// WeChat-inspired Discover & Services Ecosystem Hub for GEBTALK
/// Unifies Business Tools, CRM Assignments, Document Vault, Email Workspace,
/// Communities, Channels, Payments, and Extensible Mini-Modules under one connected environment.
class DiscoverScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const DiscoverScreen({super.key, this.onTabChanged});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.ensureInitialDataLoaded();
    });
  }

  void _showCustomerAssignmentDialog(AppState appState) {
    if (!appState.canAssignCustomers) return;

    final customers = appState.customerContacts;
    final staffList = appState.staffMembers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer → Staff Assignment Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Product Sans',
                            ),
                          ),
                          Text(
                            'Route customer portfolios to authorized staff specialists',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customer accounts found.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final cust = customers[i];
                          final assignedStaff = staffList.where((s) => s.id == cust.assignedStaffId).firstOrNull;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  backgroundImage: cust.avatar.isNotEmpty ? NetworkImage(cust.avatar) : null,
                                  child: cust.avatar.isEmpty
                                      ? Text(cust.name.isNotEmpty ? cust.name[0] : 'C', style: const TextStyle(color: Color(0xFF10B981)))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cust.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.badge_outlined, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                                          const SizedBox(width: 4),
                                          Text(
                                            assignedStaff != null
                                                ? 'Specialist: ${assignedStaff.name}'
                                                : 'Unassigned',
                                            style: TextStyle(
                                              color: assignedStaff != null ? const Color(0xFF60A5FA) : const Color(0xFFF59E0B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Reassign', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_drop_down, color: Color(0xFF60A5FA), size: 16),
                                      ],
                                    ),
                                  ),
                                  color: const Color(0xFF1E293B),
                                  onSelected: (String newStaffId) async {
                                    final success = await appState.reassignCustomer(
                                      contactId: cust.id,
                                      newStaffId: newStaffId.isEmpty ? null : newStaffId,
                                    );
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Customer ${cust.name} assigned to specialist successfully!'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: '',
                                      child: Text('Unassign (Remove Specialist)', style: TextStyle(color: Color(0xFFEF4444))),
                                    ),
                                    ...staffList.map((s) => PopupMenuItem(
                                          value: s.id,
                                          child: Text('Assign to: ${s.name} (${s.role})', style: const TextStyle(color: Colors.white)),
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isCeoOrManager = appState.canAssignCustomers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: TitanBackground(
        preset: 'lounge',
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Sliver
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(Icons.explore_rounded, color: Color(0xFF60A5FA), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discover & Services',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Product Sans',
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Unified Digital Communication Ecosystem',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  fontFamily: 'Product Sans',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (appState.canCreateAccounts)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF60A5FA), size: 18),
                          ),
                          onPressed: () => CreateAccountModal.show(context),
                          tooltip: 'Create Managed Account',
                        ),
                    ],
                  ),
                ),
              ),

              // Categories Selector
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Services', Icons.apps_rounded),
                      _buildFilterChip('business', 'Business Tools', Icons.business_center_rounded),
                      _buildFilterChip('comms', 'Communications', Icons.chat_rounded),
                      _buildFilterChip('productivity', 'Productivity', Icons.bolt_rounded),
                    ],
                  ),
                ),
              ),

              // Administrative CRM Banner (CEO / Manager only)
              if (isCeoOrManager)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: TitanGlassPanel(
                      glowColor: const Color(0xFF10B981),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Executive CRM & Assignment Control',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Product Sans',
                                      ),
                                    ),
                                    Text(
                                      'Manage customer assignments and staff routing',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAdminStatCard(
                                  'Total Staff',
                                  '${appState.staffMembers.length}',
                                  const Color(0xFF3B82F6),
                                  Icons.people_alt_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildAdminStatCard(
                                  'Customers',
                                  '${appState.customerContacts.length}',
                                  const Color(0xFF10B981),
                                  Icons.business_center_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  onPressed: () => _showCustomerAssignmentDialog(appState),
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                                  label: const Text('Customer Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CommandCenterScreen()),
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.dashboard_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Command Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Ecosystem Services Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildListDelegate(
                    _buildEcosystemCards(context, appState),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.25) : const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF60A5FA) : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF60A5FA) : Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Product Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Product Sans'),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEcosystemCards(BuildContext context, AppState appState) {
    final List<Map<String, dynamic>> items = [
      {
        'id': 'email_workspace',
        'title': 'Email Workspace',
        'subtitle': 'Unified Inbox & Comms',
        'icon': Icons.mail_outline_rounded,
        'color': const Color(0xFF3B82F6),
        'badge': appState.unreadEmailCount > 0 ? '${appState.unreadEmailCount}' : null,
        'category': 'comms',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailInboxScreen())),
      },
      {
        'id': 'broadcast_lists',
        'title': 'Broadcast Lists',
        'subtitle': 'Organization Alerts',
        'icon': Icons.podcasts_rounded,
        'color': const Color(0xFFA855F7),
        'category': 'business',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen())),
      },
      {
        'id': 'communities',
        'title': 'Communities',
        'subtitle': 'Team Workspaces',
        'icon': Icons.diversity_3_rounded,
        'color': const Color(0xFF10B981),
        'category': 'comms',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
      },
      {
        'id': 'newsletters',
        'title': 'Channels & News',
        'subtitle': 'Corporate Feeds',
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFFF59E0B),
        'category': 'business',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsletterScreen())),
      },
      {
        'id': 'wallet_payments',
        'title': 'Financial Wallet',
        'subtitle': 'Payments & Vouchers',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF06B6D4),
        'category': 'business',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
      },
      {
        'id': 'guest_meet',
        'title': 'Video Meeting Room',
        'subtitle': 'Instant WebRTC Links',
        'icon': Icons.video_camera_front_rounded,
        'color': const Color(0xFFEC4899),
        'category': 'productivity',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuestMeetScreen(meetingId: 'meet_${DateTime.now().millisecondsSinceEpoch}'))),
      },
      {
        'id': 'starred_messages',
        'title': 'Starred Vault',
        'subtitle': 'Saved Documents & Chat',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFBBF24),
        'category': 'productivity',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredMessagesScreen())),
      },
      {
        'id': 'command_center',
        'title': 'Command Center',
        'subtitle': 'System & Node Metrics',
        'icon': Icons.hub_rounded,
        'color': const Color(0xFF6366F1),
        'category': 'productivity',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandCenterScreen())),
      },
    ];

    final filtered = items.where((it) {
      if (_selectedCategory == 'all') return true;
      return it['category'] == _selectedCategory;
    }).toList();

    return filtered.map((item) {
      final Color color = item['color'] as Color;
      final String title = item['title'] as String;
      final String subtitle = item['subtitle'] as String;
      final IconData icon = item['icon'] as IconData;
      final String? badge = item['badge'] as String?;
      final VoidCallback onTap = item['onTap'] as VoidCallback;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Product Sans',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontFamily: 'Product Sans',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
