import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../screens/auth_screen.dart';

class EbiBot extends StatefulWidget {
  final String screen;
  final Function(int)? onTabChanged;

  const EbiBot({
    Key? key,
    this.screen = 'chat_list',
    this.onTabChanged,
  }) : super(key: key);

  @override
  State<EbiBot> createState() => _EbiBotState();
}

class _EbiBotState extends State<EbiBot> with TickerProviderStateMixin {
  // Use right & bottom positioning to ensure EBI stays inside the constrained viewport
  double _right = 20.0;
  double _bottom = 100.0;
  bool _isBubbleVisible = false;
  bool _isDragging = false;
  Offset _dragStartPos = Offset.zero;
  static const double _dragThreshold = 10.0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _bounceController;

  // Mascot states
  bool _isBlinking = false;
  bool _isWaving = false;
  bool _showSuccessBadge = false;

  Timer? _blinkTimer;
  Timer? _waveTimer;

  // Contextual tips dictionary
  final Map<String, List<String>> _tips = {
    'auth': [
      "Welcome to GEBTALK! Please enter your phone number to authenticate.",
      "Any 4-digit code works in our simulated secure sandbox mode.",
      "Need immediate assistance? Tap 'Contact Support' below."
    ],
    'chat_list': [
      "Tap any contact conversation to view their details or chat history.",
      "Filter conversations using the folders (Staff, Customer) and tag filters at the top.",
      "Tap 'Create Broadcast' to send announcements to multiple clients simultaneously."
    ],
    'chat_detail': [
      "Long-press any message bubble to react with emojis (👍, ❤️, 😮, etc.).",
      "Tap the (i) info icon in the header to assign contacts to folders or tags.",
      "You can send simulated voice notes and document attachments below."
    ],
    'broadcast': [
      "Select multiple recipients from the contacts list to broadcast.",
      "Broadcast messages appear as private personal messages in their chat histories.",
      "Ensure all required partners are selected before composing your blast."
    ],
    'settings': [
      "Verify your secure identity and change theme accents here.",
      "Tap 'Log Out' to sign out and return to the secure gateway.",
      "Need help managing custom organizational tags? Ask support."
    ],
  };

  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();

    // Pulse animation for glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Wave animation (slight rotation)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Bounce animation for success gestures
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Start periodic blinking timer
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _isBlinking = true;
        });
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _isBlinking = false;
            });
          }
        });
      }
    });

    // Start periodic waving timer
    _waveTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted && !_isDragging && !_isBubbleVisible) {
        _triggerWaving();
      }
    });

    // Initial greeting
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _triggerWaving();
      }
    });
  }

  void _triggerWaving() {
    setState(() {
      _isWaving = true;
    });
    _waveController.forward().then((_) {
      _waveController.reverse().then((_) {
        _waveController.forward().then((_) {
          _waveController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _isWaving = false;
              });
            }
          });
        });
      });
    });
  }

  void _triggerSuccess() {
    setState(() {
      _showSuccessBadge = true;
    });
    _bounceController.forward().then((_) {
      _bounceController.reverse().then((_) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _showSuccessBadge = false;
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _waveTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // Helper to get active tips list
  List<String> get _activeTips => _tips[widget.screen] ?? _tips['chat_list']!;

  // Actions implementation
  void _executeAction(String actionName) {
    _triggerSuccess();
    
    // Auto-minimize after click
    setState(() {
      _isBubbleVisible = false;
    });

    final appState = Provider.of<AppState>(context, listen: false);

    switch (actionName) {
      case 'start_chat':
        appState.setSearchQuery('');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("EBI: Tap a contact from the list below to begin a secure chat."),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 3),
          ),
        );
        break;
      case 'search_contacts':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("EBI: Tap the search bar at the top and type name/role to filter contacts."),
            backgroundColor: Colors.blueAccent,
          ),
        );
        break;
      case 'create_broadcast':
        if (widget.onTabChanged != null) {
          widget.onTabChanged!(1); // Switch to Broadcast tab
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("EBI: Go back to Chat list, then tap 'Broadcast' tab.")),
          );
        }
        break;
      case 'manage_folders':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("EBI: Use folders (Staff, Customers, Support) above the list to organize work."),
            backgroundColor: Colors.blueAccent,
          ),
        );
        break;
      case 'view_notifications':
        _showNotificationsDialog();
        break;
      case 'contact_support':
        _showSupportDialog();
        break;
      case 'what_is_gebtalk':
        _showInfoDialog(
          "About GEBTALK",
          "GEBTALK is a secure, premium business communication portal designed for EB GLOBAL.\n\n"
          "It integrates client management, two-level navigation folders, tag assignments, "
          "quick emoji reactions, voice messaging, document attachments, and multi-recipient broadcasts."
        );
        break;
      case 'how_to_login':
        _showInfoDialog(
          "How to Authenticate",
          "1. Enter your phone number starting with your country code.\n"
          "2. Tap 'Authenticate' to request a verification code.\n"
          "3. Enter any 4-digit code. In mock mode, any code completes the secure login successfully!"
        );
        break;
      case 'assign_folder_tag':
        _showInfoDialog(
          "Categorizing Contacts",
          "To keep your list neat:\n\n"
          "1. In the chat room, tap the info (i) icon at the top right.\n"
          "2. Select a target folder (Staff, Customer, etc.) or check custom tags (VIP, Alumni, Urgent).\n"
          "3. Tap 'Save' to apply changes instantly."
        );
        break;
      case 'add_emoji':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("EBI: Long-press any message bubble to choose an emoji reaction."),
            backgroundColor: Colors.blueAccent,
          ),
        );
        break;
      case 'back_to_chats':
        if (widget.onTabChanged != null) {
          widget.onTabChanged!(0); // Switch to Chat list tab
        } else {
          Navigator.maybePop(context);
        }
        break;
      case 'logout':
        appState.logout();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        break;
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text("Workspace Updates", style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationRow("Sarah Jenkins is active now", "Just now"),
            const Divider(color: AppColors.borderLight),
            _buildNotificationRow("2 unread messages in Support Desk", "5m ago"),
            const Divider(color: AppColors.borderLight),
            _buildNotificationRow("Backup system running database.db", "Online"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationRow(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.textMain, fontSize: 13))),
          Text(time, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Contact EBI Support", style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          "For technical help or portal configurations:\n\n"
          "✉ Email: tech-support@ebglobal.com\n"
          "☏ Phone: +1 (800) 555-0199\n\n"
          "EBI Helpdesk is available 24/7.",
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(body, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Understood", style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
    );
  }

  // Get quick actions list based on current screen
  List<Map<String, dynamic>> _getQuickActions() {
    if (widget.screen == 'auth') {
      return [
        {'id': 'how_to_login', 'label': 'How to log in', 'icon': Icons.help_outline},
        {'id': 'what_is_gebtalk', 'label': 'What is GEBTALK?', 'icon': Icons.info_outline},
        {'id': 'contact_support', 'label': 'Contact Support', 'icon': Icons.contact_support_outlined},
      ];
    } else if (widget.screen == 'chat_detail') {
      return [
        {'id': 'add_emoji', 'label': 'Add emoji reaction', 'icon': Icons.sentiment_satisfied_alt},
        {'id': 'assign_folder_tag', 'label': 'Assign Folder/Tag', 'icon': Icons.folder_open},
        {'id': 'back_to_chats', 'label': 'Back to Chat list', 'icon': Icons.arrow_back},
      ];
    } else if (widget.screen == 'broadcast') {
      return [
        {'id': 'what_is_gebtalk', 'label': 'What is Broadcast?', 'icon': Icons.campaign_outlined},
        {'id': 'back_to_chats', 'label': 'Back to Chat list', 'icon': Icons.chat_bubble_outline},
      ];
    } else if (widget.screen == 'settings') {
      return [
        {'id': 'logout', 'label': 'Sign Out', 'icon': Icons.logout},
        {'id': 'back_to_chats', 'label': 'Back to Chat list', 'icon': Icons.chat_bubble_outline},
      ];
    } else {
      // Default: chat_list
      return [
        {'id': 'start_chat', 'label': 'Start a new chat', 'icon': Icons.chat},
        {'id': 'search_contacts', 'label': 'Search contacts', 'icon': Icons.search},
        {'id': 'create_broadcast', 'label': 'Create broadcast', 'icon': Icons.campaign},
        {'id': 'manage_folders', 'label': 'Manage folders', 'icon': Icons.folder},
        {'id': 'view_notifications', 'label': 'View notifications', 'icon': Icons.notifications},
        {'id': 'contact_support', 'label': 'Contact Support', 'icon': Icons.contact_support},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final quickActions = _getQuickActions();

    return Stack(
      children: [
        // Bubble Guidance Overlay
        if (_isBubbleVisible)
          Positioned(
            right: _right,
            bottom: _bottom + 60.0, // Floating exactly above EBI mascot
            child: Container(
              width: 250.0,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95), // Semi-translucent glass light
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 15.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bubble Header
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.primary, size: 18.0),
                      const SizedBox(width: 6.0),
                      const Text(
                        "EBI CO-PILOT",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      // Context Active Pulse
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isBubbleVisible = false),
                        child: const Icon(Icons.close, color: AppColors.textMuted, size: 14.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Guidance Message
                  Text(
                    _activeTips[_tipIndex % _activeTips.length],
                    style: const TextStyle(color: AppColors.textMain, fontSize: 12.5, height: 1.45),
                  ),
                  const SizedBox(height: 10.0),

                  // Tips Cycle Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tip ${_tipIndex % _activeTips.length + 1} of ${_activeTips.length}",
                        style: const TextStyle(color: AppColors.textLight, fontSize: 9.5),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _tipIndex++;
                          });
                        },
                        child: const Row(
                          children: [
                            Text("Next Tip", style: TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_forward, color: AppColors.primary, size: 12.0),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: const Divider(color: AppColors.borderLight, height: 1.0),
                  ),

                  // Quick Actions Title
                  const Text(
                    "QUICK ACTIONS",
                    style: TextStyle(color: AppColors.textLight, fontSize: 9.0, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6.0),

                  // Grid of Quick Actions
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: quickActions.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, idx) {
                          final action = quickActions[idx];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _executeAction(action['id'] as String),
                              borderRadius: BorderRadius.circular(8.0),
                              splashColor: AppColors.primary.withOpacity(0.15),
                              highlightColor: AppColors.primary.withOpacity(0.08),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4.0),
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.08)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(action['icon'] as IconData, color: AppColors.primary, size: 16.0),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: Text(
                                        action['label'] as String,
                                        style: const TextStyle(color: AppColors.textMain, fontSize: 12.0),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: AppColors.textLight, size: 14.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Draggable Mascot Avatar positioned using right/bottom constraints
        Positioned(
          right: _right,
          bottom: _bottom,
          child: GestureDetector(
            onTap: () {
              _triggerWaving();
              setState(() {
                _isBubbleVisible = !_isBubbleVisible;
                if (_isBubbleVisible) _tipIndex = 0;
              });
            },
            onPanStart: (details) {
              _isDragging = false;
              _dragStartPos = details.globalPosition;
            },
            onPanUpdate: (details) {
              final distance = (details.globalPosition - _dragStartPos).distance;
              if (distance > _dragThreshold) {
                _isDragging = true;
              }
              if (_isDragging) {
                setState(() {
                  _right -= details.delta.dx;
                  _bottom -= details.delta.dy;
                  _right = _right.clamp(10.0, size.width - 70.0);
                  _bottom = _bottom.clamp(20.0, size.height - 250.0);
                });
              }
            },
            onPanEnd: (_) {
              _isDragging = false;
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  // Waving rotates slightly
                  double rotation = 0.0;
                  if (_isWaving) {
                    rotation = sin(_waveController.value * pi * 2) * 0.15;
                  }

                  return Transform.rotate(
                    angle: rotation,
                    child: AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        // Bounce translation for success
                        double bounceY = 0.0;
                        if (_bounceController.isAnimating) {
                          bounceY = -sin(_bounceController.value * pi) * 20.0;
                        }

                        return Transform.translate(
                          offset: Offset(0, bounceY),
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Pulse Glow Ring
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              double pulseVal = _pulseController.value;
                              return Transform.scale(
                                scale: 1.0 + (pulseVal * 0.05), // Breathing effect
                                child: Container(
                                  width: 56.0 + (pulseVal * 12.0),
                                  height: 56.0 + (pulseVal * 12.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.2 - (pulseVal * 0.15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.electricBlue.withValues(alpha: 0.4 * pulseVal),
                                        blurRadius: 20 * pulseVal,
                                        spreadRadius: 5 * pulseVal,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Main Avatar Container
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.03), // Subtle breathing core
                                child: Container(
                                  width: 50.0,
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.electricBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        blurRadius: 12.0,
                                        spreadRadius: 2.0,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 10.0,
                                        spreadRadius: 1.0,
                                      ),
                                    ],
                              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                            ),
                            child: Center(
                              // EBI Custom Animated Mascot Face
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Robot Face Frame
                                  Container(
                                    width: 38.0,
                                    height: 38.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surface,
                                      border: Border.all(color: AppColors.border),
                                    ),
                                  ),

                                  // Glowing Blue Digital Screen Head
                                  Container(
                                    width: 32.0,
                                    height: 32.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.background,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      // Glowing LED Eyes
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildEye(),
                                          const SizedBox(width: 4),
                                          _buildEye(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                          // Celebratory Thumbs-Up / Success Badge
                          if (_showSuccessBadge)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green,
                                      blurRadius: 8.0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.thumb_up,
                                  color: AppColors.background,
                                  size: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Custom Animated Eye
  Widget _buildEye() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 6.0,
      height: _isBlinking ? 1.0 : 6.0, // Flattens to horizontal slit when blinking
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(3.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primary,
            blurRadius: 4.0,
          ),
        ],
      ),
    );
  }
}
