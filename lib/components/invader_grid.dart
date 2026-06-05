import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_invaders_game.dart';
import 'enemy.dart';

enum GridDirection { right, down, left }

/// Manages the grid formation of enemy invaders with smooth continuous movement.
class InvaderGrid extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  final int columns;
  final int rows;
  final List<Enemy> enemies = [];

  /// Whether enemy movement is frozen by a power-up.
  bool _frozen = false;
  bool get frozen => _frozen;
  set frozen(bool value) {
    _frozen = value;
    // Propagate frozen state to all enemies for visual effect
    for (final enemy in enemies) {
      enemy.frozen = value;
    }
  }

  GridDirection _currentDirection = GridDirection.right;
  GridDirection _lastHorizontal = GridDirection.right;

  double _moveTimer = 0.0;
  double _moveInterval;
  double _fireTimer = 0.0;
  double _fireInterval;
  double _stepSize;

  double _leftBound = 40;
  double _rightBound = 0;

  /// For smooth movement: how long to spend moving down per phase
  static const double _downPhaseRatio = 0.25;

  InvaderGrid({
    required this.columns,
    required this.rows,
    double moveInterval = 0.8,
    double fireInterval = 1.2,
    double stepSize = 20,
  })  : _moveInterval = moveInterval,
        _fireInterval = fireInterval,
        _stepSize = stepSize;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    _rightBound = gameRef.size.x - 40;

    final spacingX = 40.0;
    final spacingY = 35.0;
    final gridWidth = (columns - 1) * spacingX;

    for (int row = 0; row < rows; row++) {
      final spriteType = row % 3;
      for (int col = 0; col < columns; col++) {
        final enemy = Enemy(row: row, col: col, type: spriteType);
        enemy.position = Vector2(
          col * spacingX - gridWidth / 2,
          row * spacingY - ((rows - 1) * spacingY) / 2,
        );
        enemy.visible = true;
        enemies.add(enemy);
        add(enemy);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isGameStarted || gameRef.isGameOver) return;

    // Freeze: don't move, but still allow firing
    if (frozen) {
      _fireTimer += dt;
      // While frozen, enemies fire more often (panic!)
      final activeEnemies = enemies.where((e) => e.visible).length;
      final totalEnemies = columns * rows;
      final speedFactor = 1.0 + (1.0 - activeEnemies / totalEnemies) * 0.5;
      if (_fireTimer >= (_fireInterval * 0.7) / speedFactor) {
        _fireTimer = 0.0;
        _fireFromLowestRow();
      }
      return;
    }

    final activeEnemies = enemies.where((e) => e.visible).length;
    final totalEnemies = columns * rows;
    final speedFactor = 1.0 + (1.0 - activeEnemies / totalEnemies) * 0.5;
    final adjustedInterval = _moveInterval / speedFactor;

    // Calculate smooth velocities
    final horizontalSpeed = _stepSize / adjustedInterval; // px/s
    final downSpeed = _stepSize / (adjustedInterval * _downPhaseRatio); // faster descent

    switch (_currentDirection) {
      case GridDirection.right:
        position.x += horizontalSpeed * dt;
        if (_rightmostEnemyX() >= _rightBound) {
          position.x = _rightBound - _rightmostEnemyX() + position.x;
          _currentDirection = GridDirection.down;
          _lastHorizontal = GridDirection.right;
          _moveTimer = 0.0;
        }
        break;

      case GridDirection.left:
        position.x -= horizontalSpeed * dt;
        if (_leftmostEnemyX() <= _leftBound) {
          position.x = _leftBound - _leftmostEnemyX() + position.x;
          _currentDirection = GridDirection.down;
          _lastHorizontal = GridDirection.left;
          _moveTimer = 0.0;
        }
        break;

      case GridDirection.down:
        position.y += downSpeed * dt;
        _moveTimer += dt;
        if (_moveTimer >= adjustedInterval * _downPhaseRatio) {
          _moveTimer = 0.0;
          _currentDirection = (_lastHorizontal == GridDirection.right)
              ? GridDirection.left
              : GridDirection.right;
        }
        break;
    }

    // Enemy firing (unchanged, with rate adjustment)
    _fireTimer += dt;
    if (_fireTimer >= _fireInterval / speedFactor) {
      _fireTimer = 0.0;
      _fireFromLowestRow();
    }
  }

  /// Fire a bullet from the lowest visible enemy in a random column.
  void _fireFromLowestRow() {
    final columnLowest = <int, Enemy>{};
    for (final enemy in enemies) {
      if (!enemy.visible) continue;
      final current = columnLowest[enemy.col];
      if (current == null || enemy.row > current.row) {
        columnLowest[enemy.col] = enemy;
      }
    }

    if (columnLowest.isNotEmpty) {
      final randomCol = columnLowest.keys.elementAt(
        Random().nextInt(columnLowest.length),
      );
      final shooter = columnLowest[randomCol]!;
      final globalPos = shooter.position + position;
      gameRef.spawnEnemyBullet(globalPos);
    }
  }

  double _rightmostEnemyX() {
    double maxX = double.negativeInfinity;
    for (final enemy in enemies) {
      if (!enemy.visible) continue;
      final worldX = position.x + enemy.position.x + enemy.size.x / 2;
      if (worldX > maxX) maxX = worldX;
    }
    return maxX;
  }

  double _leftmostEnemyX() {
    double minX = double.infinity;
    for (final enemy in enemies) {
      if (!enemy.visible) continue;
      final worldX = position.x + enemy.position.x - enemy.size.x / 2;
      if (worldX < minX) minX = worldX;
    }
    return minX == double.infinity ? 0 : minX;
  }

  bool get allDestroyed => enemies.every((e) => !e.visible);

  void reset() {
    position = Vector2(gameRef.size.x / 2, 80);
    _currentDirection = GridDirection.right;
    _lastHorizontal = GridDirection.right;
    _moveTimer = 0.0;
    _fireTimer = 0.0;

    final spacingX = 40.0;
    final spacingY = 35.0;
    final gridWidth = (columns - 1) * spacingX;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final idx = row * columns + col;
        if (idx < enemies.length) {
          enemies[idx].position = Vector2(
            col * spacingX - gridWidth / 2,
            row * spacingY - ((rows - 1) * spacingY) / 2,
          );
          enemies[idx].hitPoints = 2;
          enemies[idx].visible = true;
        }
      }
    }
  }
}
