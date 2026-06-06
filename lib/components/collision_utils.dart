import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Pre-computed alpha map for a sprite image.
/// Stores whether each pixel is visible (alpha > threshold).
class AlphaMap {
  final ui.Image image;
  final List<bool> _alpha;
  final int width;
  final int height;

  AlphaMap._(this.image, this._alpha, this.width, this.height);

  /// Build alpha map from a sprite's image.
  /// Reads pixel data and marks pixels with alpha > 10 as visible.
  static Future<AlphaMap> fromSprite(Sprite sprite) async {
    final image = sprite.image;
    final byteData = await image.toByteData();
    if (byteData == null) {
      return AlphaMap._(image, List.filled(image.width * image.height, true), image.width, image.height);
    }

    final pixels = byteData.buffer.asUint8List();
    final w = image.width;
    final h = image.height;
    final alpha = List<bool>.generate(w * h, (i) {
      // Pixel format is RGBA, alpha is at offset 3
      return pixels[i * 4 + 3] > 10;
    });

    return AlphaMap._(image, alpha, w, h);
  }

  bool isOpaque(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return _alpha[y * width + x];
  }
}

/// Utility for alpha-channel based pixel-perfect collision detection.
class CollisionUtils {
  /// Check if two sprites overlap based on their visible (non-transparent) pixels.
  ///
  /// First checks bounding box overlap (fast reject), then checks
  /// individual pixels in the overlapping region using pre-computed alpha maps.
  /// Uses step sampling (check every nth pixel) for performance.
  static bool checkAlphaCollision(
    PositionComponent a, AlphaMap alphaA,
    PositionComponent b, AlphaMap alphaB, {
    int step = 2,
  }) {
    final rectA = a.toAbsoluteRect();
    final rectB = b.toAbsoluteRect();

    // Fast bounding box check
    final overlap = rectA.intersect(rectB);
    if (overlap.isEmpty) return false;

    final scaleAX = alphaA.width / rectA.width;
    final scaleAY = alphaA.height / rectA.height;
    final scaleBX = alphaB.width / rectB.width;
    final scaleBY = alphaB.height / rectB.height;

    final startX = overlap.left.toInt();
    final startY = overlap.top.toInt();
    final endX = overlap.right.toInt();
    final endY = overlap.bottom.toInt();

    // Check pixels in overlap region with step sampling
    for (int y = startY; y < endY; y += step) {
      for (int x = startX; x < endX; x += step) {
        // Map overlap pixel to sprite A coordinates
        final ax = ((x - rectA.left) * scaleAX).round();
        final ay = ((y - rectA.top) * scaleAY).round();
        // Map overlap pixel to sprite B coordinates
        final bx = ((x - rectB.left) * scaleBX).round();
        final by = ((y - rectB.top) * scaleBY).round();

        if (alphaA.isOpaque(ax, ay) && alphaB.isOpaque(bx, by)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Simplified collision for small projectiles (bullets).
  /// Uses bounding box with scaled-down rect for better feel.
  static bool checkBulletCollision(
    PositionComponent bullet,
    PositionComponent target, {
    double shrink = 0.3,
  }) {
    final bulletRect = bullet.toAbsoluteRect();
    final targetRect = target.toAbsoluteRect();

    final shrunkTarget = targetRect.deflate(
      targetRect.shortestSide * shrink,
    );

    return bulletRect.overlaps(shrunkTarget);
  }
}
