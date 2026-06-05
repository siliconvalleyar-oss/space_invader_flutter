import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, Rect, MaskFilter, BlurStyle;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import '../game/space_invaders_game.dart';
import 'bullet.dart';

/// Individual enemy invader rendered with sprite from assets.
class Enemy extends SpriteComponent with HasGameRef<SpaceInvadersGame> {
  int hitPoints = 2;
  final int row;
  final int col;
  final int type;
  bool visible = true;
  double _animT = 0;

  Enemy({required this.row, required this.col, this.type = 0})
      : super(size: Vector2(30, 24));

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    // Select sprite based on enemy type
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

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final pulse = sin(_animT * 3) * 0.1 + 0.9;

    // Colored glow based on hitpoints
    final glowColor = hitPoints == 2
        ? const Color(0xFFFF4444)
        : const Color(0xFFFF8844);
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 * pulse, glowPaint);

    // Draw the sprite
    super.render(canvas);

    // Damage overlay
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

  void takeDamage() {
    hitPoints--;
    if (hitPoints <= 0) visible = false;
  }
}

/// Boss enemy - large invader with sprite rendering.
class Boss extends SpriteComponent with HasGameRef<SpaceInvadersGame> {
  int hitPoints = 10;
  final int maxHp;
  bool visible = true;
  double _animT = 0;
  double _beamTimer = 0;
  double _beamInterval = 2.5;

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

    // Boss aura glow
    final auraColor = Color.fromARGB(
        255, 180, (50 + (1 - hp) * 150).toInt(), (50 + hp * 200).toInt());
    final glowPaint = Paint()
      ..color = auraColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(cx, cy), cx * 1.1, glowPaint);

    // Draw sprite
    super.render(canvas);

    // Health bar
    _drawHealthBar(canvas);
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
