import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ═══════════════════════════════════════════════════════════════
//  1. XP GAIN POPUP — floating "+XP" text that rises and fades
// ═══════════════════════════════════════════════════════════════

class XPGainPopup extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onComplete;

  const XPGainPopup({
    super.key,
    this.text = '+25 XP',
    this.color = AppColors.neonRadioactive,
    this.onComplete,
  });

  @override
  State<XPGainPopup> createState() => _XPGainPopupState();
}

class _XPGainPopupState extends State<XPGainPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = t < 0.2 ? t * 5 : (1.0 - ((t - 0.2) / 0.8)).clamp(0.0, 1.0);
        final yOffset = -80 * Curves.easeOutCubic.transform(t);
        final scale = t < 0.15 ? 0.5 + (t / 0.15) * 0.7 : 1.2 - (t - 0.15) * 0.25;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scale.clamp(0.5, 1.3),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Product Sans',
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: widget.color.withValues(alpha: 0.8), blurRadius: 12),
                    Shadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  2. LEVEL UP BURST — full-screen particle + shockwave explosion
// ═══════════════════════════════════════════════════════════════

class LevelUpBurst extends StatefulWidget {
  final Color color;
  final VoidCallback? onComplete;

  const LevelUpBurst({
    super.key,
    this.color = AppColors.tierGold,
    this.onComplete,
  });

  @override
  State<LevelUpBurst> createState() => _LevelUpBurstState();
}

class _LevelUpBurstState extends State<LevelUpBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_BurstPart> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(50, (i) {
      final angle = _rng.nextDouble() * 2 * pi;
      return _BurstPart(
        angle: angle,
        speed: _rng.nextDouble() * 300 + 100,
        size: _rng.nextDouble() * 4 + 1.5,
        color: Color.lerp(widget.color, Colors.white, _rng.nextDouble() * 0.6)!,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _LevelUpPainter(
            particles: _particles,
            progress: _controller.value,
            baseColor: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BurstPart {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  _BurstPart({
    required this.angle, required this.speed,
    required this.size, required this.color,
    required this.rotationSpeed,
  });
}

class _LevelUpPainter extends CustomPainter {
  final List<_BurstPart> particles;
  final double progress;
  final Color baseColor;

  _LevelUpPainter({required this.particles, required this.progress, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Shockwave ring
    if (progress < 0.6) {
      final ringProgress = Curves.easeOutCubic.transform((progress / 0.6).clamp(0.0, 1.0));
      final ringRadius = size.width * 0.5 * ringProgress;
      final ringAlpha = (1.0 - ringProgress) * 0.5;
      canvas.drawCircle(
        center, ringRadius,
        Paint()
          ..color = baseColor.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1.0 - ringProgress),
      );
      // Inner glow
      canvas.drawCircle(
        center, ringRadius * 0.7,
        Paint()
          ..color = baseColor.withValues(alpha: ringAlpha * 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // Particles
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      final decel = Curves.easeOutQuart.transform(progress);
      final dist = p.speed * decel;
      final alpha = (1.0 - Curves.easeInCubic.transform(progress)).clamp(0.0, 1.0);
      final dx = center.dx + cos(p.angle) * dist;
      final dy = center.dy + sin(p.angle) * dist;

      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), p.size * (1.0 - progress * 0.4), paint);

      // Trailing glow
      if (alpha > 0.2) {
        paint.color = p.color.withValues(alpha: alpha * 0.15);
        canvas.drawCircle(Offset(dx, dy), p.size * 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
//  3. NEON BORDER PULSE — breathing neon border around widget
// ═══════════════════════════════════════════════════════════════

class NeonBorderPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final double intensity;

  const NeonBorderPulse({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.borderRadius = 16,
    this.intensity = 1.0,
  });

  @override
  State<NeonBorderPulse> createState() => _NeonBorderPulseState();
}

class _NeonBorderPulseState extends State<NeonBorderPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = Curves.easeInOutSine.transform(_controller.value);
        final borderAlpha = (0.15 + pulse * 0.35) * widget.intensity;
        final shadowAlpha = (0.05 + pulse * 0.12) * widget.intensity;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.color.withValues(alpha: borderAlpha.clamp(0.0, 1.0)),
              width: 1.0 + pulse * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: shadowAlpha.clamp(0.0, 1.0)),
                blurRadius: 12 + pulse * 12,
                spreadRadius: -2 + pulse * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  4. GLITCH TEXT — cyberpunk RGB channel split text
// ═══════════════════════════════════════════════════════════════

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final double intensity;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 3000),
    this.intensity = 1.0,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle(
      color: AppColors.primary,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: 'Product Sans',
      letterSpacing: 1.5,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Glitch bursts happen only 15% of the time for realism
        final t = _controller.value;
        final glitchPhase = sin(t * 2 * pi * 7);
        final isGlitching = glitchPhase.abs() > 0.85;

        final redShift = isGlitching ? (_rng.nextDouble() - 0.5) * 3.0 * widget.intensity : 0.0;
        final blueShift = isGlitching ? (_rng.nextDouble() - 0.5) * 3.0 * widget.intensity : 0.0;

        return Stack(
          children: [
            // Red channel
            if (isGlitching)
              Transform.translate(
                offset: Offset(redShift, 0),
                child: Text(
                  widget.text,
                  style: baseStyle.copyWith(
                    color: Colors.red.withValues(alpha: 0.4),
                  ),
                ),
              ),
            // Blue channel
            if (isGlitching)
              Transform.translate(
                offset: Offset(blueShift, 0),
                child: Text(
                  widget.text,
                  style: baseStyle.copyWith(
                    color: Colors.blue.withValues(alpha: 0.4),
                  ),
                ),
              ),
            // Main text
            Text(widget.text, style: baseStyle),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  5. HOLOGRAM SCAN — scanning line that sweeps over cards
// ═══════════════════════════════════════════════════════════════

class HologramScan extends StatefulWidget {
  final Widget child;
  final Color scanColor;
  final Duration duration;

  const HologramScan({
    super.key,
    required this.child,
    this.scanColor = AppColors.primary,
    this.duration = const Duration(milliseconds: 3500),
  });

  @override
  State<HologramScan> createState() => _HologramScanState();
}

class _HologramScanState extends State<HologramScan>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Stack(
            children: [
              child!,
              // Scan line
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ScanLinePainter(
                      progress: _controller.value,
                      color: widget.scanColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Scan line
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y),
        Offset(size.width, y),
        [
          Colors.transparent,
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.6),
          Colors.transparent,
        ],
        [0.0, 0.2, 0.8, 1.0],
      )
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // Glow area above the line
    final glowRect = Rect.fromLTWH(0, y - 30, size.width, 30);
    final glowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y - 30),
        Offset(0, y),
        [Colors.transparent, color.withValues(alpha: 0.06)],
      );
    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
//  6. ARC REACTOR — Iron Man-style spinning loader
// ═══════════════════════════════════════════════════════════════

class ArcReactor extends StatefulWidget {
  final double size;
  final Color color;

  const ArcReactor({
    super.key,
    this.size = 48,
    this.color = AppColors.primary,
  });

  @override
  State<ArcReactor> createState() => _ArcReactorState();
}

class _ArcReactorState extends State<ArcReactor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ArcReactorPainter(
              rotation: _controller.value * 2 * pi,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _ArcReactorPainter extends CustomPainter {
  final double rotation;
  final Color color;
  _ArcReactorPainter({required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Core glow
    canvas.drawCircle(
      center, r * 0.2,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, r * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Inner ring
    canvas.drawCircle(
      center, r * 0.4,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Outer spinning arcs (3 segments)
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final startAngle = rotation + (i * 2 * pi / 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.75),
        startAngle, pi * 0.45, false, arcPaint,
      );
    }

    // Counter-rotating outer ring (6 dots)
    final dotPaint = Paint()..color = color.withValues(alpha: 0.6);
    for (int i = 0; i < 6; i++) {
      final angle = -rotation * 0.7 + (i * pi / 3);
      final dx = center.dx + cos(angle) * r * 0.9;
      final dy = center.dy + sin(angle) * r * 0.9;
      canvas.drawCircle(Offset(dx, dy), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
//  7. MATRIX RAIN — digital code rain columns
// ═══════════════════════════════════════════════════════════════

class MatrixRain extends StatefulWidget {
  final int columnCount;
  final Color color;
  final double opacity;

  const MatrixRain({
    super.key,
    this.columnCount = 25,
    this.color = AppColors.primary,
    this.opacity = 0.15,
  });

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<MatrixRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_RainColumn> _columns;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _columns = List.generate(widget.columnCount, (i) {
      return _RainColumn(
        x: i / widget.columnCount,
        speed: _rng.nextDouble() * 0.3 + 0.1,
        length: _rng.nextInt(8) + 4,
        offset: _rng.nextDouble(),
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Update column positions
          for (var col in _columns) {
            col.offset += col.speed * 0.008;
            if (col.offset > 1.5) col.offset = -0.5;
          }
          return CustomPaint(
            painter: _MatrixRainPainter(
              columns: _columns,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _RainColumn {
  final double x;
  final double speed;
  final int length;
  double offset;
  _RainColumn({required this.x, required this.speed, required this.length, required this.offset});
}

class _MatrixRainPainter extends CustomPainter {
  final List<_RainColumn> columns;
  final Color color;
  _MatrixRainPainter({required this.columns, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final charSize = size.width / columns.length * 0.5;

    for (var col in columns) {
      final x = col.x * size.width;
      for (int i = 0; i < col.length; i++) {
        final y = (col.offset + i * 0.03) * size.height;
        if (y < 0 || y > size.height) continue;

        final fade = 1.0 - (i / col.length);
        final alpha = (fade * 0.8).clamp(0.0, 1.0);
        paint.color = i == 0
            ? Colors.white.withValues(alpha: alpha * 0.9)
            : color.withValues(alpha: alpha);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: charSize * 0.6, height: charSize * 0.3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
//  8. PLASMA ORB — pulsing plasma sphere for avatar backgrounds
// ═══════════════════════════════════════════════════════════════

class PlasmaOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Widget? child;

  const PlasmaOrb({
    super.key,
    this.size = 80,
    this.color = AppColors.primary,
    this.child,
  });

  @override
  State<PlasmaOrb> createState() => _PlasmaOrbState();
}

class _PlasmaOrbState extends State<PlasmaOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = Curves.easeInOutSine.transform(_controller.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + pulse * 0.15),
                blurRadius: 20 + pulse * 16,
                spreadRadius: 2 + pulse * 4,
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: 0.08 + pulse * 0.08),
                blurRadius: 40 + pulse * 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.2 + pulse * 0.1),
                  widget.color.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.3 + pulse * 0.2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        );
      },
      child: Center(child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  9. CYBER GRID — animated Tron-style perspective grid floor
// ═══════════════════════════════════════════════════════════════

class CyberGrid extends StatefulWidget {
  final Color color;
  final double opacity;

  const CyberGrid({
    super.key,
    this.color = AppColors.primary,
    this.opacity = 0.08,
  });

  @override
  State<CyberGrid> createState() => _CyberGridState();
}

class _CyberGridState extends State<CyberGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CyberGridPainter(
              progress: _controller.value,
              color: widget.color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CyberGridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final horizonY = size.height * 0.5;

    // Vertical lines (perspective)
    const lineCount = 16;
    for (int i = 0; i <= lineCount; i++) {
      final t = i / lineCount;
      final topX = size.width * t;
      final bottomX = size.width * (0.1 + t * 0.8);
      paint.color = color.withValues(alpha: (1.0 - (t - 0.5).abs() * 2).clamp(0.1, 0.6));
      canvas.drawLine(Offset(topX, horizonY), Offset(bottomX, size.height), paint);
    }

    // Horizontal lines (scrolling forward)
    const hLines = 12;
    for (int i = 0; i < hLines; i++) {
      final baseT = i / hLines;
      final animT = (baseT + progress) % 1.0;
      final y = horizonY + (size.height - horizonY) * animT * animT;
      final squeeze = 1.0 - animT * 0.6;
      final xStart = size.width * (0.5 - squeeze * 0.5);
      final xEnd = size.width * (0.5 + squeeze * 0.5);
      paint.color = color.withValues(alpha: (animT * 0.6).clamp(0.0, 0.5));
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
