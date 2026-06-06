import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, Rect, RRect, Radius, MaskFilter, BlurStyle, PaintingStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import '../game/space_invaders_game.dart';

/// Player spaceship component rendered with sprite from assets.
/// Uses nave_00.png (88x118) scaled to fit gameplay.
class Player extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  bool visible = true;
  bool shieldActive = false;
  double _engineAnimT = 0;
  Sprite? sprite;

  Player() : super(size: Vector2(40, 54));

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    try {
      sprite = await Sprite.load('nave_00.png');
    } catch (_) {
      try {
        sprite = await Sprite.load('player.png');
      } catch (_) {}
    }
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _engineAnimT += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    if (sprite != null) {
      sprite!.render(canvas, size: size, position: Vector2.zero());
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFF44AA88).withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );
    }

    // Engine glow animation
    final engineAlpha = (0.3 + 0.2 * sin(_engineAnimT * 6)).clamp(0.0, 1.0);
    final engineGlow = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: engineAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(size.x / 2, size.y - 2), 16, engineGlow);

    // Shield effect (when active)
    if (shieldActive) {
      final shieldAlpha = 0.2 + 0.1 * sin(_engineAnimT * 5);
      final shieldPaint = Paint()
        ..color = const Color(0xFF44AAFF).withValues(alpha: shieldAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.7, shieldPaint);

      final shieldRing = Paint()
        ..color = const Color(0xFF44AAFF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.7, shieldRing);
    }

    // Cockpit glow
    final cockpitPaint = Paint()
      ..color = const Color(0xAA00FF88).withValues(alpha: 0.6 + 0.4 * sin(_engineAnimT * 4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y * 0.3), 4, cockpitPaint);
  }
}
