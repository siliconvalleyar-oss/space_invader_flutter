import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, MaskFilter, BlurStyle, PaintingStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Types of power-ups available in the game.
enum PowerUpType {
  shield,
  triple,
  extraLife,
}

/// Power-up that falls from destroyed enemies.
/// Player collects by overlapping.
class PowerUp extends SpriteComponent {
  final PowerUpType type;
  bool visible = true;
  double _animT = 0;
  static const double fallSpeed = 60.0;

  PowerUp({
    required Vector2 position,
    required this.type,
  }) : super(size: Vector2(28, 28)) {
    this.position = position;
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Load different sprites for each type
    switch (type) {
      case PowerUpType.shield:
        try {
          sprite = await Sprite.load('nave_02.png');
        } catch (_) {}
        break;
      case PowerUpType.triple:
        try {
          sprite = await Sprite.load('disparo_de_nave_triple_00.png');
        } catch (_) {}
        break;
      case PowerUpType.extraLife:
        try {
          sprite = await Sprite.load('nave_04.png');
        } catch (_) {}
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
    position.y += fallSpeed * dt;

    if (      position.y > 880) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    // Floating/bobbing scale
    final scale = 1.0 + sin(_animT * 4) * 0.08;
    final cx = size.x / 2, cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale, scale);
    canvas.translate(-cx, -cy);

    // Glow ring
    final glowColor = _glowColor();
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.25 + 0.15 * sin(_animT * 3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), cx + 4, glowPaint);

    // Background circle
    final bgPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), cx, bgPaint);

    // Border ring
    final borderPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), cx, borderPaint);

    // Draw sprite (power-up icon)
    if (sprite != null) {
      sprite!.render(canvas, size: Vector2.all(size.x * 0.6));
    }

    // Pulsing ring
    final pulseAlpha = (0.3 + 0.2 * sin(_animT * 5)).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = glowColor.withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), cx + 4 + 3 * sin(_animT * 3), pulsePaint);

    canvas.restore();
  }

  Color _glowColor() {
    switch (type) {
      case PowerUpType.shield:
        return const Color(0xFF44AAFF);
      case PowerUpType.triple:
        return const Color(0xFFFFAA00);
      case PowerUpType.extraLife:
        return const Color(0xFF44FF44);
    }
  }

}
