import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// WhatsApp Chat Backup screen
class ChatBackupScreen extends StatefulWidget {
  const ChatBackupScreen({super.key});

  @override
  State<ChatBackupScreen> createState() => _ChatBackupScreenState();
}

class _ChatBackupScreenState extends State<ChatBackupScreen> {
  bool _isBackingUp = false;
  double _backupProgress = 0.0;
  bool _includeVideos = false;
  String _frequency = 'Daily';
  String _lastBackupTime = 'Today at 02:00 AM';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Chat Backup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backup Card
          Container(
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
                    Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Backup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(_lastBackupTime, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                          Text('Size: 42.5 MB', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isBackingUp) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _backupProgress, backgroundColor: Colors.white10, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text('Backing up messages... ${(_backupProgress * 100).toInt()}%', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: _isBackingUp ? null : _startBackup,
                    child: Text(_isBackingUp ? 'Backing Up...' : 'BACK UP', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildHeader('Backup Settings'),
          ListTile(
            title: const Text('Back up to Cloud / Local', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(_frequency, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: _showFrequencyDialog,
          ),
          SwitchListTile(
            title: const Text('Include videos', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: const Text('128 MB videos will be included in backup', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _includeVideos,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _includeVideos = val),
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

  void _startBackup() async {
    setState(() {
      _isBackingUp = true;
      _backupProgress = 0.0;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _backupProgress = i / 10.0);
    }

    if (mounted) {
      setState(() {
        _isBackingUp = false;
        _lastBackupTime = 'Just now';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat backup completed successfully!'), backgroundColor: AppColors.primaryDark),
      );
    }
  }

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Backup Frequency', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Never', 'Only when I tap "Back up"', 'Daily', 'Weekly', 'Monthly'].map((freq) {
            return RadioListTile<String>(
              title: Text(freq, style: const TextStyle(color: Colors.white)),
              value: freq,
              groupValue: _frequency,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _frequency = val);
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
