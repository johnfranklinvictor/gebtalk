import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// WhatsApp Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _conversationTones = true;
  bool _highPriorityMessages = true;
  bool _reactionNotifications = true;
  String _messageTone = 'Titan Bell';
  String _messageVibrate = 'Default';
  String _messageLight = 'Cyan';

  String _groupTone = 'Titan Chord';
  bool _groupHighPriority = true;
  bool _groupReactions = true;
  String _groupVibrate = 'Default';

  String _callRingtone = 'Titan Nebula Ringtone';
  String _callVibrate = 'Default';

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
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Conversation tones', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Play sounds for incoming and outgoing messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            value: _conversationTones,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _conversationTones = val),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildHeader('Messages'),
          ListTile(
            title: const Text('Notification tone', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_messageTone, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Notification Tone', ['Titan Bell', 'Subtle Pop', 'Glass Chime', 'Digital Ping', 'Cyber Pulse'], _messageTone, (v) => setState(() => _messageTone = v)),
          ),
          ListTile(
            title: const Text('Vibrate', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_messageVibrate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Vibrate', ['Off', 'Default', 'Short', 'Long'], _messageVibrate, (v) => setState(() => _messageVibrate = v)),
          ),
          ListTile(
            title: const Text('Light', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_messageLight, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Light', ['None', 'White', 'Cyan', 'Red', 'Yellow', 'Green', 'Blue', 'Purple'], _messageLight, (v) => setState(() => _messageLight = v)),
          ),
          SwitchListTile(
            title: const Text('Use high priority notifications', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Show previews of notifications at top of screen', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            value: _highPriorityMessages,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _highPriorityMessages = val),
          ),
          SwitchListTile(
            title: const Text('Reaction notifications', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Show notifications for reactions to messages you send', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            value: _reactionNotifications,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _reactionNotifications = val),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildHeader('Groups'),
          ListTile(
            title: const Text('Notification tone', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_groupTone, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Group Notification Tone', ['Titan Chord', 'Subtle Pop', 'Glass Chime', 'Echo Bounce', 'Horizon Wave'], _groupTone, (v) => setState(() => _groupTone = v)),
          ),
          ListTile(
            title: const Text('Vibrate', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_groupVibrate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Vibrate', ['Off', 'Default', 'Short', 'Long'], _groupVibrate, (v) => setState(() => _groupVibrate = v)),
          ),
          SwitchListTile(
            title: const Text('Use high priority notifications', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Show previews of notifications at top of screen', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            value: _groupHighPriority,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _groupHighPriority = val),
          ),
          SwitchListTile(
            title: const Text('Reaction notifications', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text('Show notifications for reactions to group messages', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            value: _groupReactions,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _groupReactions = val),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildHeader('Calls'),
          ListTile(
            title: const Text('Ringtone', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_callRingtone, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Call Ringtone', ['Titan Nebula Ringtone', 'Digital Pulse', 'Cosmic Harmony', 'Subtle Wave', 'Default Chime'], _callRingtone, (v) => setState(() => _callRingtone = v)),
          ),
          ListTile(
            title: const Text('Vibrate', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_callVibrate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showOptionDialog('Vibrate', ['Off', 'Default', 'Short', 'Long'], _callVibrate, (v) => setState(() => _callVibrate = v)),
          ),
        ],
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

  void _showOptionDialog(String title, List<String> options, String selected, Function(String val) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt, style: const TextStyle(color: Colors.white)),
              value: opt,
              groupValue: selected,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  onSelect(val);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
