import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A floating particle that drifts across the screen
class _Particle {
  double x;
  double y;
  final double size;
  double speedX;
  double speedY;
  final double opacity;
  final Color color;
  // Comet trail support
  final bool isComet;
  final List<Offset> trail;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.color,
    this.isComet = false,
  }) : trail = [];
}

/// Performance-aware particle system with comet trails, connection lines,
/// and pulse wave effects.
/// 
/// Presets:
/// - `command`: Galaxy-style with cyan/blue/purple particles + comets
/// - `arena`: Energy-style with faster, brighter particles + connections
/// - `lounge`: Luxury-style with warm, slow, elegant particles
/// - `subtle`: Minimal ambient particles for overlays
/// - `cyberpunk`: Intense magenta/cyan with fast comets
class TitanParticleField extends StatefulWidget {
  final String preset;
  final int particleCount;
  final double opacity;

  const TitanParticleField({
    super.key,
    this.preset = 'command',
    this.particleCount = 40,
    this.opacity = 1.0,
  });

  @override
  State<TitanParticleField> createState() => _TitanParticleFieldState();
}

class _TitanParticleFieldState extends State<TitanParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();
  double _pulseWaveRadius = 0;
  double _pulseWaveAlpha = 0;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  List<_Particle> _generateParticles() {
    final colors = _colorsForPreset();
    final count = widget.particleCount;
    final cometChance = _cometChance();
    return List.generate(count, (i) {
      final speedMult = _speedMultiplier();
      final isComet = _random.nextDouble() < cometChance;
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: isComet
            ? _random.nextDouble() * 2 + 1.5
            : _random.nextDouble() * 2.5 + 0.5,
        speedX: isComet
            ? (_random.nextDouble() * 0.008 + 0.003) * speedMult
            : (_random.nextDouble() - 0.5) * 0.002 * speedMult,
        speedY: isComet
            ? (_random.nextDouble() * 0.004 + 0.001) * speedMult
            : (_random.nextDouble() - 0.5) * 0.0015 * speedMult,
        opacity: _random.nextDouble() * 0.5 + 0.15,
        color: colors[_random.nextInt(colors.length)],
        isComet: isComet,
      );
    });
  }

  List<Color> _colorsForPreset() {
    switch (widget.preset) {
      case 'arena':
        return [AppColors.particleCyan, AppColors.particleBlue, AppColors.primaryLight, Colors.white];
      case 'lounge':
        return [AppColors.particleGold, AppColors.customerWarm, AppColors.particleWhite];
      case 'subtle':
        return [AppColors.particleWhite, AppColors.particleCyan];
      case 'cyberpunk':
        return [AppColors.neonMagenta, AppColors.neonIce, AppColors.particleCyan, AppColors.neonViolet];
      case 'command':
      default:
        return [AppColors.particleCyan, AppColors.particleBlue, AppColors.particlePurple, AppColors.particleWhite];
    }
  }

  double _speedMultiplier() {
    switch (widget.preset) {
      case 'arena': return 1.8;
      case 'lounge': return 0.5;
      case 'subtle': return 0.3;
      case 'cyberpunk': return 2.2;
      default: return 1.0;
    }
  }

  double _cometChance() {
    switch (widget.preset) {
      case 'arena': return 0.12;
      case 'cyberpunk': return 0.18;
      case 'command': return 0.08;
      case 'lounge': return 0.03;
      default: return 0.05;
    }
  }

  bool get _showConnections {
    return widget.preset == 'arena' || widget.preset == 'command' || widget.preset == 'cyberpunk';
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
          _frameCount++;
          
          // Update particle positions
          for (var p in _particles) {
            // Store trail for comets
            if (p.isComet && p.trail.length < 8) {
              p.trail.add(Offset(p.x, p.y));
            } else if (p.isComet) {
              p.trail.removeAt(0);
              p.trail.add(Offset(p.x, p.y));
            }
            
            p.x += p.speedX;
            p.y += p.speedY;
            // Wrap around
            if (p.x < -0.05) p.x = 1.05;
            if (p.x > 1.05) p.x = -0.05;
            if (p.y < -0.05) p.y = 1.05;
            if (p.y > 1.05) p.y = -0.05;
          }

          // Pulse wave every 180 frames (~3 seconds)
          if (_frameCount % 180 == 0) {
            _pulseWaveRadius = 0;
            _pulseWaveAlpha = 0.15;
          }
          if (_pulseWaveAlpha > 0) {
            _pulseWaveRadius += 4;
            _pulseWaveAlpha -= 0.001;
          }

          return CustomPaint(
            painter: _ParticleFieldPainter(
              particles: _particles,
              time: _controller.value,
              showConnections: _showConnections,
              connectionColor: _colorsForPreset().first,
              pulseWaveRadius: _pulseWaveRadius,
              pulseWaveAlpha: _pulseWaveAlpha,
              pulseWaveColor: _colorsForPreset().first,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ParticleFieldPainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final bool showConnections;
  final Color connectionColor;
  final double pulseWaveRadius;
  final double pulseWaveAlpha;
  final Color pulseWaveColor;

  _ParticleFieldPainter({
    required this.particles,
    required this.time,
    required this.showConnections,
    required this.connectionColor,
    required this.pulseWaveRadius,
    required this.pulseWaveAlpha,
    required this.pulseWaveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw connection lines between nearby particles (constellation effect)
    if (showConnections) {
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4;
      const maxDist = 0.12; // 12% of screen as connection distance
      
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final dx = particles[i].x - particles[j].x;
          final dy = particles[i].y - particles[j].y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < maxDist) {
            final alpha = ((1.0 - dist / maxDist) * 0.15).clamp(0.0, 0.15);
            linePaint.color = connectionColor.withValues(alpha: alpha);
            canvas.drawLine(
              Offset(particles[i].x * size.width, particles[i].y * size.height),
              Offset(particles[j].x * size.width, particles[j].y * size.height),
              linePaint,
            );
          }
        }
      }
    }

    // Draw particles
    for (var p in particles) {
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      
      // Subtle twinkle effect
      final twinkle = 0.6 + 0.4 * sin(time * 2 * pi + p.x * 10 + p.y * 10);
      final alpha = (p.opacity * twinkle).clamp(0.0, 1.0);

      // Comet trail
      if (p.isComet && p.trail.length > 1) {
        for (int i = 0; i < p.trail.length - 1; i++) {
          final trailAlpha = (alpha * (i / p.trail.length) * 0.4).clamp(0.0, 1.0);
          final trailSize = p.size * (i / p.trail.length) * 0.6;
          paint.color = p.color.withValues(alpha: trailAlpha);
          canvas.drawCircle(
            Offset(p.trail[i].dx * size.width, p.trail[i].dy * size.height),
            trailSize, paint,
          );
        }
      }
      
      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
      
      // Soft glow around larger particles
      if (p.size > 1.5) {
        paint.color = p.color.withValues(alpha: alpha * 0.2);
        canvas.drawCircle(Offset(dx, dy), p.size * 3, paint);
      }

      // Extra bright core for comets
      if (p.isComet) {
        paint.color = Colors.white.withValues(alpha: alpha * 0.7);
        canvas.drawCircle(Offset(dx, dy), p.size * 0.5, paint);
      }
    }

    // Pulse wave
    if (pulseWaveAlpha > 0) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(
        center, pulseWaveRadius,
        Paint()
          ..color = pulseWaveColor.withValues(alpha: pulseWaveAlpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


/// Celebration burst effect — spawns particles outward from center
class TitanCelebrationBurst extends StatefulWidget {
  final Color color;
  final VoidCallback? onComplete;

  const TitanCelebrationBurst({
    super.key,
    this.color = AppColors.primary,
    this.onComplete,
  });

  @override
  State<TitanCelebrationBurst> createState() => _TitanCelebrationBurstState();
}

class _TitanCelebrationBurstState extends State<TitanCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_BurstParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(30, (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 200 + 80;
      return _BurstParticle(
        angle: angle,
        speed: speed,
        size: _random.nextDouble() * 3 + 1,
        color: Color.lerp(widget.color, Colors.white, _random.nextDouble() * 0.5)!,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
          painter: _BurstPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BurstParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _BurstParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _BurstPainter extends CustomPainter {
  final List<_BurstParticle> particles;
  final double progress;

  _BurstPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      final dist = p.speed * progress;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final dx = center.dx + cos(p.angle) * dist;
      final dy = center.dy + sin(p.angle) * dist;

      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), p.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
