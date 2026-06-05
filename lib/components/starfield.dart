import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, MaskFilter, BlurStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Scrolling starfield background with optional planet decorations.
class Starfield extends Component with HasGameRef {
  final List<_Star> _stars = [];
  final List<_Planet> _planets = [];
  final Random _rng = Random();

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Generate stars
    for (int i = 0; i < 120; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble() * gameRef.size.x,
        y: _rng.nextDouble() * gameRef.size.y,
        size: 0.5 + _rng.nextDouble() * 2.0,
        alpha: 0.3 + _rng.nextDouble() * 0.7,
        speed: 15 + _rng.nextDouble() * 25,
      ));
    }

    // Load planet sprites
    final planetFiles = ['planet_00.png', 'planet_01.png', 'planet_02.png'];
    for (int i = 0; i < 3; i++) {
      final file = planetFiles[i];
      try {
        final sprite = await Sprite.load(file);
        final scale = 0.3 + _rng.nextDouble() * 0.4;
        _planets.add(_Planet(
          sprite: sprite,
          x: _rng.nextDouble() * gameRef.size.x,
          y: -100 - _rng.nextDouble() * 200 - i * 150,
          size: (sprite.originalSize * scale).x,
          speed: 8 + _rng.nextDouble() * 12,
        ));
      } catch (_) {}
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update stars
    for (final star in _stars) {
      star.y += star.speed * dt;
      if (star.y > gameRef.size.y) {
        star.y = -2;
        star.x = _rng.nextDouble() * gameRef.size.x;
      }
    }

    // Update planets
    for (final planet in _planets) {
      planet.y += planet.speed * dt;
      if (planet.y > gameRef.size.y + planet.size + 50) {
        planet.y = -planet.size - 50;
        planet.x = _rng.nextDouble() * gameRef.size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw stars
    for (final star in _stars) {
      final paint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: star.alpha)
        ..maskFilter = star.size > 1.5
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null;
      canvas.drawCircle(Offset(star.x, star.y), star.size * 0.5, paint);
    }

    // Draw planets (behind game objects)
    for (final planet in _planets) {
      planet.sprite.render(
        canvas,
        position: Vector2(planet.x, planet.y),
        size: Vector2.all(planet.size),
      );
    }

    super.render(canvas);
  }

  /// Increase scroll speed as player advances levels
  void setSpeedLevel(int level) {
    for (final star in _stars) {
      star.speed = 15 + _rng.nextDouble() * 25 + level * 2;
    }
  }
}

class _Star {
  double x, y, size, alpha, speed;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.alpha,
    required this.speed,
  });
}

class _Planet {
  final Sprite sprite;
  double x, y, size, speed;
  _Planet({
    required this.sprite,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}
