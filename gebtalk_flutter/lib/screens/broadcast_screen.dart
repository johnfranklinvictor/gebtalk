import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../theme/colors.dart';
import '../models/chat_models.dart';
import '../widgets/animations.dart';
import '../utils/error_handler.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({Key? key}) : super(key: key);

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Composer state
  final List<String> _selectedContactIds = [];
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isInputFocused = false;
  String? _selectedListId;

  // File Picker state
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Group search state
  String _groupSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _inputFocusNode.addListener(() {
      setState(() => _isInputFocused = _inputFocusNode.hasFocus);
    });
    // Load fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.fetchBroadcastLists();
      appState.fetchBroadcastHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _toggleContactSelection(String id) {
    setState(() {
      _selectedListId = null; // Clear list selection if manually tweaking
      if (_selectedContactIds.contains(id)) {
        _selectedContactIds.remove(id);
      } else {
        _selectedContactIds.add(id);
      }
    });
  }

  void _selectGroup(BroadcastList group) {
    setState(() {
      _selectedListId = group.id;
      _selectedContactIds.clear();
      _selectedContactIds.addAll(group.members);
      _tabController.animateTo(0); // Switch back to Composer tab
    });
  }

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'jpg', 'jpeg', 'png', 'gif'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        // Enforce 20MB file limit
        if (file.size > 20 * 1024 * 1024) {
          ErrorHandler.showError("File size exceeds the 20MB limit.");
          return;
        }
        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      ErrorHandler.showError("Failed to pick file: $e");
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _sendBroadcast() async {
    final text = _msgController.text.trim();
    if (_selectedContactIds.isEmpty) {
      ErrorHandler.showError("Select at least one contact or group.");
      return;
    }
    if (text.isEmpty && _selectedFile == null) {
      ErrorHandler.showError("Message text or file attachment is required.");
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate progress if there is a file
    if (_selectedFile != null) {
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        setState(() {
          _uploadProgress = i / 10.0;
        });
      }
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.sendBroadcastMessage(
      _selectedContactIds,
      text,
      isFile: _selectedFile != null,
      fileName: _selectedFile?.name,
      fileSize: _selectedFile != null ? _formatFileSize(_selectedFile!.size) : null,
    );

    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Broadcast sent to ${_selectedContactIds.length} recipients successfully!")),
      );
      setState(() {
        _selectedContactIds.clear();
        _selectedListId = null;
        _selectedFile = null;
        _msgController.clear();
      });
      _tabController.animateTo(2); // Jump to History logs tab
    } else {
      ErrorHandler.showError("Broadcast failed to deliver. Verify service configuration.");
    }
  }

  void _showCreateGroupDialog() {
    String groupName = '';
    final List<String> groupMembers = [];
    String searchContactQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final appState = Provider.of<AppState>(context);
            final contacts = appState.contacts.where((c) {
              return c.folder == 'customers' &&
                  c.name.toLowerCase().contains(searchContactQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Create Broadcast Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 380,
                height: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: "Enter Group Name",
                        hintStyle: TextStyle(color: AppColors.textLight),
                        prefixIcon: Icon(Icons.label_outline_rounded, color: AppColors.textLight),
                      ),
                      onChanged: (val) => groupName = val,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search contacts...",
                        hintStyle: const TextStyle(color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textLight),
                        contentPadding: const EdgeInsets.all(8),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchContactQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: contacts.isEmpty
                          ? const Center(child: Text("No contacts found", style: TextStyle(color: AppColors.textLight)))
                          : ListView.builder(
                              itemCount: contacts.length,
                              itemBuilder: (context, index) {
                                final c = contacts[index];
                                final isAdded = groupMembers.contains(c.id);
                                return CheckboxListTile(
                                  value: isAdded,
                                  activeColor: AppColors.primary,
                                  title: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  subtitle: Text(c.role, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        groupMembers.add(c.id);
                                      } else {
                                        groupMembers.remove(c.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (groupName.trim().isEmpty) {
                      ErrorHandler.showError("Group name is required");
                      return;
                    }
                    if (groupMembers.isEmpty) {
                      ErrorHandler.showError("Add at least one member to the group");
                      return;
                    }
                    final appState = Provider.of<AppState>(context, listen: false);
                    final success = await appState.createBroadcastList(groupName.trim(), groupMembers);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Broadcast group '$groupName' created persistently!")),
                      );
                    }
                  },
                  child: const Text('Create Group', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Banner ──
            _buildHeaderBanner(),

            // ── Sleek Custom Glassmorphic Tab Switcher ──
            _buildTabSelector(),

            // ── Scrollable Body Pages ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildComposerTab(appState),
                  _buildGroupsTab(appState),
                  _buildHistoryTab(appState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Broadcast Hub",
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
                  "Transmit secure announcements to multiple client folders concurrently.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11.5,
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

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Product Sans'),
        tabs: const [
          Tab(text: "Composer"),
          Tab(text: "Saved Groups"),
          Tab(text: "History Logs"),
        ],
      ),
    );
  }

  Widget _buildComposerTab(AppState appState) {
    final contacts = appState.contacts.where((c) => c.folder == 'customers').toList();

    return Column(
      children: [
        // Selection State info
        if (_selectedListId != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Selected Group: ${appState.broadcastLists.firstWhere((l) => l.id == _selectedListId).name} (${_selectedContactIds.length} members)",
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedListId = null;
                      _selectedContactIds.clear();
                    });
                  },
                  child: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Choose Recipients (${_selectedContactIds.length} selected)",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Product Sans'),
                ),
                if (_selectedContactIds.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _selectedContactIds.clear()),
                    child: const Text("Clear Selection", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

        // Contacts list
        Expanded(
          child: contacts.isEmpty
              ? const Center(child: Text("No recipients available"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final c = contacts[index];
                    final isChecked = _selectedContactIds.contains(c.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () => _toggleContactSelection(c.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isChecked ? AppColors.primary.withOpacity(0.04) : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isChecked ? AppColors.primary : AppColors.border, width: isChecked ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: c.avatar.isNotEmpty ? NetworkImage(c.avatar) : null,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: c.avatar.isEmpty ? const Icon(Icons.person, color: AppColors.primary, size: 18) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(c.role, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Icon(
                                isChecked ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                color: isChecked ? AppColors.primary : AppColors.textLight,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Attachment Preview Card
        if (_selectedFile != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedFile!.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(_formatFileSize(_selectedFile!.size), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    if (!_isUploading)
                      GestureDetector(
                        onTap: () => setState(() => _selectedFile = null),
                        child: const Icon(Icons.close_rounded, color: AppColors.textLight, size: 20),
                      ),
                  ],
                ),
                if (_isUploading) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ],
              ],
            ),
          ),

        // Text input & transmit composer bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                    onPressed: _isUploading ? null : _pickFile,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _isInputFocused ? AppColors.primary : AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _msgController,
                        focusNode: _inputFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "Type announcements here...",
                          hintStyle: TextStyle(color: AppColors.textLight),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TapScaleWidget(
                onTap: _isUploading ? () {} : _sendBroadcast,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orangeGlow.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isUploading
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                      : const Center(
                          child: Text(
                            "Transmit Announcement",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Product Sans'),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 108), // Spacing to avoid bottom navigation bar overlap
      ],
    );
  }

  Widget _buildGroupsTab(AppState appState) {
    final lists = appState.broadcastLists.where((l) {
      return l.name.toLowerCase().contains(_groupSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search & create list bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search groups...",
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _groupSearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showCreateGroupDialog,
                icon: const Icon(Icons.group_add_rounded, size: 16, color: Colors.black),
                label: const Text("New Group", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // Groups list view
        Expanded(
          child: lists.isEmpty
              ? const Center(child: Text("No broadcast groups defined.", style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 6, bottom: 108),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.08),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${list.members.length} member(s)",
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.secondary, size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: const Text("Delete Group", style: TextStyle(color: Colors.white)),
                                    content: Text("Are you sure you want to delete broadcast group '${list.name}'?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: AppColors.textLight))),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                                        onPressed: () async {
                                          await appState.deleteBroadcastList(list.id);
                                          if (context.mounted) Navigator.pop(context);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _onSelectGroupTrigger(list),
                            child: const Text("Select", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _onSelectGroupTrigger(BroadcastList list) {
    _selectGroup(list);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Group '${list.name}' selected. Switch to composer to transmit.")),
    );
  }

  Widget _buildHistoryTab(AppState appState) {
    final history = appState.broadcastHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.textLight.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              "No Transmissions Logged",
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Product Sans'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 108),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header logs details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${item.date} • ${item.time}",
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Text(
                      "${item.deliveredCount}/${item.recipientCount} Sent",
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // File preview if list contains file
              if (item.isFile)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(item.fileName ?? "attachment", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      if (item.fileSize != null) ...[
                        const SizedBox(width: 6),
                        Text("(${item.fileSize})", style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                      ],
                    ],
                  ),
                ),

              // Text announcement body
              if (item.text.isNotEmpty)
                Text(
                  item.text,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.45),
                ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 8),
              
              // Recipients list
              Text(
                "Recipients: ${item.recipients}",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
