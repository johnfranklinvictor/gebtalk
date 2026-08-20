import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/webrtc_service.dart';
import '../theme/colors.dart';
import '../models/chat_models.dart';
import 'auth_screen.dart';
import '../utils/error_handler.dart';
import '../widgets/ebi_bot.dart';
import '../widgets/animations.dart';
import '../widgets/titan_glass_panel.dart';
import '../widgets/titan_background.dart';
import '../widgets/email_verification_modal.dart';
import '../widgets/create_account_modal.dart';
import '../widgets/change_password_modal.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const ProfileScreen({super.key, this.onTabChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _emailController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppState>(context, listen: false).currentProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _roleController = TextEditingController(text: profile?.role ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Enforce 5MB limit for avatar images
        if (file.size > 5 * 1024 * 1024) {
          ErrorHandler.showError("Avatar image size must be under 5MB");
          return;
        }

        List<int> bytes;
        if (file.bytes != null) {
          bytes = file.bytes!;
        } else if (file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        } else {
          ErrorHandler.showError("Cannot read file bytes.");
          return;
        }

        final base64String = base64Encode(bytes);
        final ext = file.extension ?? 'png';
        final dataUrl = 'data:image/$ext;base64,$base64String';

        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.currentProfile != null) {
          final updatedProfile = appState.currentProfile!.copyWith(avatar: dataUrl);
          setState(() => _isSaving = true);
          final success = await appState.updateProfile(updatedProfile);
          setState(() => _isSaving = false);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile picture updated successfully!")),
            );
          }
        }
      }
    } catch (e) {
      ErrorHandler.showError("Failed to pick image: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.currentProfile == null) return;

    final isCeo = appState.isCeo;
    final updated = appState.currentProfile!.copyWith(
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      email: isCeo ? _emailController.text.trim() : appState.currentProfile!.email,
    );

    setState(() {
      _isSaving = true;
    });

    final success = await appState.updateProfile(updated);

    setState(() {
      _isSaving = false;
      if (success) {
        _isEditing = false;
      }
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile details saved persistently!")),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to terminate your secure session and log out of GEBTALK?',
            style: TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                Provider.of<WebRtcService>(context, listen: false).resetForLogout();
                appState.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
              child: const Text('Confirm Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  ImageProvider _getAvatarImage(String avatarStr) {
    if (avatarStr.startsWith('data:image')) {
      final base64Content = avatarStr.split(',').last;
      return MemoryImage(base64Decode(base64Content));
    }
    return NetworkImage(avatarStr);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final profile = appState.currentProfile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: TitanBackground(
        preset: 'lounge',
        child: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), // Bottom padding for floating nav bar
              children: [
                // ── Header Banner ──
                _buildHeader(),
                const SizedBox(height: 24),

                // ── Profile Picture & Identity Card ──
                _buildIdentityCard(profile),
                const SizedBox(height: 20),

                // ── Administrative User Provisioning Card (CEO / Manager) ──
                if (appState.canCreateAccounts && !appState.isCustomerRole && !appState.isStaffRole) ...[
                  _buildAdminProvisioningCard(appState),
                  const SizedBox(height: 20),
                ],

                // ── Email Identity & VoIP Card ──
                _buildEmailIdentityCard(profile),
                const SizedBox(height: 20),

                // ── Form Details Panel ──
                _buildDetailsForm(),
                const SizedBox(height: 20),

                // ── Contact Information Section ──
                _buildContactInfoCard(profile),
                const SizedBox(height: 20),

                // ── Settings Cards ──
                _buildPreferencesCard(appState, profile),
                const SizedBox(height: 20),

                // ── App Information Details ──
                _buildAppInfoCard(),
                const SizedBox(height: 24),

                // ── Logout Button ──
                _buildLogoutButton(),
              ],
            ),
          ),
          
          // EBI Mascot integrated
          EbiBot(screen: 'settings', onTabChanged: widget.onTabChanged),
        ],
      ),
     ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "User Command Profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Product Sans',
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Manage profile settings, identity records, and notifications.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'Product Sans',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentityCard(UserProfile profile) {
    return TitanGlassPanel(
      glowColor: AppColors.accentForRole(profile.role),
      child: Column(
        children: [
          // Avatar upload sphere
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: profile.avatar.isNotEmpty
                        ? ClipOval(
                            child: Image(
                              image: _getAvatarImage(profile.avatar),
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.background,
                                  child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                                );
                              },
                            ),
                          )
                        : const CircleAvatar(
                            radius: 56,
                            backgroundColor: AppColors.background,
                            child: Icon(Icons.person, size: 50, color: AppColors.primary),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: TapScaleWidget(
                    onTap: _isSaving ? () {} : _pickAvatar,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.orangeGradient,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orangeGlow.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            profile.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Product Sans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.role,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Product Sans',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              "Registered: ${profile.phone}",
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Product Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProvisioningCard(AppState appState) {
    final isCeo = appState.isCeo;
    final roleTitle = isCeo ? 'CEO Executive Console' : 'Manager Provisioning Console';
    final roleBadgeColor = isCeo ? const Color(0xFF60A5FA) : const Color(0xFFA855F7);

    return TitanGlassPanel(
      glowColor: roleBadgeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleBadgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: roleBadgeColor.withOpacity(0.3)),
                ),
                child: Icon(Icons.admin_panel_settings_rounded, color: roleBadgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                    Text(
                      isCeo 
                          ? 'Provision Manager, Staff & Customer accounts' 
                          : 'Provision Staff & Customer accounts with specialist routing',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: roleBadgeColor.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: roleBadgeColor.withOpacity(0.5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => CreateAccountModal.show(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(
                'Create & Provision User Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm() {
    final appState = Provider.of<AppState>(context, listen: false);
    final profile = appState.currentProfile;
    final String currentRole = (profile?.role ?? _roleController.text).toLowerCase().trim();
    final bool isUserCeo = !currentRole.contains('customer') &&
        !currentRole.contains('client') &&
        !currentRole.contains('staff') &&
        !currentRole.contains('specialist') &&
        !currentRole.contains('manager') &&
        (currentRole == 'ceo' ||
            currentRole == 'founder' ||
            currentRole == 'chief executive' ||
            currentRole.startsWith('ceo ') ||
            currentRole.endsWith(' ceo') ||
            currentRole == 'global ceo') &&
        appState.isCeo;

    return TitanGlassPanel(
      glowColor: AppColors.accentForRole(appState.currentProfile?.role ?? ''),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Account Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Product Sans',
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            if (_isEditing) {
                              // Reset details on cancel
                              final p = Provider.of<AppState>(context, listen: false).currentProfile;
                              _nameController.text = p?.name ?? '';
                              _roleController.text = p?.role ?? '';
                              _emailController.text = p?.email ?? '';
                            }
                            _isEditing = !_isEditing;
                          });
                        },
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _isEditing ? "Cancel" : "Edit Details",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Product Sans',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildFieldLabel("Full Name"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              enabled: _isEditing && !_isSaving,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              validator: (val) => val == null || val.trim().isEmpty ? "Name cannot be empty" : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textLight, size: 18),
                hintText: "Enter full name",
              ),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel("Corporate Role"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _roleController,
              enabled: isUserCeo && _isEditing && !_isSaving,
              style: TextStyle(
                color: (isUserCeo || !_isEditing) ? Colors.white : Colors.white60,
                fontSize: 13,
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Role cannot be empty" : null,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.work_outline, color: AppColors.textLight, size: 18),
                hintText: "Enter corporate role",
                helperText: !isUserCeo && _isEditing ? "Corporate role is assigned by the CEO" : null,
                helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                suffixIcon: !isUserCeo && _isEditing ? const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 16) : null,
              ),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel("Secure Email Address"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              enabled: isUserCeo && _isEditing && !_isSaving,
              style: TextStyle(
                color: (isUserCeo || !_isEditing) ? Colors.white : Colors.white60,
                fontSize: 13,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Email cannot be empty";
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) return "Invalid email address";
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textLight, size: 18),
                hintText: "Enter email address",
                helperText: !isUserCeo ? "Login email is managed exclusively by the CEO" : null,
                helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                suffixIcon: !isUserCeo ? const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 16) : null,
              ),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel("Account Password"),
            const SizedBox(height: 6),
            InkWell(
              onTap: isUserCeo ? () => ChangePasswordModal.show(context) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.textLight, size: 18),
                    const SizedBox(width: 12),
                    const Text(
                      "••••••••••••",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isUserCeo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.key_rounded, color: AppColors.primary, size: 13),
                            SizedBox(width: 5),
                            Text(
                              "Change Password",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Product Sans',
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, color: Colors.white38, size: 13),
                            SizedBox(width: 5),
                            Text(
                              "Managed by CEO",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Product Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 20),
              TapScaleWidget(
                onTap: _isSaving ? () {} : _saveProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isSaving
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                          ),
                        )
                      : const Center(
                          child: Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Product Sans',
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailIdentityCard(UserProfile profile) {
    final bool isVerified = profile.email.isNotEmpty && (profile.verificationStatus == 'Verified');
    final appState = Provider.of<AppState>(context, listen: false);
    final String currentRole = profile.role.toLowerCase().trim();
    final bool isUserCeo = !currentRole.contains('customer') &&
        !currentRole.contains('client') &&
        !currentRole.contains('staff') &&
        !currentRole.contains('specialist') &&
        !currentRole.contains('manager') &&
        (currentRole == 'ceo' ||
            currentRole == 'founder' ||
            currentRole == 'chief executive' ||
            currentRole.startsWith('ceo ') ||
            currentRole.endsWith(' ceo') ||
            currentRole == 'global ceo') &&
        appState.isCeo;
    
    return TitanGlassPanel(
      glowColor: isVerified ? AppColors.primary : Colors.orangeAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.orangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isVerified ? Icons.mark_email_read_rounded : Icons.mail_outline_rounded,
                      color: isVerified ? AppColors.primary : Colors.orangeAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Email & VoIP Identity",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Product Sans',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : Colors.orangeAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 12,
                      color: isVerified ? AppColors.primary : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? "Verified ID" : "Unverified",
                      style: TextStyle(
                        color: isVerified ? AppColors.primary : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.email.isNotEmpty ? profile.email : "No email linked to this GebTalk account",
            style: TextStyle(
              color: profile.email.isNotEmpty ? Colors.white : AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Product Sans',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Linking your verified email allows clients and staff to call you via email link and dispatches Missed VoIP Call Alerts when you are offline.",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
              fontFamily: 'Product Sans',
            ),
          ),
          const SizedBox(height: 16),
          if (isUserCeo)
            TapScaleWidget(
              onTap: () => EmailVerificationModal.show(
                context,
                initialEmail: profile.email,
                onVerified: () {
                  setState(() {
                    _emailController.text = Provider.of<AppState>(context, listen: false).currentProfile?.email ?? '';
                  });
                },
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.edit_rounded : Icons.verified_user_rounded,
                        size: 15,
                        color: isVerified ? AppColors.primary : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVerified ? "Change / Re-verify Email" : "Verify Email Address with OTP",
                        style: TextStyle(
                          color: isVerified ? AppColors.primary : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Product Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Colors.white38),
                  SizedBox(width: 8),
                  Text(
                    "Login email is managed exclusively by the CEO",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Product Sans',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: 'Product Sans',
      ),
    );
  }

  Widget _buildPreferencesCard(AppState appState, UserProfile profile) {
    return TitanGlassPanel(
      glowColor: AppColors.accentForRole(profile.role),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Preferences & Privacy",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Product Sans',
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleRow(
            icon: Icons.notifications_active_outlined,
            title: "Enable System Notifications",
            value: profile.notificationsEnabled,
            onChanged: (val) {
              appState.updateProfile(profile.copyWith(notificationsEnabled: val));
            },
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          _buildToggleRow(
            icon: Icons.volume_up_outlined,
            title: "Notification Sounds",
            value: profile.notificationSound,
            onChanged: (val) {
              appState.updateProfile(profile.copyWith(notificationSound: val));
            },
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          _buildToggleRow(
            icon: Icons.vibration_outlined,
            title: "Haptic Vibration Feedback",
            value: profile.notificationVibration,
            onChanged: (val) {
              appState.updateProfile(profile.copyWith(notificationVibration: val));
            },
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          _buildToggleRow(
            icon: Icons.verified_user_outlined,
            title: "Two-Factor Auth (2FA)",
            value: profile.security2fa,
            onChanged: (val) {
              appState.updateProfile(profile.copyWith(security2fa: val));
            },
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          _buildToggleRow(
            icon: Icons.done_all_rounded,
            title: "Transmit Read Receipts",
            value: profile.readReceipts,
            onChanged: (val) {
              appState.updateProfile(profile.copyWith(readReceipts: val));
            },
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          _buildToggleRow(
            icon: Icons.visibility_outlined,
            title: "Show Last Seen Status",
            value: profile.lastSeenVisible,
            onChanged: (val) {
              appState.updateProfile(profile.copyWith(lastSeenVisible: val));
            },
          ),
          if (appState.hasAdminPrivileges) ...[
            const Divider(color: AppColors.borderLight, height: 20),
            _buildToggleRow(
              icon: Icons.admin_panel_settings_outlined,
              title: "Staff View Mode (Preview Permissions)",
              value: !appState.isAdmin,
              onChanged: (val) {
                if (val != !appState.isAdmin) {
                  appState.toggleAdminMode();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontFamily: 'Product Sans',
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    final appState = Provider.of<AppState>(context, listen: false);
    return TitanGlassPanel(
      glowColor: AppColors.accentForRole(appState.currentProfile?.role ?? ''),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Center(
                  child: Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "GEBTALK Corporate HQ",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Product Sans'),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Version 1.5.2-Beta (Release)",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Product Sans'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),
          Text(
            "Designed and compiled exclusively for EB GLOBAL digital workspace environments. All transmissions encrypted.",
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.8),
              fontSize: 10.5,
              height: 1.45,
              fontFamily: 'Product Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(UserProfile profile) {
    return TitanGlassPanel(
      glowColor: AppColors.accentForRole(profile.role),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact Information",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Product Sans',
            ),
          ),
          const SizedBox(height: 16),
          // Verified Phone Number Badge & Phone Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "✓ Verified Phone Number",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.phone.isNotEmpty ? profile.phone : "Not Available",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Product Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 32),
          // Country Display
          Row(
            children: [
              const Icon(Icons.public_rounded, color: AppColors.textLight, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Country",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.countryName.isNotEmpty 
                          ? "${profile.countryName} ${profile.countryFlag}" 
                          : "Not Configured",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 32),
          // Account Creation Date
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppColors.textLight, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Account Creation Date",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.createdAt.isNotEmpty ? profile.createdAt : "Not Available",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 32),
          // Verification Status
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.textLight, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Verification Status",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.verificationStatus.isNotEmpty ? profile.verificationStatus : "Verified",
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TapScaleWidget(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.secondary, size: 18),
            SizedBox(width: 8),
            Text(
              "Log Out of Workspace",
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Product Sans',
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
