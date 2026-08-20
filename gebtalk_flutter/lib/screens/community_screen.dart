import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

/// WhatsApp Communities hub screen
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> _communities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    final communities = await ApiService.getCommunities();
    if (mounted) {
      setState(() {
        _communities = communities;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Communities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => _showCreateCommunityDialog(context),
            tooltip: 'New Community',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _communities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _communities.length,
                  itemBuilder: (context, index) {
                    final comm = _communities[index];
                    return _buildCommunityCard(comm);
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
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_rounded, color: AppColors.primary, size: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'Stay connected with a community',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Communities bring members together in topic-based groups, and make it easy to send announcements to everyone.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            label: const Text('New Community', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _showCreateCommunityDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> comm) {
    final name = comm['name'] ?? 'Community';
    final desc = comm['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: desc.isNotEmpty
                ? Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
          ),
          const Divider(color: Colors.white10, height: 1),

          // Sub-groups / Announcement Channel
          ListTile(
            leading: const Icon(Icons.campaign_rounded, color: Colors.orangeAccent, size: 22),
            title: const Text('Announcements', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text('Official community updates', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.group_work_rounded, color: AppColors.primary, size: 22),
            title: const Text('General Discussion', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text('Open discussion group', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showCreateCommunityDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Community', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Community Name',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await ApiService.createCommunity(name, descCtrl.text.trim());
                _fetchCommunities();
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
