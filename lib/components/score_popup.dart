import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ScorePopup extends TextComponent {
  final double _startY;
  double _life = 0;
  static const double _duration = 1.2;
  bool visible = true;

  ScorePopup({
    required Vector2 position,
    required String text,
    Color color = Colors.yellowAccent,
  }) : _startY = position.y,
       super(
         text: text,
         textRenderer: TextPaint(
           style: TextStyle(
             fontFamily: 'monospace',
             fontSize: 16,
             fontWeight: FontWeight.bold,
             color: color,
             shadows: [
               Shadow(color: Colors.black87, blurRadius: 4),
               Shadow(color: Colors.black54, blurRadius: 8),
             ],
           ),
         ),
         position: position,
         anchor: Anchor.center,
         priority: 150,
       );

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    final progress = (_life / _duration).clamp(0.0, 1.0);
    position.y = _startY - 50 * progress;
    if (_life >= _duration) {
      visible = false;
      removeFromParent();
    }
  }
}
