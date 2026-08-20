import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'titan_particles.dart';
import 'gamify_animations.dart';

/// Living background system for every screen — now with breathing orbs,
/// hex grid overlay, matrix rain, and cyberpunk preset.
/// 
/// Presets:
/// - `command`: Galaxy nebula with particles + hex grid
/// - `arena`: Energy field with faster particles + connections
/// - `lounge`: Warm elegant drift with gold particles
/// - `void`: Deep black with minimal particles
/// - `auth`: Dramatic, cinematic with matrix rain
/// - `cyberpunk`: Electric pink/cyan with digital rain + cyber grid
class TitanBackground extends StatelessWidget {
  final String preset;
  final Widget child;
  final int particleCount;

  const TitanBackground({
    super.key,
    this.preset = 'void',
    required this.child,
    this.particleCount = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base color
        Positioned.fill(
          child: Container(color: AppColors.background),
        ),
        
        // Animated breathing nebula orbs based on preset
        ..._buildNebulaOrbs(),
        
        // Cyber grid floor for cyberpunk preset
        if (preset == 'cyberpunk')
          const Positioned.fill(
            child: CyberGrid(color: AppColors.neonMagenta, opacity: 0.06),
          ),
        
        // Hex grid overlay for command preset
        if (preset == 'command' || preset == 'cyberpunk')
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HexGridPainter(
                  color: preset == 'cyberpunk'
                      ? AppColors.neonMagenta.withValues(alpha: 0.03)
                      : AppColors.primary.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),

        // Matrix rain for auth and cyberpunk
        if (preset == 'auth' || preset == 'cyberpunk')
          Positioned.fill(
            child: MatrixRain(
              columnCount: preset == 'cyberpunk' ? 30 : 20,
              color: preset == 'cyberpunk' ? AppColors.neonMagenta : AppColors.primary,
              opacity: preset == 'cyberpunk' ? 0.12 : 0.08,
            ),
          ),
        
        // Particle field
        Positioned.fill(
          child: TitanParticleField(
            preset: _particlePreset(),
            particleCount: particleCount,
            opacity: _particleOpacity(),
          ),
        ),
        
        // Content
        Positioned.fill(child: child),
      ],
    );
  }

  String _particlePreset() {
    switch (preset) {
      case 'command': return 'command';
      case 'arena': return 'arena';
      case 'lounge': return 'lounge';
      case 'auth': return 'command';
      case 'cyberpunk': return 'cyberpunk';
      default: return 'subtle';
    }
  }

  double _particleOpacity() {
    switch (preset) {
      case 'command': return 0.8;
      case 'arena': return 0.6;
      case 'lounge': return 0.5;
      case 'auth': return 0.9;
      case 'cyberpunk': return 0.7;
      default: return 0.4;
    }
  }

  List<Widget> _buildNebulaOrbs() {
    switch (preset) {
      case 'command':
        return [
          _BreathingNebulaOrb(
            top: -180, left: -150, size: 450,
            color: AppColors.primary.withValues(alpha: 0.06),
            blur: 100, breatheIntensity: 0.3,
          ),
          _BreathingNebulaOrb(
            bottom: -120, right: -120, size: 380,
            color: AppColors.electricBlue.withValues(alpha: 0.05),
            blur: 100, breatheIntensity: 0.2,
            breatheDuration: const Duration(seconds: 5),
          ),
          _BreathingNebulaOrb(
            top: 200, right: -80, size: 250,
            color: AppColors.nebulaPurple.withValues(alpha: 0.04),
            blur: 80, breatheIntensity: 0.25,
            breatheDuration: const Duration(seconds: 7),
          ),
        ];
      case 'auth':
        return [
          _BreathingNebulaOrb(
            top: -200, left: -180, size: 500,
            color: AppColors.primary.withValues(alpha: 0.08),
            blur: 120, breatheIntensity: 0.4,
          ),
          _BreathingNebulaOrb(
            bottom: -150, right: -150, size: 420,
            color: AppColors.nebulaPurple.withValues(alpha: 0.06),
            blur: 120, breatheIntensity: 0.3,
            breatheDuration: const Duration(seconds: 6),
          ),
        ];
      case 'arena':
        return [
          _BreathingNebulaOrb(
            top: -100, right: -100, size: 300,
            color: AppColors.primary.withValues(alpha: 0.04),
            blur: 80, breatheIntensity: 0.2,
          ),
        ];
      case 'lounge':
        return [
          _BreathingNebulaOrb(
            top: -100, left: -100, size: 350,
            color: AppColors.ceoGold.withValues(alpha: 0.03),
            blur: 100, breatheIntensity: 0.15,
            breatheDuration: const Duration(seconds: 8),
          ),
          _BreathingNebulaOrb(
            bottom: -80, right: -80, size: 280,
            color: AppColors.customerWarm.withValues(alpha: 0.03),
            blur: 80, breatheIntensity: 0.15,
            breatheDuration: const Duration(seconds: 6),
          ),
        ];
      case 'cyberpunk':
        return [
          _BreathingNebulaOrb(
            top: -180, left: -180, size: 500,
            color: AppColors.neonMagenta.withValues(alpha: 0.06),
            blur: 120, breatheIntensity: 0.35,
          ),
          _BreathingNebulaOrb(
            bottom: -150, right: -120, size: 400,
            color: AppColors.neonIce.withValues(alpha: 0.05),
            blur: 100, breatheIntensity: 0.3,
            breatheDuration: const Duration(seconds: 5),
          ),
          _BreathingNebulaOrb(
            top: 150, right: -100, size: 300,
            color: AppColors.neonViolet.withValues(alpha: 0.04),
            blur: 80, breatheIntensity: 0.25,
            breatheDuration: const Duration(seconds: 7),
          ),
        ];
      default:
        return [
          _BreathingNebulaOrb(
            top: -150, left: -150, size: 400,
            color: AppColors.primary.withValues(alpha: 0.03),
            blur: 100, breatheIntensity: 0.15,
          ),
        ];
    }
  }
}

/// A nebula orb that slowly breathes (scales and alpha-pulses)
class _BreathingNebulaOrb extends StatefulWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double blur;
  final double breatheIntensity;
  final Duration breatheDuration;

  const _BreathingNebulaOrb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.blur,
    this.breatheIntensity = 0.2,
    this.breatheDuration = const Duration(seconds: 4),
  });

  @override
  State<_BreathingNebulaOrb> createState() => _BreathingNebulaOrbState();
}

class _BreathingNebulaOrbState extends State<_BreathingNebulaOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.breatheDuration,
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
      builder: (context, _) {
        final breathe = Curves.easeInOutSine.transform(_controller.value);
        final scale = 1.0 + breathe * widget.breatheIntensity;
        final alphaScale = 1.0 + breathe * widget.breatheIntensity * 0.5;

        return Positioned(
          top: widget.top,
          bottom: widget.bottom,
          left: widget.left,
          right: widget.right,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                    alpha: (widget.color.a * alphaScale).clamp(0.0, 1.0),
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hexagonal grid overlay painter
class _HexGridPainter extends CustomPainter {
  final Color color;
  _HexGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexRadius = 40.0;
    final hexHeight = hexRadius * sqrt(3);
    
    for (double y = -hexHeight; y < size.height + hexHeight; y += hexHeight) {
      for (double x = -hexRadius * 2; x < size.width + hexRadius * 2; x += hexRadius * 3) {
        final offsetX = ((y ~/ hexHeight) % 2 == 0) ? 0.0 : hexRadius * 1.5;
        _drawHex(canvas, Offset(x + offsetX, y), hexRadius, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
