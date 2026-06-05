import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, Rect, RRect, Radius, Path, MaskFilter, BlurStyle, PaintingStyle, Gradient, TextDirection, FontWeight;
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;
import 'package:flame/components.dart';
import '../game/space_invaders_game.dart';

/// Retro-styled main menu rendered as a Flame component.
/// Shows animated title, PLAY/LEVELS buttons, high score, and arcade decorations.
class MainMenu extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  double _animT = 0;
  double _scanlineOffset = 0;

  /// Button rectangles in world coordinates for hit testing.
  Rect playButtonRect = Rect.zero;
  Rect levelsButtonRect = Rect.zero;

  static const double _titleY = 0.18;
  static const double _subtitleY = 0.30;
  static const double _playY = 0.52;
  static const double _levelsY = 0.64;
  static const double _hsY = 0.78;
  static const double _footerY = 0.92;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    // No sprite loading needed — all drawn procedurally
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
    _scanlineOffset = (_scanlineOffset + dt * 120) % 4;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final w = size.x;

    _drawScanlines(canvas);
    _drawVignette(canvas);
    _drawTitle(canvas, cx, w);
    _drawSubtitle(canvas, cx);
    _drawPlayButton(canvas, cx, w);
    _drawLevelsButton(canvas, cx, w);
    _drawHighScore(canvas, cx);
    _drawDecorationEnemies(canvas, cx);
    _drawFooter(canvas, cx);
  }

  // ─── SCANLINES ───

  void _drawScanlines(Canvas canvas) {
    final paint = Paint()..color = const Color(0x08000000);
    for (double y = _scanlineOffset; y < size.y; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  // ─── VIGNETTE ───

  void _drawVignette(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = Paint()
      ..shader = Gradient.radial(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.7,
        [const Color(0x00FFFFFF), const Color(0x33000000)],
      );
    canvas.drawRect(rect, gradient);
  }

  // ─── TITLE ───

  void _drawTitle(Canvas canvas, double cx, double w) {
    final titleY = size.y * _titleY;

    // Outer glow (cyan)
    final glowAlpha = (0.3 + 0.2 * sin(_animT * 1.5)).clamp(0.0, 1.0);
    final outerGlow = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    _drawTextCentered(canvas, 'SPACE', cx, titleY - 18, 42, outerGlow);
    _drawTextCentered(canvas, 'INVADERS', cx, titleY + 20, 42, outerGlow);

    // Mid glow
    final midGlow = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    _drawTextCentered(canvas, 'SPACE', cx, titleY - 18, 42, midGlow);
    _drawTextCentered(canvas, 'INVADERS', cx, titleY + 20, 42, midGlow);

    // Core text (white)
    final corePaint = Paint()..color = const Color(0xFFFFFFFF);
    _drawTextCentered(canvas, 'SPACE', cx, titleY - 18, 42, corePaint);
    _drawTextCentered(canvas, 'INVADERS', cx, titleY + 20, 42, corePaint);

    // Underline glow
    final linePaint = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: 0.4 + 0.3 * sin(_animT * 2))
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
      Offset(cx - 100, titleY + 44),
      Offset(cx + 100, titleY + 44),
      linePaint,
    );
  }

  // ─── SUBTITLE ───

  void _drawSubtitle(Canvas canvas, double cx) {
    final subY = size.y * _subtitleY;
    final flicker = sin(_animT * 3) > 0.5 ? 1.0 : 0.85;
    final paint = Paint()
      ..color = const Color(0xFF44AACC).withValues(alpha: 0.7 * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    _drawTextCentered(canvas, '★ ARCAD EDI T I ON ★', cx, subY, 14, paint);
  }

  // ─── PLAY BUTTON ───

  void _drawPlayButton(Canvas canvas, double cx, double w) {
    final y = size.y * _playY;
    final btnW = w * 0.55;
    final btnH = 48.0;

    // Store for hit testing
    playButtonRect = Rect.fromCenter(center: Offset(cx, y), width: btnW, height: btnH);

    // Button bg pulse
    final pulse = 0.5 + 0.3 * sin(_animT * 2.5);
    final bgPaint = Paint()
      ..color = const Color(0xFF004433).withValues(alpha: pulse * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      _rrrect(playButtonRect, 8),
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.7 + 0.3 * sin(_animT * 2.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(_rrrect(playButtonRect, 8), borderPaint);

    // Play icon + text
    final textPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 1.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    _drawTextCentered(canvas, '▶  PLAY', cx, y + 6, 22, textPaint);
  }

  // ─── LEVELS BUTTON ───

  void _drawLevelsButton(Canvas canvas, double cx, double w) {
    final y = size.y * _levelsY;
    final btnW = w * 0.55;
    final btnH = 44.0;

    levelsButtonRect = Rect.fromCenter(center: Offset(cx, y), width: btnW, height: btnH);

    final bgPaint = Paint()
      ..color = const Color(0xFF222244).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(_rrrect(levelsButtonRect, 8), bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF6688CC).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(_rrrect(levelsButtonRect, 8), borderPaint);

    final textPaint = Paint()
      ..color = const Color(0xFF88AACC)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    _drawTextCentered(canvas, '☰  LEVELS', cx, y + 5, 18, textPaint);
  }

  // ─── HIGH SCORE ───

  void _drawHighScore(Canvas canvas, double cx) {
    final hs = gameRef.highScore;
    if (hs <= 0) return;

    final y = size.y * _hsY;
    final paint = Paint()
      ..color = const Color(0xFFFFCC44).withValues(alpha: 0.6 + 0.2 * sin(_animT * 1.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    _drawTextCentered(canvas, 'HIGH SCORE', cx, y - 10, 12, paint);
    final scorePaint = Paint()
      ..color = const Color(0xFFFFEE88).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    _drawTextCentered(canvas, '$hs', cx, y + 10, 20, scorePaint);
  }

  // ─── DECORATION ENEMIES ───

  void _drawDecorationEnemies(Canvas canvas, double cx) {
    // Floating enemy silhouettes as decoration
    final count = 4;
    for (int i = 0; i < count; i++) {
      final phase = i * 1.57 + _animT * 0.5;
      final x = cx + cos(phase + i * 2.0) * (size.x * 0.35);
      final y = size.y * 0.40 + sin(phase * 0.7 + i) * 30;
      final alpha = (0.08 + 0.06 * sin(phase * 0.5 + i)).clamp(0.0, 1.0);

      final enemyPaint = Paint()
        ..color = const Color(0xFF00FFCC).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      _drawEnemyShape(canvas, Offset(x, y), 16, enemyPaint);
    }
  }

  void _drawEnemyShape(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.7, center.dy - size * 0.3)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx + size * 0.7, center.dy + size * 0.5)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.7, center.dy + size * 0.5)
      ..lineTo(center.dx - size, center.dy)
      ..lineTo(center.dx - size * 0.7, center.dy - size * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  // ─── FOOTER ───

  void _drawFooter(Canvas canvas, double cx) {
    final y = size.y * _footerY;
    final paint = Paint()
      ..color = const Color(0xFF335566).withValues(alpha: 0.5);
    _drawTextCentered(canvas, 'v1.4.2  •  FREE BUFF', cx, y, 10, paint);
  }

  // ─── HELPERS ───

  void _drawTextCentered(Canvas canvas, String text, double cx, double y, double size, Paint paint) {
    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: paint.color,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  RRect _rrrect(Rect rect, double radius) {
    return RRect.fromRectAndRadius(rect, Radius.circular(radius));
  }

  /// Handle a tap at the given position. Returns true if the tap was handled.
  bool handleTap(Vector2 position) {
    final pos = Offset(position.x, position.y);
    if (playButtonRect.contains(pos)) {
      gameRef.startGameFromMenu();
      return true;
    }
    if (levelsButtonRect.contains(pos)) {
      gameRef.showLevelSelect();
      return true;
    }
    return false;
  }
}
