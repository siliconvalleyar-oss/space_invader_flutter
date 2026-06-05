import 'dart:async';
import 'dart:math';
import 'dart:ui' show Canvas, Paint, Color, Offset, Rect, RRect, Radius, MaskFilter, BlurStyle, PaintingStyle, TextDirection, FontWeight;
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;
import 'package:flame/components.dart';
import '../game/space_invaders_game.dart';

/// Level selection screen rendered as a Flame component.
/// Shows a grid of 7 levels with boss indicators and lock states.
class LevelSelect extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  double _animT = 0;
  double _scanlineOffset = 0;

  /// Level button rectangles for hit testing. Index = level 0-6.
  final List<Rect> levelRects = List.filled(7, Rect.zero);
  Rect backButtonRect = Rect.zero;

  static const double _titleY = 0.12;
  static const double _gridTopY = 0.26;
  static const double _backY = 0.88;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
    _scanlineOffset = (_scanlineOffset + dt * 120) % 4;
  }

  @override
  void render(Canvas canvas) {
    _drawScanlines(canvas);
    _drawTitle(canvas);
    _drawLevelGrid(canvas);
    _drawBackButton(canvas);
  }

  void _drawScanlines(Canvas canvas) {
    final paint = Paint()..color = const Color(0x08000000);
    for (double y = _scanlineOffset; y < size.y; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _drawTitle(Canvas canvas) {
    final cx = size.x / 2;
    final y = size.y * _titleY;

    final glow = Paint()
      ..color = const Color(0xFFFFAA44).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    _drawTextCentered(canvas, 'SELECT LEVEL', cx, y, 24, glow);

    final core = Paint()
      ..color = const Color(0xFFFFCC66).withValues(alpha: 0.9);
    _drawTextCentered(canvas, 'SELECT LEVEL', cx, y, 24, core);
  }

  void _drawLevelGrid(Canvas canvas) {
    final cx = size.x / 2;
    final cols = 3;
    final rows = 3; // 3 rows to fit 7 levels (last row has 1 item)
    final cellW = size.x / cols;
    final cellH = 60.0;

    for (int i = 0; i < 7; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final x = col * cellW + cellW / 2;
      final y = size.y * _gridTopY + row * (cellH + 10);

      _drawLevelButton(canvas, i, x, y, cellW - 16, cellH);
    }
  }

  void _drawLevelButton(Canvas canvas, int index, double cx, double cy, double w, double h) {
    final level = index + 1;
    final config = _levelConfig(index);
    final isBoss = config?.isBossLevel ?? false;
    final isLocked = index > gameRef.unlockedLevel;

    // Store hit rect
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    if (index < levelRects.length) levelRects[index] = rect;

    // Colors based on state
    final Color borderColor;
    final Color fillColor;
    final Color textColor;

    if (isLocked) {
      borderColor = const Color(0xFF334455);
      fillColor = const Color(0x11112244);
      textColor = const Color(0xFF445566);
    } else if (isBoss) {
      borderColor = const Color(0xFFFF6644);
      fillColor = const Color(0x22442200);
      textColor = const Color(0xFFFF8844);
    } else {
      borderColor = const Color(0xFF44AACC);
      fillColor = const Color(0x11004466);
      textColor = const Color(0xFF88CCDD);
    }

    // Button background
    final pulse = isLocked ? 0.0 : 0.3 + 0.2 * sin(_animT * 2 + index * 1.5);
    final bgPaint = Paint()
      ..color = fillColor.withValues(alpha: (fillColor.alpha / 255 + pulse * 0.3).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);

    // Border
    final borderAlpha = isLocked ? 0.4 : (0.6 + 0.3 * sin(_animT * 2.5 + index * 1.2));
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isBoss ? 2.0 : 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    // Level number
    final numPaint = Paint()
      ..color = textColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    _drawTextCentered(canvas, '$level', cx, cy - 6, 20, numPaint);

    // Boss indicator
    if (isBoss && !isLocked) {
      final bossPaint = Paint()
        ..color = const Color(0xFFFF6644).withValues(alpha: 0.6 + 0.3 * sin(_animT * 2 + index))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      _drawTextCentered(canvas, '👑 BOSS', cx, cy + 14, 10, bossPaint);
    }

    // Lock icon
    if (isLocked) {
      final lockPaint = Paint()
        ..color = const Color(0xFF445566).withValues(alpha: 0.7);
      _drawTextCentered(canvas, '🔒', cx, cy + 14, 14, lockPaint);
    }
  }

  void _drawBackButton(Canvas canvas) {
    final cx = size.x / 2;
    final y = size.y * _backY;
    final btnW = size.x * 0.4;
    final btnH = 40.0;

    backButtonRect = Rect.fromCenter(center: Offset(cx, y), width: btnW, height: btnH);

    final bgPaint = Paint()
      ..color = const Color(0x22223344).withValues(alpha: 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(backButtonRect, const Radius.circular(8)), bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF445566).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(backButtonRect, const Radius.circular(8)), borderPaint);

    final textPaint = Paint()
      ..color = const Color(0xFF88AACC).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    _drawTextCentered(canvas, '← BACK', cx, y + 4, 16, textPaint);
  }

  LevelConfig? _levelConfig(int index) {
    if (index < LevelConfig.levels.length) return LevelConfig.levels[index];
    return null;
  }

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

  /// Handle a tap at the given position. Returns true if handled.
  bool handleTap(Vector2 position) {
    final pos = Offset(position.x, position.y);

    // Check back button
    if (backButtonRect.contains(pos)) {
      gameRef.showMainMenu();
      return true;
    }

    // Check level buttons
    for (int i = 0; i < levelRects.length; i++) {
      if (levelRects[i].contains(pos)) {
        if (i <= gameRef.unlockedLevel) {
          gameRef.startLevelFromSelect(i);
          return true;
        }
        // Locked level — play a sound or haptic
        return true;
      }
    }

    return false;
  }
}
