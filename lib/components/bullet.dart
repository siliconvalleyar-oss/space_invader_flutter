import 'dart:async';
import 'dart:ui' show Canvas, Paint, Color, Offset, RRect, Rect, Radius, ColorFilter, BlendMode, MaskFilter, BlurStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import '../game/space_invaders_game.dart';

/// Bullet component rendered with sprite from assets.
/// Player bullets use disparo_de_nave_00.png (visible beam), 
/// enemy bullets use bullet.png with red tint.
class Bullet extends SpriteComponent with HasGameRef<SpaceInvadersGame> {
  final bool isPlayerBullet;
  final double speed;
  bool visible = true;

  Bullet({
    required Vector2 position,
    required this.isPlayerBullet,
    this.speed = 400.0,
  }) : super(size: isPlayerBullet ? Vector2(16, 32) : Vector2(12, 24)) {
    this.position = position;
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    if (isPlayerBullet) {
      // Use ship shot sprite for player bullets
      try {
        sprite = await Sprite.load('disparo_de_nave_00.png');
        // Scale sprite to component size
      } catch (_) {
        try {
          sprite = await Sprite.load('bullet.png');
        } catch (_) {}
      }
    } else {
      // Use generic bullet for enemy
      try {
        sprite = await Sprite.load('bullet.png');
      } catch (_) {}
    }
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    if (isPlayerBullet) {
      // Green glow for player bullet
      _drawGlow(canvas, const Color(0xFF00FF88));      
      // Draw sprite without tint
      if (sprite != null) {
        paint.colorFilter = null;
        sprite!.render(canvas, size: size);
      }
      // Bright core line
      final corePaint = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: 3, height: size.y - 6),
        corePaint,
      );
    } else {
      // Red glow for enemy bullet
      _drawGlow(canvas, const Color(0xFFFF4444));
      // Draw with red tint
      if (sprite != null) {
        paint.colorFilter = const ColorFilter.mode(Color(0xFFFF4444), BlendMode.srcATop);
        super.render(canvas);
      }
    }
  }

  void _drawGlow(Canvas canvas, Color color) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x + 6,
          height: size.y + 6,
        ),
        const Radius.circular(6),
      ),
      glowPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPlayerBullet) {
      position.y -= speed * dt;
    } else {
      position.y += speed * dt;
    }
    if (position.y < -40 || position.y > (gameRef?.size.y ?? 800) + 40) {
      removeFromParent();
    }
  }
}
