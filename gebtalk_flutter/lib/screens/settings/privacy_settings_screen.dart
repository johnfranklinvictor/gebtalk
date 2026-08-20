import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';

/// WhatsApp Privacy Settings screen
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _lastSeenPrivacy = 'everyone';
  String _profilePhotoPrivacy = 'everyone';
  String _aboutPrivacy = 'everyone';
  String _statusPrivacy = 'contacts';
  String _groupsPrivacy = 'everyone';
  bool _readReceipts = true;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppState>(context, listen: false).currentProfile;
    if (profile != null) {
      _lastSeenPrivacy = profile.lastSeenPrivacy;
      _profilePhotoPrivacy = profile.profilePhotoPrivacy;
      _aboutPrivacy = profile.aboutPrivacy;
      _statusPrivacy = profile.statusPrivacy;
      _groupsPrivacy = profile.groupsPrivacy;
      _readReceipts = profile.readReceipts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Privacy Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Who can see my personal info'),
          _buildPrivacyTile(
            title: 'Last seen and online',
            value: _lastSeenPrivacy,
            onTap: () => _showOptionsDialog('Last seen and online', _lastSeenPrivacy, (val) {
              setState(() => _lastSeenPrivacy = val);
              _savePrivacySetting({'last_seen_privacy': val});
            }),
          ),
          _buildPrivacyTile(
            title: 'Profile photo',
            value: _profilePhotoPrivacy,
            onTap: () => _showOptionsDialog('Profile photo', _profilePhotoPrivacy, (val) {
              setState(() => _profilePhotoPrivacy = val);
              _savePrivacySetting({'profile_photo_privacy': val});
            }),
          ),
          _buildPrivacyTile(
            title: 'About',
            value: _aboutPrivacy,
            onTap: () => _showOptionsDialog('About', _aboutPrivacy, (val) {
              setState(() => _aboutPrivacy = val);
              _savePrivacySetting({'about_privacy': val});
            }),
          ),
          _buildPrivacyTile(
            title: 'Status',
            value: _statusPrivacy,
            onTap: () => _showOptionsDialog('Status', _statusPrivacy, (val) {
              setState(() => _statusPrivacy = val);
              _savePrivacySetting({'status_privacy': val});
            }),
          ),

          SwitchListTile(
            title: const Text('Read receipts', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(
              "If turned off, you won't send or receive Read receipts. Read receipts are always sent for group chats.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            value: _readReceipts,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _readReceipts = val);
              _savePrivacySetting({'read_receipts': val});
            },
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildSectionHeader('Disappearing messages'),
          ListTile(
            title: const Text('Default message timer', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Start new chats with disappearing messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            trailing: const Text('Off', style: TextStyle(color: AppColors.primary, fontSize: 14)),
            onTap: () => _showDisappearingDefaultDialog(),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildSectionHeader('Security & Contacts'),
          ListTile(
            leading: const Icon(Icons.group_rounded, color: Colors.white70),
            title: const Text('Groups', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_groupsPrivacy, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _showOptionsDialog('Groups', _groupsPrivacy, (val) {
              setState(() => _groupsPrivacy = val);
              _savePrivacySetting({'groups_privacy': val});
            }),
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.white70),
            title: const Text('Blocked contacts', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('${appState.chatPreferences.blocked.length} contacts blocked', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _showBlockedContactsDialog(appState),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded, color: Colors.white70),
            title: const Text('App Lock', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Require PIN or fingerprint to open GebTalk', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            onTap: () => _showAppLockDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPrivacyTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: Text(
        value == 'everyone' ? 'Everyone' : value == 'contacts' ? 'My contacts' : 'Nobody',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: onTap,
    );
  }

  void _showDisappearingDefaultDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Default Message Timer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption('24 Hours', '24h', 'off', ctx, (val) => _savePrivacySetting({'default_disappearing_timer': val})),
            _buildRadioOption('7 Days', '7d', 'off', ctx, (val) => _savePrivacySetting({'default_disappearing_timer': val})),
            _buildRadioOption('90 Days', '90d', 'off', ctx, (val) => _savePrivacySetting({'default_disappearing_timer': val})),
            _buildRadioOption('Off', 'off', 'off', ctx, (val) => _savePrivacySetting({'default_disappearing_timer': val})),
          ],
        ),
      ),
    );
  }

  void _showBlockedContactsDialog(AppState appState) async {
    final blockedList = await ApiService.getBlockedContacts();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Blocked Contacts', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: blockedList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No contacts blocked.', style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: blockedList.length,
                  itemBuilder: (context, i) {
                    final item = blockedList[i];
                    final contactId = item['contact_id'] ?? item['id'] ?? '';
                    final name = item['name'] ?? contactId;
                    return ListTile(
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      trailing: TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await appState.toggleBlockContact(contactId);
                          if (mounted) setState(() {});
                        },
                        child: const Text('Unblock', style: TextStyle(color: AppColors.primary)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _showAppLockDialog() {
    bool enabled = true;
    final pinController = TextEditingController(text: '1234');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('App Lock Settings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Enable Passcode Lock', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: enabled,
                activeColor: AppColors.primary,
                onChanged: (val) => setDlgState(() => enabled = val),
              ),
              if (enabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4),
                  decoration: const InputDecoration(
                    labelText: '4-Digit PIN',
                    labelStyle: TextStyle(color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ApiService.setAppLock(enabled, pinController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(enabled ? 'App Lock enabled with PIN' : 'App Lock disabled')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog(String title, String currentValue, Function(String val) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption('Everyone', 'everyone', currentValue, ctx, onSelect),
            _buildRadioOption('My contacts', 'contacts', currentValue, ctx, onSelect),
            _buildRadioOption('Nobody', 'nobody', currentValue, ctx, onSelect),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, String value, String currentValue, BuildContext ctx, Function(String val) onSelect) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: currentValue,
      activeColor: AppColors.primary,
      onChanged: (val) {
        if (val != null) {
          onSelect(val);
          Navigator.pop(ctx);
        }
      },
    );
  }

  void _savePrivacySetting(Map<String, dynamic> settings) {
    ApiService.updatePrivacySettings(settings);
  }
}
