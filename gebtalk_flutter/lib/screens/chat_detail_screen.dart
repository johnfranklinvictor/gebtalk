import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../widgets/ebi_bot.dart';
import '../theme/colors.dart';
import '../widgets/animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/error_handler.dart';
import '../utils/file_download_helper.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ChatDetailContent(showLeadingBackButton: true);
  }
}

class ChatDetailContent extends StatefulWidget {
  final bool showLeadingBackButton;

  const ChatDetailContent({
    Key? key,
    this.showLeadingBackButton = true,
  }) : super(key: key);

  @override
  State<ChatDetailContent> createState() => _ChatDetailContentState();
}

class _ChatDetailContentState extends State<ChatDetailContent>
    with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isInputFocused = false;
  bool _isPanelOpen = false;

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Download simulation progress states
  final Map<int, double> _downloadProgresses = {};
  final Set<int> _isDownloading = {};

  // Typing indicator animation
  late AnimationController _typingController;
  late List<Animation<double>> _dotAnimations;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      setState(() => _isInputFocused = _inputFocusNode.hasFocus);
    });

    // Staggered bounce for 3 dots
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotAnimations = List.generate(3, (i) {
      final start = i * 0.2;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _typingController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeInOut),
        ),
      );
    });

    // Poll active chat history every 2 seconds for real-time updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.activeContactId != null && !appState.isLoading) {
          appState.pollMessages();
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_isUploading) return;
    if (_selectedFile != null) {
      _uploadAndSendFile();
      return;
    }
    
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.sendMessage(text);
    if (success) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _simulateAudioAttach() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.sendMessage('', isAudio: true, duration: "0:42");
    if (success) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true, // For web, this loads the bytes into memory if needed
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        if (!_validateFile(file)) return;
        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      ErrorHandler.showError("Failed to pick file: $e");
    }
  }

  bool _validateFile(PlatformFile file) {
    // 20 MB size limit
    const int maxSize = 20 * 1024 * 1024;
    if (file.size > maxSize) {
      ErrorHandler.showError("File size exceeds 20MB limit.");
      return false;
    }
    return true;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'xls':
      case 'xlsx': return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx': return 'application/vnd.ms-powerpoint';
      case 'zip': return 'application/zip';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  void _triggerDownloadOrOpen(int msgId, String? fileData, String fileName) async {
    if (_isDownloading.contains(msgId)) return;
    if (fileData == null || fileData.isEmpty) {
      ErrorHandler.showError("File URL is invalid.");
      return;
    }

    final resolvedUrl = ApiService.resolveUrl(fileData);

    setState(() {
      _isDownloading.add(msgId);
      _downloadProgresses[msgId] = 0.0;
    });

    // Simulate progress increments
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _downloadProgresses[msgId] = i / 10.0;
      });
    }

    try {
      if (resolvedUrl.startsWith('data:')) {
        triggerFileView(resolvedUrl);
      } else {
        // Trigger actual download for network files
        await triggerFileDownload(resolvedUrl, fileName);
      }

      // Complete progress simulation
      for (int i = 6; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        setState(() {
          _downloadProgresses[msgId] = i / 10.0;
        });
      }

      ErrorHandler.showSuccess("Download started successfully!");
    } catch (e) {
      ErrorHandler.showError("Download failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading.remove(msgId);
          _downloadProgresses.remove(msgId);
        });
      }
    }
  }

  void _showPdfOptionsDialog(BuildContext context, Message msg, String? fileData, String fileName) {
    final resolvedUrl = fileData != null ? ApiService.resolveUrl(fileData) : null;
    final extension = fileName.split('.').last.toUpperCase();
    final fileSize = msg.fileSize ?? '2.5 MB';
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.border, width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  "PDF Attachment",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Product Sans',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.insert_drive_file_outlined, "Size: $fileSize"),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.calendar_today_outlined, "Uploaded: ${msg.time}"),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.extension_outlined, "Format: $extension Document"),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actionsPadding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                label: const Text("View PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _viewPdf(resolvedUrl, fileName);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                label: const Text("Download PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _downloadPdf(msg.id, resolvedUrl, fileName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _viewPdf(String? url, String fileName) {
    if (url == null || url.isEmpty) {
      ErrorHandler.showError("PDF URL is invalid.");
      return;
    }
    try {
      triggerFileView(url);
    } catch (e) {
      ErrorHandler.showError("Error opening PDF: $e");
    }
  }

  void _downloadPdf(int msgId, String? url, String fileName) async {
    if (url == null || url.isEmpty) {
      ErrorHandler.showError("PDF URL is invalid.");
      return;
    }

    setState(() {
      _isDownloading.add(msgId);
      _downloadProgresses[msgId] = 0.0;
    });

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _downloadProgresses[msgId] = i / 10.0;
      });
    }

    try {
      await triggerFileDownload(url, fileName);
      
      for (int i = 6; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        setState(() {
          _downloadProgresses[msgId] = i / 10.0;
        });
      }
      
      ErrorHandler.showSuccess("Download started successfully!");
    } catch (e) {
      ErrorHandler.showError("Download failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading.remove(msgId);
          _downloadProgresses.remove(msgId);
        });
      }
    }
  }

  void _uploadAndSendFile() async {
    if (_selectedFile == null) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    List<int>? fileBytes = _selectedFile!.bytes;
    if (fileBytes == null && !kIsWeb && _selectedFile!.path != null) {
      try {
        fileBytes = await io.File(_selectedFile!.path!).readAsBytes();
      } catch (e) {
        print("Error reading file: $e");
      }
    }

    if (fileBytes == null) {
      ErrorHandler.showError("Failed to read file contents.");
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      return;
    }

    // Start upload in parallel
    bool uploadComplete = false;
    final uploadFuture = ApiService.uploadFile(fileBytes, _selectedFile!.name);

    // Simulated progress increments while HTTP upload in progress
    for (int i = 1; i <= 9; i++) {
      if (uploadComplete) break;
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _uploadProgress = i / 10.0;
      });
    }

    final uploadedUrl = await uploadFuture;
    uploadComplete = true;

    if (uploadedUrl == null) {
      ErrorHandler.showError("Failed to upload file to storage server.");
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      return;
    }

    setState(() {
      _uploadProgress = 1.0;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    
    // Ensure we have an extension to show, fallback to "FILE"
    String ext = _selectedFile!.extension?.toUpperCase() ?? "FILE";
    String formattedSize = _formatFileSize(_selectedFile!.size);
    String displaySizeStr = "$formattedSize • $ext";
    
    // Use the text input as caption if available
    String caption = _msgController.text.trim();
    _msgController.clear();

    final messageText = jsonEncode({
      'caption': caption,
      'url': uploadedUrl,
    });
    
    final success = await appState.sendMessage(
      messageText, 
      isFile: true, 
      fileName: _selectedFile!.name, 
      fileSize: displaySizeStr,
    );
    
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _selectedFile = null;
      });
      if (success) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } else {
        ErrorHandler.showError("Failed to send file message.");
      }
    }
  }

  void _openInfoDrawer(BuildContext context, Contact contact, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        "Contact Management",
                        style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Folder Picker
                  const Text("Assign to Folder", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: appState.folders.where((f) => f.id != 'all').map((folder) {
                        final isSelected = contact.folder == folder.id;
                        return GestureDetector(
                          onTap: () async {
                            await appState.updateContactAssignments(contact.id, folder.id, contact.tags.map((t) => t.id).toList());
                            setModalState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? _parseColor(folder.color).withValues(alpha: 0.12) : AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? _parseColor(folder.color) : AppColors.border,
                              ),
                            ),
                            child: Text(
                              folder.name,
                              style: TextStyle(
                                color: isSelected ? AppColors.textMain : AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReactionPicker(BuildContext context, int messageId, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['👍', '❤️', '😂', '😮', '😢'].map((emoji) {
              return TapScaleWidget(
                onTap: () {
                  appState.reactToMessage(messageId, emoji);
                  Navigator.pop(context);
                },
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Date divider between message groups ──
  Widget _buildDateDivider(String dateLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.border.withValues(alpha: 0.0),
                    AppColors.border,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.border,
                    AppColors.border.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Typing indicator (3 bouncing dots) ──
  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Transform.translate(
                      offset: Offset(0, -4 * sin(_dotAnimations[i].value * pi)),
                      child: Container(
                        margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.3 + (_dotAnimations[i].value * 0.5)),
                        ),
                      ),
                    );
                  }),
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
    final contact = appState.activeContact;
    final messages = appState.activeChatHistory;

    // Trigger scrolling on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    if (contact == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left: Main chat screen (app bar, message list, input bar)
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // ─── Gradient App Bar ───
                    _buildGradientAppBar(context, contact, appState),

                    // ─── Message History Feed ───
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];

                          // Date divider logic: show when the date label changes
                          Widget? divider;
                          if (index == 0) {
                            divider = _buildDateDivider(_extractDateLabel(msg.time));
                          } else {
                            final prevDate = _extractDateLabel(messages[index - 1].time);
                            final curDate = _extractDateLabel(msg.time);
                            if (curDate != prevDate) {
                              divider = _buildDateDivider(curDate);
                            }
                          }

                          return AnimatedListItem(
                            index: index,
                            child: Column(
                              children: [
                                if (divider != null) divider,
                                _buildMessageBubble(msg, appState),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ─── Typing Indicator (shown when loading) ───
                    if (appState.isLoading) _buildTypingIndicator(),

                    // ─── Message Input Bar ───
                    SafeArea(
                      top: false,
                      child: _buildInputBar(),
                    ),
                  ],
                ),
                EbiBot(screen: widget.showLeadingBackButton ? 'chat_detail' : 'chat_detail_embedded'),
              ],
            ),
          ),
          // Right: Collapsible side panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isPanelOpen ? 320 : 0,
            child: ClipRect(
              child: SizedBox(
                width: 320,
                child: _buildSideInfoPanel(context, contact, appState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchPhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(url);
    } catch (e) {
      ErrorHandler.showError("Could not launch phone dialer: $e");
    }
  }

  // ── Gradient App Bar ──
  Widget _buildGradientAppBar(BuildContext context, Contact contact, AppState appState) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A08615B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              if (widget.showLeadingBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (!widget.showLeadingBackButton) const SizedBox(width: 16),
              _buildAvatar(contact),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Customer: ${contact.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        fontFamily: 'Product Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (contact.phone.isNotEmpty)
                      Text(
                        "Phone: ${contact.phone}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontFamily: 'Product Sans',
                        ),
                      )
                    else
                      Text(
                        contact.role,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontFamily: 'Product Sans',
                        ),
                      ),
                  ],
                ),
              ),
              if (contact.phone.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => _launchPhoneCall(contact.phone),
                  tooltip: 'Call Customer',
                ),
              IconButton(
                icon: Icon(
                  _isPanelOpen ? Icons.info : Icons.info_outline,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPanelOpen = !_isPanelOpen;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Enhanced Input Bar ──
  Widget _buildFilePreview() {
    if (_selectedFile == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFileSize(_selectedFile!.size),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!_isUploading)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                ),
            ],
          ),
          if (_isUploading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Uploading... ${(_uploadProgress * 100).toInt()}%",
              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Teal shimmer top border
        Container(
          height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x0008615B),
                AppColors.tealGlow,
                AppColors.primaryLight,
                AppColors.tealGlow,
                Color(0x0008615B),
              ],
              stops: [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilePreview(),
              Row(
                children: [
                  // Attachment button with teal tint circle
                  _buildIconCircle(Icons.attach_file, _isUploading ? () {} : _pickFile),
                  const SizedBox(width: 2),
                  // Mic button with teal tint circle
                  _buildIconCircle(Icons.mic_none, _simulateAudioAttach),
                  const SizedBox(width: 6),
                  // Text input with animated gradient border
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: _isInputFocused
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [AppColors.border, AppColors.border],
                              ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _msgController,
                          focusNode: _inputFocusNode,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                          enabled: !_isUploading,
                          decoration: InputDecoration(
                            hintText: _selectedFile != null ? "Add a caption..." : "Type a secure message...",
                            hintStyle: const TextStyle(color: AppColors.textLight),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button — orange gradient circle with glow + TapScale
                  TapScaleWidget(
                    onTap: _isUploading ? () {} : _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.orangeGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orangeGlow.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isUploading 
                          ? const SizedBox(
                              width: 18, 
                              height: 18, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Icon circle for attach / mic buttons ──
  Widget _buildIconCircle(IconData icon, VoidCallback onPressed) {
    return TapScaleWidget(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _buildStatusCheckmark(String status) {
    Widget icon;
    if (status == 'sent') {
      icon = const Icon(Icons.check, size: 12, color: AppColors.textMuted);
    } else if (status == 'delivered') {
      icon = const Icon(Icons.done_all_rounded, size: 13, color: AppColors.textMuted);
    } else if (status == 'read') {
      icon = const Icon(Icons.done_all_rounded, size: 13, color: AppColors.primary);
    } else {
      return const SizedBox.shrink();
    }
    
    return icon
        .animate(key: ValueKey(status))
        .scale(duration: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMessageBubble(Message msg, AppState appState) {
    final isUser = msg.isUser;

    return GestureDetector(
      onLongPress: () => _showReactionPicker(context, msg.id, appState),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Bubble ──
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                // User: gradient teal | Contact: white with left teal accent border
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : AppColors.surface,
                border: isUser
                    ? null
                    : const Border(
                        left: BorderSide(color: AppColors.primary, width: 2),
                      ),
                boxShadow: [
                  if (isUser)
                    BoxShadow(
                      color: AppColors.tealGlow.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  if (!isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isAudio) ...[
                      // Audio Message View
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: isUser ? Colors.white : AppColors.primary),
                          const SizedBox(width: 8),
                          Container(
                            width: 120,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isUser ? Colors.white.withValues(alpha: 0.24) : AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            msg.duration ?? "0:00",
                            style: TextStyle(
                              color: isUser ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ] else if (msg.isFile) ...[
                      _buildFileBubbleContent(msg, isUser),
                    ] else ...[
                      // Normal text
                      Text(
                        msg.text,
                        style: TextStyle(color: isUser ? Colors.white : AppColors.textMain, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Reactions & timestamp below bubble ──
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timestamp
                Text(
                  msg.time,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 9),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  _buildStatusCheckmark(msg.status),
                ],
                const SizedBox(width: 6),
                // Reactions list
                if (msg.reactions.isNotEmpty)
                  Row(
                    children: msg.reactions.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(left: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.black.withValues(alpha: 0.15) : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isUser ? Colors.transparent : AppColors.border, width: 0.5),
                        ),
                        child: Text(r, style: TextStyle(color: isUser ? Colors.white : AppColors.textMain, fontSize: 10)),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileBubbleContent(Message msg, bool isUser) {
    String caption = '';
    String? fileData;
    try {
      final trimmedText = msg.text.trim();
      if (trimmedText.startsWith('{') && trimmedText.endsWith('}')) {
        final parsed = jsonDecode(trimmedText);
        caption = parsed['caption'] ?? '';
        fileData = parsed['url'] ?? parsed['data'];
      } else if (trimmedText.startsWith('http') || trimmedText.startsWith('data:')) {
        fileData = trimmedText;
        caption = '';
      } else {
        caption = trimmedText;
      }
    } catch (e) {
      caption = msg.text;
    }

    final filename = msg.fileName ?? 'file';
    final extension = filename.split('.').last.toLowerCase();
    
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension) ||
                    (fileData != null && (
                      fileData.startsWith('data:image') ||
                      fileData.toLowerCase().contains('.png') ||
                      fileData.toLowerCase().contains('.jpg') ||
                      fileData.toLowerCase().contains('.jpeg') ||
                      fileData.toLowerCase().contains('.webp') ||
                      fileData.toLowerCase().contains('.gif')
                    ));
    final isPdf = extension == 'pdf';

    if (isImage) {
      return _buildImageBubble(msg, caption, fileData, isUser);
    } else if (isPdf) {
      return _buildPdfBubble(msg, caption, fileData, isUser);
    } else {
      return _buildGenericDocBubble(msg, caption, fileData, isUser, extension);
    }
  }

  Widget _buildImageBubble(Message msg, String caption, String? fileData, bool isUser) {
    final filename = msg.fileName ?? 'image.jpg';
    final filesize = msg.fileSize ?? '';

    Widget imageWidget;
    if (fileData != null && fileData.startsWith('data:image')) {
      final base64Content = fileData.split(',').last;
      try {
        imageWidget = Image.memory(
          base64Decode(base64Content),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(filename),
        );
      } catch (e) {
        imageWidget = _buildImageErrorPlaceholder(filename);
      }
    } else if (fileData != null && fileData.startsWith('http')) {
      final resolvedUrl = ApiService.resolveUrl(fileData);
      imageWidget = Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(filename),
      );
    } else {
      // Premium Unsplash default placeholder based on hash to look diverse
      final index = (filename.hashCode % 5).abs();
      final placeholders = [
        "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80",
        "https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?auto=format&fit=crop&w=400&q=80",
        "https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?auto=format&fit=crop&w=400&q=80",
        "https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?auto=format&fit=crop&w=400&q=80",
        "https://images.unsplash.com/photo-1574169208507-84376144848b?auto=format&fit=crop&w=400&q=80",
      ];
      imageWidget = Image.network(
        placeholders[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(filename),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _openFullscreenImage(context, fileData, filename, caption),
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUser ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.5),
              child: Stack(
                children: [
                  imageWidget,
                  // Glassmorphic metadata overlay badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        filesize.split('•').first.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              caption,
              style: TextStyle(color: isUser ? Colors.white : AppColors.textMain, fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageErrorPlaceholder(String filename) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.red.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_rounded, color: AppColors.secondary, size: 36),
          const SizedBox(height: 8),
          Text(
            filename,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openFullscreenImage(BuildContext context, String? fileData, String filename, String caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Interactive Image Viewer
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: fileData != null && fileData.startsWith('data:image')
                      ? Image.memory(base64Decode(fileData.split(',').last))
                      : fileData != null && fileData.startsWith('http')
                          ? Image.network(ApiService.resolveUrl(fileData))
                          : Image.network("https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80"),
                ),
              ),
              // Header actions
              Positioned(
                top: 40,
                right: 20,
                child: Row(
                  children: [
                    // Download/Open button
                    ClipOval(
                      child: Container(
                        color: Colors.white.withOpacity(0.12),
                        child: IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                          onPressed: () {
                            if (fileData != null && fileData.isNotEmpty) {
                              try {
                                final resolved = ApiService.resolveUrl(fileData);
                                triggerFileView(resolved);
                                ErrorHandler.showSuccess("Opening image in new tab...");
                              } catch (e) {
                                ErrorHandler.showError("Failed to open image: $e");
                              }
                            } else {
                              ErrorHandler.showError("Image URL is invalid.");
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Close button
                    ClipOval(
                      child: Container(
                        color: Colors.white.withOpacity(0.12),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Footer Caption
              if (caption.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(
                        caption,
                        style: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none, fontFamily: 'Product Sans'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfBubble(Message msg, String caption, String? fileData, bool isUser) {
    final filename = msg.fileName ?? 'document.pdf';
    final filesize = msg.fileSize ?? '2.5 MB';
    
    // Deterministic page count based on filename
    final mockPageCount = (filename.hashCode % 18).abs() + 3;
    final isDownloading = _isDownloading.contains(msg.id);
    final downloadProgress = _downloadProgresses[msg.id] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showPdfOptionsDialog(context, msg, fileData, filename),
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.black.withOpacity(0.2) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUser 
                    ? Colors.white.withOpacity(0.2) 
                    : AppColors.secondary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filename,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${filesize.split('•').first.trim()} • $mockPageCount Pages",
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    if (isDownloading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                          strokeWidth: 2.0,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: isUser ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
                        size: 20,
                      ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 3.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              caption,
              style: TextStyle(color: isUser ? Colors.white : AppColors.textMain, fontSize: 12.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenericDocBubble(Message msg, String caption, String? fileData, bool isUser, String ext) {
    final filename = msg.fileName ?? 'file';
    final filesize = msg.fileSize ?? '1.2 MB';

    IconData icon;
    Color accentColor;
    
    switch (ext.toLowerCase()) {
      case 'doc':
      case 'docx':
        icon = Icons.description_rounded;
        accentColor = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart_rounded;
        accentColor = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow_rounded;
        accentColor = Colors.orange;
        break;
      case 'zip':
      case 'rar':
        icon = Icons.folder_zip_rounded;
        accentColor = Colors.amber;
        break;
      case 'txt':
        icon = Icons.article_rounded;
        accentColor = Colors.blueGrey;
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
        accentColor = Colors.teal;
    }

    final isDownloading = _isDownloading.contains(msg.id);
    final downloadProgress = _downloadProgresses[msg.id] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _triggerDownloadOrOpen(msg.id, fileData, filename),
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.black.withOpacity(0.2) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUser 
                    ? Colors.white.withOpacity(0.2) 
                    : accentColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filename,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filesize.split('•').first.trim(),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    if (isDownloading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: accentColor,
                          strokeWidth: 2.0,
                        ),
                      )
                    else
                      Icon(
                        Icons.open_in_new_rounded,
                        color: isUser ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
                        size: 18,
                      ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 3.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              caption,
              style: TextStyle(color: isUser ? Colors.white : AppColors.textMain, fontSize: 12.5),
            ),
          ),
        ],
      ],
    );
  }

  // ── Avatar with PulsingDot status indicator ──
  Widget _buildAvatar(Contact contact) {
    Widget avatarWidget;

    if (contact.avatar.isEmpty) {
      avatarWidget = Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.psychology, color: Colors.white, size: 20),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(contact.avatar),
        backgroundColor: Colors.transparent,
      );
    }

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Center(child: avatarWidget),
          // Online PulsingDot overlay — bottom-right
          const Positioned(
            right: 0,
            bottom: 0,
            child: PulsingDot(
              color: Color(0xFF22C55E),
              size: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  /// Extract a readable date label from the time string for dividers.
  /// Falls back to the raw time if no date portion exists.
  String _extractDateLabel(String time) {
    // If the time string contains a comma or multi-word date, use it directly.
    // Otherwise create a generic "Today" label.
    if (time.contains(',')) {
      return time.split(',').first.trim();
    }
    return 'Today';
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildSideInfoPanel(BuildContext context, Contact contact, AppState appState) {
    final staffMembers = appState.contacts.where((c) => c.folder == 'staff').toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          left: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.contact_page_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Customer Info",
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Product Sans',
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      setState(() {
                        _isPanelOpen = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundImage: contact.avatar.isNotEmpty ? NetworkImage(contact.avatar) : null,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: contact.avatar.isEmpty ? const Icon(Icons.person, color: AppColors.primary, size: 36) : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          contact.name,
                          style: const TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Product Sans',
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.role,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontFamily: 'Product Sans',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (contact.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            contact.phone,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Product Sans',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (appState.isAdmin && contact.folder == 'customers') ...[
                    const Text(
                      "Assigned Staff Member",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Product Sans'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: contact.assignedStaffId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textMain, fontFamily: 'Product Sans', fontSize: 13),
                      dropdownColor: AppColors.surface,
                      items: staffMembers.map((staff) {
                        return DropdownMenuItem<String>(
                          value: staff.id,
                          child: Text(staff.name),
                        );
                      }).toList(),
                      onChanged: (newStaffId) async {
                        if (newStaffId != null) {
                          final success = await appState.moveCustomerToStaff(contact.id, newStaffId);
                          if (mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Reassigned customer to ${staffMembers.firstWhere((s) => s.id == newStaffId).name}")),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    "Assign to Folder",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Product Sans'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: appState.folders.where((f) => f.id != 'all').map((folder) {
                      final isSelected = contact.folder == folder.id;
                      final folderColor = _parseColor(folder.color);
                      return GestureDetector(
                        onTap: () async {
                          await appState.updateContactAssignments(contact.id, folder.id, contact.tags.map((t) => t.id).toList());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? folderColor.withValues(alpha: 0.12) : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? folderColor : AppColors.border,
                            ),
                          ),
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              color: isSelected ? AppColors.textMain : AppColors.textMuted,
                              fontSize: 11,
                              fontFamily: 'Product Sans',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
