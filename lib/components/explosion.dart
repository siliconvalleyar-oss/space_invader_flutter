import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, MaskFilter, BlurStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Explosion effect with particles and optional impact sprite.
class Explosion extends Component with HasGameRef {
  final Vector2 _position;
  final Color _color;
  final int _particleCount;
  final double _duration;
  double _elapsed = 0.0;
  final List<_Particle> _particles = [];
  bool _showSprite = true;
  Sprite? _impactSprite;
  double _spriteAlpha = 1.0;

  Explosion({
    required Vector2 position,
    Color color = const Color(0xFFFF6644),
    int particleCount = 12,
    double duration = 0.6,
    bool useSprite = true,
  })  : _position = position.clone(),
        _color = color,
        _particleCount = particleCount,
        _duration = duration,
        _showSprite = useSprite;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Load impact sprite
    if (_showSprite) {
      try {
        _impactSprite = await Sprite.load('impact_00.png');
      } catch (_) {
        _showSprite = false;
      }
    }

    // Generate particles
    final rng = Random();
    for (int i = 0; i < _particleCount; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 50 + rng.nextDouble() * 150;
      _particles.add(_Particle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        size: 2 + rng.nextDouble() * 4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }

    final progress = _elapsed / _duration;

    // Fade sprite quickly
    if (_showSprite && progress < 0.3) {
      _spriteAlpha = 1.0 - (progress / 0.3);
    } else if (_showSprite) {
      _showSprite = false;
    }

    // Update particles
    for (final p in _particles) {
      p.x += p.dx * dt;
      p.y += p.dy * dt;
      p.dx *= 0.95;
      p.dy *= 0.95;
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _elapsed / _duration;

    // Draw impact sprite (brief flash)
    if (_showSprite && _impactSprite != null && _spriteAlpha > 0) {
      final size = 40.0;
      _impactSprite!.render(
        canvas,
        position: _position - Vector2.all(size / 2),
        size: Vector2.all(size),
        overridePaint: Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: _spriteAlpha),
      );
    }

    // Draw particles
    for (final p in _particles) {
      final particleAlpha = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = _color.withValues(alpha: particleAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(_position.x + p.x, _position.y + p.y),
        p.size,
        paint,
      );
    }

    // Central flash
    if (progress < 0.2) {
      final flashPaint = Paint()
        ..color = const Color(0xFFFFFF88).withValues(alpha: 1.0 - progress * 5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(
        Offset(_position.x, _position.y),
        15 + (1 - progress) * 10,
        flashPaint,
      );
    }

    super.render(canvas);
  }
}

class _Particle {
  double x = 0, y = 0;
  double dx, dy, size;
  _Particle({
    required this.dx,
    required this.dy,
    required this.size,
  });
}
