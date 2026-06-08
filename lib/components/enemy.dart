import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, Rect, RRect, Radius, MaskFilter, BlurStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import '../game/space_invaders_game.dart';
import 'bullet.dart';

/// Individual enemy invader rendered with sprite from assets.
class Enemy extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  int hitPoints = 1;
  final int row;
  final int col;
  final int type;
  bool visible = true;
  bool frozen = false;
  double _animT = 0;
  double _hitFlashTimer = 0;
  Sprite? sprite;

  Enemy({required this.row, required this.col, this.type = 0})
      : super(size: Vector2(30, 24));

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    final spriteFiles = ['enemy_00.png', 'enemy_01.png', 'enemy_02.png'];
    final file = spriteFiles[type % spriteFiles.length];
    try {
      sprite = await Sprite.load(file);
    } catch (_) {
      try {
        sprite = await Sprite.load('enemy.png');
      } catch (_) {}
    }
    anchor = Anchor.center;
  }

  void hitFlash() {
    _hitFlashTimer = 0.12;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final pulse = sin(_animT * 3) * 0.1 + 0.9;

    final glowColor = frozen
        ? const Color(0xFF44CCFF)
        : (hitPoints == 2
            ? const Color(0xFFFF4444)
            : const Color(0xFFFF8844));
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 * pulse, glowPaint);

    if (sprite != null) {
      sprite!.render(canvas, size: size, position: Vector2.zero());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(1, 1, size.x - 2, size.y - 2),
        Paint()..color = glowColor.withValues(alpha: 0.5 * pulse),
      );
    }

    // Hit flash overlay
    if (_hitFlashTimer > 0) {
      final flashPaint = Paint()
        ..color = const Color(0xCCFFFFFF).withValues(alpha: (_hitFlashTimer / 0.12).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        flashPaint,
      );
    }

    if (frozen) {
      _drawFrozenEffect(canvas);
    }

    if (hitPoints == 1) {
      final crackPaint = Paint()
        ..color = const Color(0x44FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawLine(
          Offset(4, 4), Offset(size.x - 4, size.y - 4), crackPaint);
      canvas.drawLine(
          Offset(size.x - 4, 4), Offset(4, size.y - 4), crackPaint);
    }
  }

  /// Draw ice tint overlay and crystal particles when frozen.
  void _drawFrozenEffect(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;

    // Blue ice tint overlay on the sprite
    final iceTint = Paint()
      ..color = const Color(0x6644CCFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      iceTint,
    );

    // Ice crystal particles that twinkle
    final crystalCount = 5;
    for (int i = 0; i < crystalCount; i++) {
      final phase = i * 1.256 + _animT * 2.0;
      final angle = phase;
      final dist = 6.0 + sin(_animT * 1.5 + i * 1.7) * 4.0;
      final particleX = cx + cos(angle) * dist;
      final particleY = cy + sin(angle) * dist;
      final particleSize = 1.5 + sin(_animT * 3.0 + i * 2.3) * 0.8;
      final alpha = (0.5 + 0.5 * sin(_animT * 4.0 + i * 1.1)).clamp(0.2, 1.0);

      final crystalPaint = Paint()
        ..color = const Color(0xCCFFFFFF).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(particleX, particleY), particleSize.abs() + 1, crystalPaint);

      // Bright center dot
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.6);
      canvas.drawCircle(Offset(particleX, particleY), (particleSize * 0.5).abs(), corePaint);
    }

    // Ice shimmer line
    final shimmerAlpha = (0.3 + 0.3 * sin(_animT * 2.5)).clamp(0.0, 1.0);
    final shimmerPaint = Paint()
      ..color = const Color(0xCCFFFFFF).withValues(alpha: shimmerAlpha)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(
      Offset(cx - 8, cy),
      Offset(cx + 8, cy + sin(_animT * 3) * 2),
      shimmerPaint,
    );
  }

  void takeDamage() {
    hitPoints--;
    if (hitPoints <= 0) visible = false;
  }
}

/// Boss enemy - large invader with sprite rendering.
class Boss extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  int hitPoints = 10;
  final int maxHp;
  bool visible = true;
  bool frozen = false;
  double _animT = 0;
  double _beamTimer = 0;
  double _beamInterval = 2.5;
  Sprite? sprite;

  Boss({this.maxHp = 10}) : super(size: Vector2(64, 48)) {
    hitPoints = maxHp;
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    try {
      sprite = await Sprite.load('boss.png');
    } catch (_) {}
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!visible || !gameRef.isGameStarted || gameRef.isGameOver) return;
    _animT += dt;
    position.x += 20 * dt * cos(_animT * 0.5);

    _beamTimer += dt;
    if (_beamTimer >= _beamInterval) {
      _beamTimer = 0;
      for (double off = -1; off <= 1; off += 1) {
        final b = Bullet(
            position: Vector2(position.x + off * 15, position.y + 20),
            isPlayerBullet: false,
            speed: 250);
        gameRef.enemyBullets.add(b);
        gameRef.add(b);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final cx = size.x / 2, cy = size.y / 2;
    final hp = hitPoints / maxHp;

    // Boss aura glow (changes to ice blue when frozen)
    if (frozen) {
      final freezeGlow = Paint()
        ..color = const Color(0xFF44CCFF).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset(cx, cy), cx * 1.1, freezeGlow);
    } else {
      final auraColor = Color.fromARGB(
          255, 180, (50 + (1 - hp) * 150).toInt(), (50 + hp * 200).toInt());
      final glowPaint = Paint()
        ..color = auraColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset(cx, cy), cx * 1.1, glowPaint);
    }

    if (sprite != null) {
      sprite!.render(canvas, size: size, position: Vector2.zero());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
        Paint()..color = Color.fromARGB(180, 50, (50 + (1 - hp) * 150).toInt(), (50 + hp * 200).toInt()),
      );
    }

    if (frozen) {
      _drawBossFrozenEffect(canvas);
    }

    _drawHealthBar(canvas);
    _drawHealthBar(canvas);
  }

  /// Draw ice tint overlay and crystal particles for boss when frozen.
  void _drawBossFrozenEffect(Canvas canvas) {
    final cx = size.x / 2, cy = size.y / 2;

    // Blue ice tint overlay on the sprite
    final iceTint = Paint()
      ..color = const Color(0x5544CCFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      iceTint,
    );

    // Larger ice crystals for boss
    final crystalCount = 8;
    for (int i = 0; i < crystalCount; i++) {
      final phase = i * 1.256 + _animT * 2.0;
      final angle = phase;
      final dist = 10.0 + sin(_animT * 1.5 + i * 1.7) * 6.0;
      final particleX = cx + cos(angle) * dist;
      final particleY = cy + sin(angle) * dist;
      final particleSize = 2.0 + sin(_animT * 3.0 + i * 2.3) * 1.0;
      final alpha = (0.5 + 0.5 * sin(_animT * 4.0 + i * 1.1)).clamp(0.2, 1.0);

      final crystalPaint = Paint()
        ..color = const Color(0xCCFFFFFF).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(particleX, particleY), particleSize.abs() + 1.5, crystalPaint);

      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.6);
      canvas.drawCircle(Offset(particleX, particleY), (particleSize * 0.5).abs(), corePaint);
    }

    // Ice shimmer lines
    final shimmerAlpha = (0.3 + 0.3 * sin(_animT * 2.5)).clamp(0.0, 1.0);
    final shimmerPaint = Paint()
      ..color = const Color(0xCCFFFFFF).withValues(alpha: shimmerAlpha)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(
      Offset(cx - 12, cy - 4),
      Offset(cx + 12, cy + 4 + sin(_animT * 3) * 3),
      shimmerPaint,
    );
    canvas.drawLine(
      Offset(cx - 8, cy + 4),
      Offset(cx + 8, cy - 4 + sin(_animT * 2) * 2),
      shimmerPaint..color = const Color(0xCCFFFFFF).withValues(alpha: shimmerAlpha * 0.6),
    );
  }

  void _drawHealthBar(Canvas canvas) {
    final pct = hitPoints / maxHp;
    final bw = size.x, bh = 4.0;
    canvas.drawRect(
        Rect.fromLTWH(0, size.y + 4, bw, bh),
        Paint()..color = const Color(0x44FF0000));
    canvas.drawRect(
        Rect.fromLTWH(0, size.y + 4, bw * pct, bh),
        Paint()
          ..color = Color.fromARGB(
              255, (255 * (1 - pct)).toInt(), (255 * pct).toInt(), 0));
  }

  void takeDamage() {
    hitPoints--;
    if (hitPoints <= 0) visible = false;
  }
}
