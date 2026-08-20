import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Rarity tier enum for gamified glass panels
enum GlassTier { common, rare, epic, legendary }

/// The signature GEBTALK Energy Panel — now with hover glow, edge light
/// sweep, corner accent dots, and rarity tiers.
/// 
/// Features:
/// - Multi-layer glassmorphism with frosted backdrop
/// - Animated border glow that pulses subtly
/// - Mouse hover glow intensification (web/desktop)
/// - Edge light sweep on first appearance
/// - Corner accent dots (HUD targeting reticle)
/// - Rarity tiers: common, rare, epic, legendary
/// - Tap-reactive depth effect
/// - Configurable glow color per role
class TitanGlassPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color glowColor;
  final double glowIntensity;
  final double borderRadius;
  final double blurSigma;
  final bool animate;
  final VoidCallback? onTap;
  final GlassTier tier;

  const TitanGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.glowColor = AppColors.primary,
    this.glowIntensity = 0.12,
    this.borderRadius = 20,
    this.blurSigma = 12,
    this.animate = true,
    this.onTap,
    this.tier = GlassTier.common,
  });

  @override
  State<TitanGlassPanel> createState() => _TitanGlassPanelState();
}

class _TitanGlassPanelState extends State<TitanGlassPanel>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _sweepController;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _tierPulseDuration()),
    );
    if (widget.animate) {
      _glowController.repeat(reverse: true);
    }

    // Edge light sweep — plays once on mount
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _sweepController.forward();
    });
  }

  int _tierPulseDuration() {
    switch (widget.tier) {
      case GlassTier.legendary: return 1800;
      case GlassTier.epic: return 2200;
      case GlassTier.rare: return 2600;
      case GlassTier.common: return 3000;
    }
  }

  double _tierBorderWidth() {
    switch (widget.tier) {
      case GlassTier.legendary: return 1.5;
      case GlassTier.epic: return 1.3;
      case GlassTier.rare: return 1.1;
      case GlassTier.common: return 1.0;
    }
  }

  double _tierGlowMult() {
    switch (widget.tier) {
      case GlassTier.legendary: return 2.5;
      case GlassTier.epic: return 1.8;
      case GlassTier.rare: return 1.3;
      case GlassTier.common: return 1.0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowController, _sweepController]),
        builder: (context, child) {
          final glowValue = widget.animate ? _glowController.value : 0.5;
          final tierMult = _tierGlowMult();
          final hoverBoost = _isHovered ? 0.15 : 0.0;
          final borderAlpha = ((widget.glowIntensity + glowValue * 0.08 + hoverBoost) * tierMult).clamp(0.0, 1.0);
          final scale = _isPressed ? 0.98 : (_isHovered ? 1.005 : 1.0);
          final sweepVal = _sweepController.value;

          return GestureDetector(
            onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: widget.onTap != null ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            } : null,
            onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.glowColor.withValues(alpha: borderAlpha),
                    width: _tierBorderWidth(),
                  ),
                  boxShadow: [
                    // Outer shadow for depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    // Colored glow
                    BoxShadow(
                      color: widget.glowColor.withValues(
                        alpha: ((0.04 + glowValue * 0.03 + hoverBoost * 0.5) * tierMult).clamp(0.0, 1.0),
                      ),
                      blurRadius: 24 + hoverBoost * 30,
                      spreadRadius: -4 + hoverBoost * 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.surface.withValues(alpha: 0.45),
                            AppColors.surface.withValues(alpha: 0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Inner light reflection at top-left
                          Positioned(
                            top: -30,
                            left: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.04 + hoverBoost * 0.04),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Edge light sweep
                          if (sweepVal > 0 && sweepVal < 1.0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _EdgeSweepPainter(
                                    progress: sweepVal,
                                    color: widget.glowColor,
                                    borderRadius: widget.borderRadius,
                                  ),
                                ),
                              ),
                            ),
                          // Corner accent dots (HUD reticle)
                          if (widget.tier != GlassTier.common)
                            ..._buildCornerDots(glowValue),
                          // Content
                          Padding(
                            padding: widget.padding,
                            child: widget.child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerDots(double glowValue) {
    final dotAlpha = (0.3 + glowValue * 0.4).clamp(0.0, 1.0);
    final dotSize = widget.tier == GlassTier.legendary ? 4.0 : 3.0;
    final color = widget.glowColor.withValues(alpha: dotAlpha);
    const inset = 8.0;

    return [
      Positioned(top: inset, left: inset, child: _cornerDot(color, dotSize)),
      Positioned(top: inset, right: inset, child: _cornerDot(color, dotSize)),
      Positioned(bottom: inset, left: inset, child: _cornerDot(color, dotSize)),
      Positioned(bottom: inset, right: inset, child: _cornerDot(color, dotSize)),
    ];
  }

  Widget _cornerDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Edge light sweep painter — a bright streak that traces the border once
class _EdgeSweepPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  _EdgeSweepPainter({required this.progress, required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a path along the rounded rectangle border
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final perimeter = 2 * (size.width + size.height);
    final sweepLength = perimeter * 0.15; // 15% of perimeter
    final sweepStart = perimeter * progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Sample points along the rectangle perimeter
    final points = <Offset>[];
    const steps = 120;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps * perimeter;
      points.add(_pointOnRect(rect, t, size));
    }

    for (int i = 0; i < points.length - 1; i++) {
      final t = i / steps * perimeter;
      final dist = (t - sweepStart + perimeter) % perimeter;
      if (dist < sweepLength) {
        final localT = dist / sweepLength;
        final alpha = (sin(localT * pi) * 0.6).clamp(0.0, 1.0);
        paint.color = color.withValues(alpha: alpha);
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  Offset _pointOnRect(Rect rect, double t, Size size) {
    final w = size.width;
    final h = size.height;
    final perim = 2 * (w + h);
    final norm = t % perim;

    if (norm < w) return Offset(norm, 0);
    if (norm < w + h) return Offset(w, norm - w);
    if (norm < 2 * w + h) return Offset(w - (norm - w - h), h);
    return Offset(0, h - (norm - 2 * w - h));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


/// A simplified glass container without animation overhead — for inline use
class TitanGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;

  const TitanGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorderSubtle,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
