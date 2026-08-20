import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';
import '../theme/colors.dart';
import '../widgets/animations.dart';
import '../widgets/titan_glass_panel.dart';
import '../widgets/gamify_animations.dart';

class Star {
  double angle;
  double radius;
  final double size;
  final double speed;
  final Color color;

  Star({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class GalaxyPainter extends CustomPainter {
  final List<Star> stars;
  final double rotationAngle;

  GalaxyPainter({required this.stars, required this.rotationAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.04),
          AppColors.electricBlue.withValues(alpha: 0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2.5));
    canvas.drawCircle(center, size.width / 2.5, nebulaPaint);

    for (var star in stars) {
      final double curAngle = star.angle + (rotationAngle * star.speed);
      final double dx = center.dx + cos(curAngle) * star.radius;
      final double dy = center.dy + sin(curAngle) * star.radius;
      
      paint.color = star.color.withValues(alpha: 0.3 + 0.5 * sin(curAngle * 2).abs());
      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MapNetworkPainter extends CustomPainter {
  final double progress;
  final double pulseGlow;
  final List contacts;

  MapNetworkPainter({
    required this.progress,
    required this.pulseGlow,
    required this.contacts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint corePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8 + (pulseGlow * 2), corePaint);
    
    final Paint pulsePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3 - (pulseGlow * 0.3))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 12 + (pulseGlow * 16), pulsePaint);

    final List staff = contacts.where((c) => c.folder == 'staff').toList();
    final List customers = contacts.where((c) => c.folder == 'customers').toList();

    final int staffCount = staff.length.clamp(3, 8);
    for (int i = 0; i < staffCount; i++) {
      final double angle = (i * 2 * pi / staffCount) + (progress * 2 * pi * 0.1);
      const double radius = 55.0;
      final Offset nodePos = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      
      final Paint linePaint = Paint()
        ..color = AppColors.electricBlue.withValues(alpha: 0.2)
        ..strokeWidth = 1.0;
      canvas.drawLine(center, nodePos, linePaint);

      final Paint nodePaint = Paint()
        ..color = AppColors.electricBlue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, 4, nodePaint);
      
      canvas.drawCircle(nodePos, 4 + (pulseGlow * 6), Paint()
        ..color = AppColors.electricBlue.withValues(alpha: 0.25 - (pulseGlow * 0.25))
        ..style = PaintingStyle.stroke);

      final double particleProgress = (progress + (i * 0.25)) % 1.0;
      final Offset particlePos = Offset(
        center.dx + cos(angle) * radius * particleProgress,
        center.dy + sin(angle) * radius * particleProgress,
      );
      canvas.drawCircle(particlePos, 2, Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill);
    }

    final int customerCount = customers.length.clamp(4, 10);
    for (int i = 0; i < customerCount; i++) {
      final double angle = (i * 2 * pi / customerCount) - (progress * 2 * pi * 0.05);
      const double radius = 80.0;
      final Offset nodePos = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      
      final Paint linePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..strokeWidth = 0.8;
      canvas.drawLine(center, nodePos, linePaint);

      canvas.drawCircle(nodePos, 3, Paint()
        ..color = AppColors.primary.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill);

      final double particleProgress = (progress + (i * 0.15)) % 1.0;
      final Offset particlePos = Offset(
        center.dx + cos(angle) * radius * particleProgress,
        center.dy + sin(angle) * radius * particleProgress,
      );
      canvas.drawCircle(particlePos, 1.5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CommandCenterScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const CommandCenterScreen({super.key, this.onTabChanged});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with TickerProviderStateMixin {
  late AnimationController _galaxyController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  
  final List<Star> _stars = [];
  final List<String> _telemetryLogs = [];
  final List<String> _allTelemetryMessages = [
    "INITIALIZING SECURE QUANTUM LINK...",
    "HANDSHAKE PROTOCOL STABLE ON PORT 5000",
    "EBI CORE LOADED: REASONING MODULE ON",
    "DB_TUNNEL: SECURE POSTGRESQL LINKED",
    "VAULT MEMORY STATUS: OK (12.4 GB FREE)",
    "ROTATING SECURITY KEYS... KEYROT_02 OK",
    "AI COMPANION SUB-ROUTINES: CALIBRATING",
    "DECRYPTING PRIVATE BROADCAST FEED...",
    "STAFF DIRECTORY DETECTED: 3 ACTIVE VAULTS",
    "COMMUNICATION ARENA: ROUTING CHANNELS",
    "VIP CHANNELS MONITORING ENABLED",
    "DIAGNOSTIC STATUS: ALL SYSTEMS OPERATIONAL"
  ];
  
  Timer? _logTimer;
  bool _isScanning = false;
  String _scanningStatus = "";

  // Interactive state for Staff and Customer dashboards
  final List<Map<String, dynamic>> _staffTasks = [
    {'title': 'Verify code build pipeline', 'done': true},
    {'title': 'Update design system documentation', 'done': false},
    {'title': 'Call Bob Smith (CFO) regarding contract', 'done': false},
    {'title': 'Prepare weekly operations briefing', 'done': false},
  ];

  final List<Map<String, dynamic>> _customerTickets = [
    {'id': 'TKT-9912', 'subject': 'API Integration issues on Sandbox', 'status': 'Open'},
    {'id': 'TKT-8902', 'subject': 'Request for test credentials reset', 'status': 'Closed'},
  ];

  final TextEditingController _aiController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  String _aiResponse = "Ask EBI AI anything (e.g. 'summarize projects', 'help').";

  @override
  void initState() {
    super.initState();

    _galaxyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    final random = Random();
    for (int i = 0; i < 60; i++) {
      _stars.add(Star(
        angle: random.nextDouble() * 2 * pi,
        radius: random.nextDouble() * 300 + 40,
        size: random.nextDouble() * 2.2 + 0.8,
        speed: random.nextDouble() * 0.15 + 0.05,
        color: random.nextBool() ? AppColors.primary : AppColors.electricBlue,
      ));
    }

    for (int i = 0; i < 5; i++) {
      _telemetryLogs.add(_allTelemetryMessages[i]);
    }

    _logTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          final nextMsg = _allTelemetryMessages[
              random.nextInt(_allTelemetryMessages.length)];
          _telemetryLogs.insert(0, nextMsg);
          if (_telemetryLogs.length > 20) {
            _telemetryLogs.removeLast();
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).ensureInitialDataLoaded();
    });
  }

  @override
  void dispose() {
    _galaxyController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _logTimer?.cancel();
    _aiController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _runDiagnosticScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanningStatus = "SWEEPING SECURE NODE CORE...";
    });
    
    await _scanController.forward(from: 0.0);
    
    if (mounted) {
      setState(() {
        _scanningStatus = "DECRYPTING LOGS & DATABASES...";
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    if (mounted) {
      setState(() {
        _scanningStatus = "EBI CORE: 100% HEALTHY & ENCRYPTED";
      });
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final profile = appState.userProfile ?? {
      'name': 'Marcus Sterling',
      'role': 'Executive VP | Global EB Tech',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80'
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _galaxyController,
              builder: (context, _) {
                return CustomPaint(
                  painter: GalaxyPainter(
                    stars: _stars,
                    rotationAngle: _galaxyController.value * 2 * pi,
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(profile),
                  
                  const SizedBox(height: 24),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return _buildRoleSpecificDashboard(appState, isWide);
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_isScanning)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                final topPos = MediaQuery.of(context).size.height * _scanController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: topPos,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary,
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: MediaQuery.of(context).size.height * (1.0 - _scanController.value),
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.04),
                              AppColors.primary.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.45,
                      left: 40,
                      right: 40,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, width: 1),
                          ),
                          child: Text(
                            _scanningStatus,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: (profile['avatar'] != null && (profile['avatar'] as String).isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      profile['avatar'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.person, color: AppColors.primary),
                        );
                      },
                    ),
                  )
                : const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "COMMANDER ${profile['name']?.toString().toUpperCase() ?? ''}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2.0,
                fontFamily: 'Product Sans',
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const PulsingDot(color: Colors.green, size: 6.0),
                const SizedBox(width: 6),
                Text(
                  "SECURE CONTEXT: ${profile['role']?.toString().toUpperCase() ?? ''}",
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _isScanning
            ? const ArcReactor(size: 36, color: AppColors.primary)
            : IconButton(
                icon: const Icon(Icons.security_rounded, color: AppColors.primary),
                tooltip: 'Run Diagnostic Scan',
                onPressed: _runDiagnosticScan,
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildIntelligenceCenterPanel(AppState appState) {
    final staffCount = appState.contacts.where((c) => c.folder == 'staff').length;
    final customerCount = appState.contacts.where((c) => c.folder == 'customers').length;
    final totalUnread = appState.contacts.fold(0, (sum, c) => sum + c.unreadCount);

    return NeonBorderPulse(
      color: AppColors.accentForRole(appState.currentProfile?.role ?? ''),
      borderRadius: 20,
      child: TitanGlassPanel(
      tier: GlassTier.epic,
      glowColor: AppColors.accentForRole(appState.currentProfile?.role ?? ''),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(Icons.dashboard_customize_rounded, "EXECUTIVE CORE"),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricWidget("STAFF", "$staffCount", AppColors.primary),
              Container(width: 1.5, height: 40, color: AppColors.border),
              _buildMetricWidget("CLIENTS", "$customerCount", AppColors.electricBlue),
              Container(width: 1.5, height: 40, color: AppColors.border),
              _buildMetricWidget("UNREAD", "$totalUnread", totalUnread > 0 ? AppColors.secondary : AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "SYSTEM UTILITIES",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildSystemActionButton("SECURE CHAT SPACE", Icons.chat_rounded, () {
            if (widget.onTabChanged != null) widget.onTabChanged!(1);
          }),
          const SizedBox(height: 8),
          _buildSystemActionButton("BROADCAST MATRIX", Icons.campaign_rounded, () {
            if (widget.onTabChanged != null) widget.onTabChanged!(2);
          }),
          const SizedBox(height: 8),
          _buildSystemActionButton("SYSTEM DIAGNOSTICS", Icons.compass_calibration_outlined, _runDiagnosticScan),
        ],
      ),
    ),
    );
  }

  Widget _buildActiveGalaxyMap(AppState appState) {
    return HologramScan(
      scanColor: AppColors.accentForRole(appState.currentProfile?.role ?? ''),
      child: TitanGlassPanel(
      tier: GlassTier.rare,
      glowColor: AppColors.accentForRole(appState.currentProfile?.role ?? ''),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(Icons.language_rounded, "RELATIONSHIP GALAXY"),
          const SizedBox(height: 16),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _galaxyController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: MapNetworkPainter(
                      progress: _galaxyController.value,
                      pulseGlow: _pulseController.value,
                      contacts: appState.contacts,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTelemetryStreamPanel() {
    return TitanGlassPanel(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(Icons.dns_rounded, "TELEMETRY LOGS MATRIX"),
          const SizedBox(height: 14),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: ListView.builder(
              reverse: false,
              padding: EdgeInsets.zero,
              itemCount: _telemetryLogs.length,
              itemBuilder: (context, index) {
                final isFirst = index == 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: isFirst
                      ? GlitchText(
                          text: _telemetryLogs[index],
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          intensity: 0.8,
                        )
                      : Text(
                          _telemetryLogs[index],
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPanelHeader(IconData icon, String title) {
    return TitanPanelHeader(icon: icon, title: title);
  }

  Widget _buildMetricWidget(String title, String val, Color glowColor) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: glowColor.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemActionButton(String label, IconData icon, VoidCallback onTap) {
    return TapScaleWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.deepSpaceBlack.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificDashboard(AppState appState, bool isWide) {
    if (appState.isCeo) {
      return Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildIntelligenceCenterPanel(appState)),
                const SizedBox(width: 16),
                Expanded(child: _buildActiveGalaxyMap(appState)),
              ],
            )
          else ...[
            _buildIntelligenceCenterPanel(appState),
            const SizedBox(height: 16),
            _buildActiveGalaxyMap(appState),
          ],
          const SizedBox(height: 16),
          _buildTelemetryStreamPanel(),
        ],
      );
    } else if (appState.isManager) {
      return _buildManagerDashboard(appState, isWide);
    } else if (appState.isStaffRole) {
      return _buildStaffDashboard(appState, isWide);
    } else {
      return _buildCustomerDashboard(appState, isWide);
    }
  }

  Widget _buildManagerDashboard(AppState appState, bool isWide) {
    final staffCount = appState.contacts.where((c) => c.folder == 'staff').length;
    final customerCount = appState.contacts.where((c) => c.folder == 'customers').length;
    final totalUnread = appState.contacts.fold(0, (sum, c) => sum + c.unreadCount);

    return Column(
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TitanGlassPanel(
                  glowColor: AppColors.managerBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPanelHeader(Icons.analytics_rounded, "TEAM ANALYTICS"),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricWidget("TEAM STAFF", "$staffCount", AppColors.primary),
                          Container(width: 1.5, height: 40, color: AppColors.border),
                          _buildMetricWidget("TEAM CLIENTS", "$customerCount", AppColors.electricBlue),
                          Container(width: 1.5, height: 40, color: AppColors.border),
                          _buildMetricWidget("UNREAD CHATS", "$totalUnread", totalUnread > 0 ? AppColors.secondary : AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildActiveGalaxyMap(appState)),
            ],
          )
        else ...[
          TitanGlassPanel(
            glowColor: AppColors.managerBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPanelHeader(Icons.analytics_rounded, "TEAM ANALYTICS"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricWidget("TEAM STAFF", "$staffCount", AppColors.primary),
                    Container(width: 1.5, height: 40, color: AppColors.border),
                    _buildMetricWidget("TEAM CLIENTS", "$customerCount", AppColors.electricBlue),
                    Container(width: 1.5, height: 40, color: AppColors.border),
                    _buildMetricWidget("UNREAD CHATS", "$totalUnread", totalUnread > 0 ? AppColors.secondary : AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          _buildActiveGalaxyMap(appState),
        ],
        const SizedBox(height: 16),
        // Customer Assignments Center
        TitanGlassPanel(
          glowColor: AppColors.managerBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.assignment_ind_rounded, "CUSTOMER ASSIGNMENTS"),
              const SizedBox(height: 14),
              const Text(
                "ASSIGN OR REASSIGN CUSTOMERS TO STAFF MEMBERS",
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              _buildManagerCustomerAssignmentsList(appState),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildManagerPerformancePanel(appState),
        const SizedBox(height: 16),
        _buildTelemetryStreamPanel(),
      ],
    );
  }

  Widget _buildManagerCustomerAssignmentsList(AppState appState) {
    final customers = appState.contacts.where((c) => c.folder == 'customers').toList();
    final staff = appState.contacts.where((c) => c.folder == 'staff').toList();

    if (customers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text("No customers available.", style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.deepSpaceBlack.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight, width: 0.5),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text("Phone: ${customer.phone}", style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
              const Spacer(),
              DropdownButton<String>(
                value: customer.assignedStaffId ?? '',
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Product Sans'),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text("Unassigned")),
                  ...staff.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name))),
                ],
                onChanged: (String? val) {
                  if (val != null) {
                    if (val.isEmpty) {
                      appState.removeCustomerFromStaff(customer.id);
                    } else {
                      appState.moveCustomerToStaff(customer.id, val);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Reassigned ${customer.name} successfully."),
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManagerPerformancePanel(AppState appState) {
    final staff = appState.contacts.where((c) => c.folder == 'staff').toList();
    return TitanGlassPanel(
      glowColor: AppColors.managerBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(Icons.speed_rounded, "TEAM PERFORMANCE MONITORING"),
          const SizedBox(height: 14),
          if (staff.isEmpty)
            const Center(child: Text("No team members active.", style: TextStyle(color: AppColors.textMuted)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staff.length,
              itemBuilder: (context, index) {
                final s = staff[index];
                // Simulated response latency based on name length
                final latency = (s.name.length * 1.3).toStringAsFixed(1);
                final isWarning = s.name.length > 12;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: isWarning ? Colors.amber : Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "$latency min avg delay",
                            style: TextStyle(
                              color: isWarning ? Colors.amber : Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStaffDashboard(AppState appState, bool isWide) {
    final customers = appState.contacts.where((c) => c.folder == 'customers').toList();
    final totalUnread = appState.contacts.fold(0, (sum, c) => sum + c.unreadCount);

    return Column(
      children: [
        TitanGlassPanel(
          glowColor: AppColors.staffTeal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.folder_shared_rounded, "STAFF PORTAL CORE"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricWidget("MY CLIENTS", "${customers.length}", AppColors.electricBlue),
                  Container(width: 1.5, height: 40, color: AppColors.border),
                  _buildMetricWidget("UNREAD ALERTS", "$totalUnread", totalUnread > 0 ? AppColors.secondary : AppColors.textMuted),
                  Container(width: 1.5, height: 40, color: AppColors.border),
                  _buildMetricWidget("VAULT SIZE", "1.2 GB / 10 GB", AppColors.primary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Interactive Checklist (Tasks)
        TitanGlassPanel(
          glowColor: AppColors.staffTeal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.checklist_rounded, "MY OPERATIONAL CHECKLIST"),
              const SizedBox(height: 14),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _staffTasks.length,
                itemBuilder: (context, index) {
                  final task = _staffTasks[index];
                  return CheckboxListTile(
                    value: task['done'] == true,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        color: task['done'] == true ? AppColors.textMuted : Colors.white,
                        decoration: task['done'] == true ? TextDecoration.lineThrough : null,
                        fontSize: 12.5,
                      ),
                    ),
                    onChanged: (bool? val) {
                      setState(() {
                        _staffTasks[index]['done'] = val == true;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Add operational task...",
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.deepSpaceBlack.withValues(alpha: 0.4),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final title = _taskController.text.trim();
                      if (title.isNotEmpty) {
                        setState(() {
                          _staffTasks.add({'title': title, 'done': false});
                          _taskController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("Add", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Calls & logs
        TitanGlassPanel(
          glowColor: AppColors.staffTeal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.phone_in_talk_rounded, "CALL ACTIVITY LOGS"),
              const SizedBox(height: 14),
              const Text("Recent secure call signals received:", style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildCallLogItem("Incoming Call from David Miller", "Connected • 04:12 mins", Colors.green),
              _buildCallLogItem("Outgoing Call to Diana Prince", "No Answer", Colors.redAccent),
              _buildCallLogItem("Incoming Call from Ethan Hunt", "Missed Call", Colors.amber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallLogItem(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.phone_callback_rounded, color: color, size: 14),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDashboard(AppState appState, bool isWide) {
    Contact? assignedStaff;
    final customerPhoneNorm = appState.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    Contact? customerContact;
    
    for (var c in appState.contacts) {
      if (c.folder == 'customers' && c.phone.replaceAll(RegExp(r'[^\d]'), '') == customerPhoneNorm) {
        customerContact = c;
        break;
      }
    }
    
    if (customerContact != null && customerContact.assignedStaffId != null) {
      for (var c in appState.contacts) {
        if (c.id == customerContact.assignedStaffId) {
          assignedStaff = c;
          break;
        }
      }
    }

    return Column(
      children: [
        // Assigned Specialist Card
        TitanGlassPanel(
          glowColor: AppColors.customerWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.contact_phone_rounded, "ASSIGNED SPECIALIST"),
              const SizedBox(height: 16),
              if (assignedStaff != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: assignedStaff.avatar.isNotEmpty ? NetworkImage(assignedStaff.avatar) : null,
                      child: assignedStaff.avatar.isEmpty ? const Icon(Icons.person, color: AppColors.primary) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(assignedStaff.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(assignedStaff.role, style: const TextStyle(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.forum_rounded, color: AppColors.primary),
                      onPressed: () {
                        if (widget.onTabChanged != null) widget.onTabChanged!(1);
                      },
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surface,
                      child: Icon(Icons.adb_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("EBI (AI Engine)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("GEBTALK Co-pilot", style: TextStyle(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.forum_rounded, color: AppColors.primary),
                      onPressed: () {
                        if (widget.onTabChanged != null) widget.onTabChanged!(1);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Support Tickets
        TitanGlassPanel(
          glowColor: AppColors.customerWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPanelHeader(Icons.confirmation_num_rounded, "SUPPORT TICKETS"),
                  ElevatedButton(
                    onPressed: () => _showCreateTicketDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text("New Ticket", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customerTickets.length,
                itemBuilder: (context, index) {
                  final ticket = _customerTickets[index];
                  final isOpen = ticket['status'] == 'Open';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ticket['subject'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text("ID: ${ticket['id']}", style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isOpen ? Colors.green : Colors.red, width: 0.5),
                          ),
                          child: Text(
                            ticket['status'],
                            style: TextStyle(color: isOpen ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Shared Documents
        TitanGlassPanel(
          glowColor: AppColors.customerWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.description_rounded, "SHARED DOCUMENTS VAULT"),
              const SizedBox(height: 12),
              _buildDocItem("aurora_pricing_proposal.pdf", "2.4 MB • PDF"),
              _buildDocItem("gebtalk_security_specs.pdf", "4.8 MB • PDF"),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quick AI box
        TitanGlassPanel(
          glowColor: AppColors.customerWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanelHeader(Icons.question_answer_rounded, "EBI AI COMPANION"),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.deepSpaceBlack.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                ),
                child: Text(_aiResponse, style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontFamily: 'Courier')),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _aiController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Type a query to EBI...",
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.deepSpaceBlack.withValues(alpha: 0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () {
                      final query = _aiController.text.trim().toLowerCase();
                      if (query.isNotEmpty) {
                        setState(() {
                          if (query.contains('summarize') || query.contains('project')) {
                            _aiResponse = "EBI: Here is your integration status:\n- Project Aurora: Phase 3 (75% completed)\n- Project Vortex: Phase 1 (33% completed)\n- Project Titan: Phase 4 (66% completed)";
                          } else if (query.contains('help')) {
                            _aiResponse = "EBI: I can help you summarize project status, draft contract requests, or download shared documents.";
                          } else {
                            _aiResponse = "EBI: Link securely established. Let me compile the analytics for '$query' now...";
                          }
                          _aiController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocItem(String name, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondary, size: 20),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        subtitle: Text(details, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 18),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Downloading $name... Done."),
                backgroundColor: AppColors.primaryDark,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context) {
    String subject = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Create Support Ticket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: "Enter subject...",
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            onChanged: (val) => subject = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (subject.isNotEmpty) {
                  setState(() {
                    final ticketId = "TKT-${Random().nextInt(9000) + 1000}";
                    _customerTickets.insert(0, {'id': ticketId, 'subject': subject, 'status': 'Open'});
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ticket submitted successfully."), backgroundColor: AppColors.primaryDark),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
