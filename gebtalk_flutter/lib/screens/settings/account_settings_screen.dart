import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/colors.dart';
import '../../widgets/email_verification_modal.dart';
import '../../widgets/change_password_modal.dart';

/// WhatsApp Account Settings Screen
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _securityNotifications = true;
  bool _twoStepVerification = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppState>(context, listen: false).currentProfile;
    _twoStepVerification = profile?.security2fa ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final profile = appState.currentProfile;
    final userEmail = profile?.email.isNotEmpty == true ? profile!.email : 'None linked';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Security & Verification'),
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text('Security notifications', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(
              'Get notified when security code changes for any of your contacts.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            value: _securityNotifications,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _securityNotifications = val),
          ),
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text('Two-step verification', style: TextStyle(color: Colors.white, fontSize: 15)),
            subtitle: Text(
              'For extra security, require a 6-digit PIN when registering your phone number with GebTalk again.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            value: _twoStepVerification,
            activeColor: AppColors.primary,
            onChanged: (val) => _toggleTwoStep(val, appState),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildHeader('Account Management'),
          _buildAccountTile(
            icon: Icons.alternate_email_rounded,
            title: 'Email address',
            subtitle: appState.isCeo
                ? '$userEmail • Tap to verify or update with OTP'
                : '$userEmail • Managed exclusively by CEO',
            onTap: appState.isCeo
                ? () => EmailVerificationModal.show(
                    context,
                    initialEmail: profile?.email,
                    onVerified: () => setState(() {}),
                  )
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login email is managed exclusively by the CEO.'),
                      ),
                    );
                  },
          ),
          _buildAccountTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change password',
            subtitle: appState.isCeo
                ? 'Update your account login credentials'
                : 'Locked • Managed exclusively by CEO',
            onTap: appState.isCeo
                ? () => ChangePasswordModal.show(context)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Staff and Customer passwords are managed exclusively by the CEO.'),
                      ),
                    );
                  },
          ),
          _buildAccountTile(
            icon: Icons.phone_android_rounded,
            title: 'Change number',
            subtitle: 'Migrate your account info, groups & settings to a new number',
            onTap: () => _showChangeNumberDialog(context),
          ),
          _buildAccountTile(
            icon: Icons.description_rounded,
            title: 'Request account info',
            subtitle: 'Download an encrypted report of your GebTalk account data and settings',
            onTap: () => _showRequestReportDialog(context),
          ),
          _buildAccountTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete my account',
            subtitle: 'Erase message history, delete groups, and terminate account permanently',
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context, appState),
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

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }

  void _toggleTwoStep(bool enable, AppState appState) async {
    if (enable) {
      final pinCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Set 6-Digit PIN', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 20),
            decoration: const InputDecoration(hintText: '••••••', hintStyle: TextStyle(color: Colors.white38)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final pin = pinCtrl.text.trim();
                if (pin.length == 6) {
                  Navigator.pop(ctx);
                  await appState.setAccount2FA(true, pin);
                  setState(() => _twoStepVerification = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Two-step verification activated!')),
                  );
                }
              },
              child: const Text('Enable', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      await appState.setAccount2FA(false, '');
      setState(() => _twoStepVerification = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-step verification disabled.')),
      );
    }
  }

  void _showChangeNumberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Change Phone Number', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Changing your phone number will migrate all your chat history, groups, and contact links to your new phone number.\n\nBefore continuing, ensure your new number can receive SMS verification.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Next', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRequestReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Account Report', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Create an encrypted zip report of your GebTalk account information and settings. The report will be ready in approximately 3 days.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account report requested. You will receive a notification when ready.')),
              );
            },
            child: const Text('Request Report', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this account?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'WARNING: Deleting your account will:\n• Delete your account info and profile photo\n• Delete you from all GebTalk groups\n• Delete your message history on this device and encrypted backups\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.deleteAccount();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('DELETE ACCOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
