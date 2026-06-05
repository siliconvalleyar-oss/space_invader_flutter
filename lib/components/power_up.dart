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
  freeze,
  spread,
  bomb,
}

/// Power-up that falls from destroyed enemies.
/// Player collects by overlapping.
class PowerUp extends SpriteComponent {
  final PowerUpType type;
  bool visible = true;
  double _animT = 0;

  // Entry animation state
  double _entryTimer = 0;
  static const double entryDuration = 0.5;
  bool get _inEntryPhase => _entryTimer < entryDuration;

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
    _entryTimer = 0;

    // Load different sprites for each type
    switch (type) {
      case PowerUpType.shield:
        try { sprite = await Sprite.load('nave_02.png'); } catch (_) {}
        break;
      case PowerUpType.triple:
        try { sprite = await Sprite.load('disparo_de_nave_triple_00.png'); } catch (_) {}
        break;
      case PowerUpType.extraLife:
        try { sprite = await Sprite.load('nave_04.png'); } catch (_) {}
        break;
      case PowerUpType.freeze:
        try { sprite = await Sprite.load('nave_03.png'); } catch (_) {}
        break;
      case PowerUpType.spread:
        try { sprite = await Sprite.load('disparo_de_nave_01.png'); } catch (_) {}
        break;
      case PowerUpType.bomb:
        try { sprite = await Sprite.load('disparo_de_nave_02.png'); } catch (_) {}
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;

    // Entry animation: timer advances until reaching entryDuration
    if (_inEntryPhase) {
      _entryTimer += dt;
      // Delay actual falling during entry so the power-up spawns in place
      if (_entryTimer < 0.15) {
        // Brief pause before starting to fall
        return;
      }
    }

    position.y += fallSpeed * dt;

    if (position.y > 880) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final cx = size.x / 2, cy = size.y / 2;
    final glowColor = _glowColor();

    // === ENTRY ANIMATION ===
    double entryAlpha = 1.0;
    double entryScale = 1.0;
    double entryRotation = 0.0;

    if (_inEntryPhase) {
      final t = (_entryTimer / entryDuration).clamp(0.0, 1.0);
      // Ease-out cubic: fast start, smooth end
      final eased = 1.0 - pow(1.0 - t, 3).toDouble();
      entryAlpha = eased;
      entryScale = 0.3 + 0.7 * eased;
      entryRotation = (1.0 - eased) * pi * 2; // Full spin during entry
    }

    canvas.save();

    // Apply entry transforms
    if (_inEntryPhase) {
      canvas.translate(cx, cy);
      canvas.rotate(entryRotation);
      canvas.scale(entryScale, entryScale);
      canvas.translate(-cx, -cy);
    }

    // Floating bobbing scale (only after entry phase completes)
    if (!_inEntryPhase) {
      final floatScale = 1.0 + sin(_animT * 4) * 0.08;
      canvas.translate(cx, cy);
      canvas.scale(floatScale, floatScale);
      canvas.translate(-cx, -cy);
    }

    // Glow ring
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: (0.25 + 0.15 * sin(_animT * 3)).clamp(0.0, 1.0) * entryAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), cx + 4, glowPaint);

    // Background circle
    final bgPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.3 * entryAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), cx, bgPaint);

    // Border ring
    final borderPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.8 * entryAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), cx, borderPaint);

    // Draw sprite (power-up icon) with alpha
    if (sprite != null) {
      final spritePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: entryAlpha);
      sprite!.render(canvas, size: Vector2.all(size.x * 0.6), overridePaint: spritePaint);
    }

    // Pulsing ring (only after entry or subtle during)
    final pulseAlpha = (0.3 + 0.2 * sin(_animT * 5)).clamp(0.0, 1.0) * entryAlpha;
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
      case PowerUpType.freeze:
        return const Color(0xFF88CCFF);
      case PowerUpType.spread:
        return const Color(0xFFFF8800);
      case PowerUpType.bomb:
        return const Color(0xFFFF2200);
    }
  }

}
