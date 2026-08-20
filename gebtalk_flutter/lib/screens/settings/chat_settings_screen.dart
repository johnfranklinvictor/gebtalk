import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// WhatsApp Chat Settings screen
class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _enterIsSend = true;
  bool _mediaVisibility = true;
  bool _keepArchived = true;
  String _theme = 'System default (Dark)';
  String _wallpaper = 'Default (Dark Galaxy)';
  String _fontSize = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Chat Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Display'),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded, color: Colors.white70),
            title: const Text('Theme', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_theme, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showThemeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper_rounded, color: Colors.white70),
            title: const Text('Wallpaper', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_wallpaper, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showWallpaperDialog(),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildHeader('Chat Settings'),
          SwitchListTile(
            title: const Text('Enter is send', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: const Text('Enter key will send your message', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _enterIsSend,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _enterIsSend = val),
          ),
          SwitchListTile(
            title: const Text('Media visibility', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: const Text("Show newly downloaded media in your phone's gallery", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _mediaVisibility,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _mediaVisibility = val),
          ),
          ListTile(
            title: const Text('Font size', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_fontSize, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => _showFontSizeDialog(),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildHeader('Archived Chats'),
          SwitchListTile(
            title: const Text('Keep chats archived', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: const Text('Archived chats will remain archived when you receive a new message', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _keepArchived,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _keepArchived = val),
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
        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Choose Theme', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['System default (Dark)', 'Titan Cyberpunk Dark', 'Obsidian OLED Black', 'Deep Cosmos'].map((t) {
            return RadioListTile<String>(
              title: Text(t, style: const TextStyle(color: Colors.white)),
              value: t,
              groupValue: _theme,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _theme = val);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showWallpaperDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Chat Wallpaper', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Default (Dark Galaxy)', 'Nebula Purple', 'Deep Ocean', 'Emerald Matrix', 'Solid Dark'].map((w) {
            return RadioListTile<String>(
              title: Text(w, style: const TextStyle(color: Colors.white)),
              value: w,
              groupValue: _wallpaper,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _wallpaper = val);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Font Size', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Small', 'Medium', 'Large'].map((size) {
            return RadioListTile<String>(
              title: Text(size, style: const TextStyle(color: Colors.white)),
              value: size,
              groupValue: _fontSize,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _fontSize = val);
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
