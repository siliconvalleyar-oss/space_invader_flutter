import 'dart:ui' show Canvas, Paint, Color, Offset, Rect;
import 'package:flame/components.dart';

/// Phases of the screen transition animation.
enum TransitionPhase { fadeOut, switching, fadeIn, idle }

/// Full-screen overlay that fades to black and back to create smooth
/// transitions between menu, level select, and gameplay screens.
class ScreenTransition extends PositionComponent {
  double _animT = 0;
  TransitionPhase _phase = TransitionPhase.idle;
  double _alpha = 0;

  static const double fadeDuration = 0.2;

  /// Callback executed exactly when the screen is fully black (mid-transition).
  void Function()? onSwitch;

  bool get isActive => _phase != TransitionPhase.idle;

  /// Start a transition: fade out → execute callback → fade in.
  void start(void Function() switchAction) {
    _phase = TransitionPhase.fadeOut;
    _animT = 0;
    _alpha = 0;
    onSwitch = switchAction;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_phase == TransitionPhase.idle) return;

    _animT += dt;

    switch (_phase) {
      case TransitionPhase.fadeOut:
        _alpha = (_animT / fadeDuration).clamp(0.0, 1.0);
        if (_alpha >= 1.0) {
          _phase = TransitionPhase.switching;
          _animT = 0;
          // Execute the screen switch
          onSwitch?.call();
          onSwitch = null;
        }
        break;

      case TransitionPhase.switching:
        // Brief pause at full black
        if (_animT >= 0.05) {
          _phase = TransitionPhase.fadeIn;
          _animT = 0;
        }
        break;

      case TransitionPhase.fadeIn:
        _alpha = 1.0 - (_animT / fadeDuration).clamp(0.0, 1.0);
        if (_alpha <= 0.0) {
          _phase = TransitionPhase.idle;
          _alpha = 0;
        }
        break;

      case TransitionPhase.idle:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_phase == TransitionPhase.idle && _alpha <= 0) return;

    final overlay = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: _alpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlay);
  }
}
