import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, Rect, RRect, Radius, Path, MaskFilter, BlurStyle, PaintingStyle;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route;
import '../game/space_invaders_game.dart';

class PauseMenu extends Component with HasGameRef<SpaceInvadersGame> {
  bool _visible = false;
  double _animT = 0;
  bool _isAnimating = false;
  bool _isOpening = false;

  bool get isActive => _visible || _isAnimating;

  void show() {
    _visible = true;
    _isAnimating = true;
    _isOpening = true;
    _animT = 0;
  }

  void hide() {
    _isAnimating = true;
    _isOpening = false;
    _animT = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isAnimating) return;
    _animT += dt * 3;
    if (_animT >= 1) {
      _animT = 1;
      _isAnimating = false;
      if (!_isOpening) {
        _visible = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_visible && !_isAnimating) return;

    final size = gameRef.size;
    final t = _isOpening ? _easeOutBack(_animT) : _easeInCubic(_animT);

    // Dim background
    final bgAlpha = (180 * t).toInt();
    final bgPaint = Paint()
      ..color = Color.fromARGB(bgAlpha, 0, 0, 0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    if (_animT <= 0) return;

    // Panel
    final panelW = size.x * 0.75;
    final panelH = 320.0;
    final scale = 0.3 + 0.7 * t;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scale, scale);
    canvas.translate(-panelW / 2, -panelH / 2);

    // Panel background
    final panelBg = Paint()
      ..color = const Color(0xCC0D0D2B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, panelW, panelH),
        const Radius.circular(16),
      ),
      panelBg,
    );

    // Panel border
    final borderPaint = Paint()
      ..color = const Color(0x44AAAAFF).withValues(alpha: t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, panelW, panelH),
        const Radius.circular(16),
      ),
      borderPaint,
    );

    // Title
    final titleAlpha = (255 * t).toInt();
    _drawText(canvas, 'PAUSED', panelW / 2, 50, 28, Colors.cyanAccent.withValues(alpha: t));

    // Resume button
    _drawButton(canvas, '▶  RESUME', panelW / 2, 130, panelW - 60, 44, t, const Color(0xFF44AAFF));

    // Restart button
    _drawButton(canvas, '↻  RESTART', panelW / 2, 190, panelW - 60, 44, t, const Color(0xFFFF8844));

    // Main Menu button
    _drawButton(canvas, '✕  MAIN MENU', panelW / 2, 250, panelW - 60, 44, t, const Color(0xFFFF4444));

    canvas.restore();
  }

  void _drawButton(Canvas canvas, String text, double x, double y, double w, double h, double t, Color color) {
    final alpha = (255 * t).toInt();
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15 * t);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w / 2, y - h / 2, w, h),
        const Radius.circular(10),
      ),
      bgPaint,
    );
    final border = Paint()
      ..color = color.withValues(alpha: 0.5 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w / 2, y - h / 2, w, h),
        const Radius.circular(10),
      ),
      border,
    );
    _drawText(canvas, text, x, y + 4, 16, color.withValues(alpha: t));
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color color) {
    final tb = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tb.paint(canvas, Offset(x - tb.width / 2, y - tb.height / 2));
  }

  double _easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }

  double _easeInCubic(double t) {
    return t * t * t;
  }

  String? handleTap(Vector2 position) {
    if (!_visible || _isAnimating) return null;
    final size = gameRef.size;
    final panelW = size.x * 0.75;
    final panelH = 320.0;
    final panelLeft = (size.x - panelW) / 2;
    final panelTop = (size.y - panelH) / 2;

    if (position.x < panelLeft || position.x > panelLeft + panelW ||
        position.y < panelTop || position.y > panelTop + panelH) {
      return 'resume';
    }

    final localY = position.y - panelTop;

    if (localY >= 108 && localY <= 152) return 'resume';
    if (localY >= 168 && localY <= 212) return 'restart';
    if (localY >= 228 && localY <= 272) return 'quit';

    return null;
  }
}
