import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';

/// WhatsApp Storage and Data Usage Manager Screen
class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _storageSummary;

  bool _lowDataCalls = false;
  bool _autoDownloadPhotosMobile = true;
  bool _autoDownloadAudioMobile = false;
  bool _autoDownloadVideoMobile = false;
  bool _autoDownloadDocsMobile = true;

  bool _autoDownloadPhotosWifi = true;
  bool _autoDownloadAudioWifi = true;
  bool _autoDownloadVideoWifi = true;
  bool _autoDownloadDocsWifi = true;

  @override
  void initState() {
    super.initState();
    _fetchStorage();
  }

  Future<void> _fetchStorage() async {
    final summary = await ApiService.getStorageSummary();
    if (mounted) {
      setState(() {
        _storageSummary = summary;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Storage and Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Manage Storage Visual Card
                _buildStorageCard(),

                const SizedBox(height: 20),

                _buildHeader('Manage Storage by Chat'),
                if (_storageSummary?['chats'] != null)
                  ...(_storageSummary!['chats'] as List).map((chat) => _buildChatStorageTile(chat)),

                const Divider(color: Colors.white10, height: 32),

                _buildHeader('Network Usage'),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.network_check_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Network usage', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('42.8 MB sent • 128.4 MB received', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
                  onTap: _showNetworkUsageDialog,
                ),
                SwitchListTile(
                  title: const Text('Use less data for calls', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text('Reduces the data used during WebRTC calls', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  value: _lowDataCalls,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _lowDataCalls = val),
                ),

                const Divider(color: Colors.white10, height: 32),

                _buildHeader('Media Auto-Download'),
                ListTile(
                  title: const Text('When using mobile data', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(
                    _formatAutoDownloadSummary(_autoDownloadPhotosMobile, _autoDownloadAudioMobile, _autoDownloadVideoMobile, _autoDownloadDocsMobile),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () => _showAutoDownloadDialog(
                    'When using mobile data',
                    _autoDownloadPhotosMobile,
                    _autoDownloadAudioMobile,
                    _autoDownloadVideoMobile,
                    _autoDownloadDocsMobile,
                    (p, a, v, d) => setState(() {
                      _autoDownloadPhotosMobile = p;
                      _autoDownloadAudioMobile = a;
                      _autoDownloadVideoMobile = v;
                      _autoDownloadDocsMobile = d;
                    }),
                  ),
                ),
                ListTile(
                  title: const Text('When connected on Wi-Fi', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(
                    _formatAutoDownloadSummary(_autoDownloadPhotosWifi, _autoDownloadAudioWifi, _autoDownloadVideoWifi, _autoDownloadDocsWifi),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () => _showAutoDownloadDialog(
                    'When connected on Wi-Fi',
                    _autoDownloadPhotosWifi,
                    _autoDownloadAudioWifi,
                    _autoDownloadVideoWifi,
                    _autoDownloadDocsWifi,
                    (p, a, v, d) => setState(() {
                      _autoDownloadPhotosWifi = p;
                      _autoDownloadAudioWifi = a;
                      _autoDownloadVideoWifi = v;
                      _autoDownloadDocsWifi = d;
                    }),
                  ),
                ),

                const Divider(color: Colors.white10, height: 32),

                _buildHeader('Media Upload Quality'),
                ListTile(
                  title: const Text('Photo upload quality', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('Best quality (Lossless HD mode)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {},
                ),
              ],
            ),
    );
  }

  Widget _buildStorageCard() {
    final usedFormatted = _storageSummary?['total_used_formatted'] ?? '42.5 MB';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GebTalk Storage', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$usedFormatted Used', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Multi-color storage bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: 25, child: Container(color: Colors.greenAccent)),
                  Expanded(flex: 35, child: Container(color: Colors.blueAccent)),
                  Expanded(flex: 15, child: Container(color: Colors.orangeAccent)),
                  Expanded(flex: 25, child: Container(color: Colors.purpleAccent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildLegend('Photos (24.5 MB)', Colors.greenAccent),
              _buildLegend('Videos (88.2 MB)', Colors.blueAccent),
              _buildLegend('Audio (14.1 MB)', Colors.orangeAccent),
              _buildLegend('Docs (32.0 MB)', Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }

  Widget _buildChatStorageTile(Map<String, dynamic> chat) {
    final name = chat['name'] ?? 'Contact';
    final size = chat['size_formatted'] ?? '1.2 MB';
    final msgCount = chat['message_count'] ?? 0;
    final cid = chat['id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text('$msgCount messages', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(size, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white38, size: 20),
              tooltip: 'Clear Media',
              onPressed: () => _confirmClearMedia(cid, name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  String _formatAutoDownloadSummary(bool p, bool a, bool v, bool d) {
    final list = <String>[];
    if (p) list.add('Photos');
    if (a) list.add('Audio');
    if (v) list.add('Videos');
    if (d) list.add('Docs');
    return list.isEmpty ? 'No media' : list.join(', ');
  }

  void _showAutoDownloadDialog(
    String title,
    bool p, bool a, bool v, bool d,
    Function(bool p, bool a, bool v, bool d) onSave,
  ) {
    bool photo = p;
    bool audio = a;
    bool video = v;
    bool docs = d;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Photos', style: TextStyle(color: Colors.white)),
                value: photo,
                activeColor: AppColors.primary,
                onChanged: (val) => setModalState(() => photo = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Audio', style: TextStyle(color: Colors.white)),
                value: audio,
                activeColor: AppColors.primary,
                onChanged: (val) => setModalState(() => audio = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Videos', style: TextStyle(color: Colors.white)),
                value: video,
                activeColor: AppColors.primary,
                onChanged: (val) => setModalState(() => video = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Documents', style: TextStyle(color: Colors.white)),
                value: docs,
                activeColor: AppColors.primary,
                onChanged: (val) => setModalState(() => docs = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
                onSave(photo, audio, video, docs);
              },
              child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearMedia(String cid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear Media for $name?', style: const TextStyle(color: Colors.white)),
        content: const Text('This will delete all sent and received photos, videos, audio and files in this chat to free up device storage.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.clearChatMedia(cid);
              _fetchStorage();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Media cleared for $name')),
                );
              }
            },
            child: const Text('Clear Media', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showNetworkUsageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Network Usage Statistics', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNetworkStatRow('Calls', '18.4 MB', '52.1 MB'),
            _buildNetworkStatRow('Media', '20.1 MB', '68.5 MB'),
            _buildNetworkStatRow('Messages', '3.8 MB', '7.2 MB'),
            _buildNetworkStatRow('Status', '0.5 MB', '0.6 MB'),
            const Divider(color: Colors.white24, height: 24),
            _buildNetworkStatRow('Total', '42.8 MB sent', '128.4 MB received', isBold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network statistics reset')));
            },
            child: const Text('Reset Statistics', style: TextStyle(color: Colors.orangeAccent)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildNetworkStatRow(String category, String sent, String recv, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          Text('$sent / $recv', style: TextStyle(color: isBold ? AppColors.primary : Colors.white70, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ],
      ),
    );
  }
}
