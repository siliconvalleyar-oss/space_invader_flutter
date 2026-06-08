import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_invaders_game.dart';
import 'enemy.dart';

enum GridDirection { right, down, left }

/// Per-enemy state for swarm movement.
class _SwarmState {
  double phase;
  double amplitude;
  double driftSpeed;
  double diveTimer;
  double diveCooldown;
  bool isDiving;
  double baseX;

  _SwarmState({
    required this.phase,
    required this.amplitude,
    required this.driftSpeed,
    required this.diveTimer,
    this.diveCooldown = 0,
    this.isDiving = false,
    required this.baseX,
  });
}

/// Manages the grid formation of enemy invaders with smooth continuous movement.
class InvaderGrid extends PositionComponent with HasGameRef<SpaceInvadersGame> {
  final int columns;
  final int rows;
  final List<Enemy> enemies = [];
  final bool isSwarm;

  /// Whether enemy movement is frozen by a power-up.
  bool _frozen = false;
  bool get frozen => _frozen;
  set frozen(bool value) {
    _frozen = value;
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

  static const double _downPhaseRatio = 0.25;

  final Map<Enemy, _SwarmState> _swarmStates = {};
  final Random _rng = Random();

  InvaderGrid({
    required this.columns,
    required this.rows,
    double moveInterval = 0.8,
    double fireInterval = 1.2,
    double stepSize = 20,
    this.isSwarm = false,
  })  : _moveInterval = moveInterval,
        _fireInterval = fireInterval,
        _stepSize = stepSize;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    _rightBound = gameRef.size.x - 40;

    if (isSwarm) {
      _initSwarm();
    } else {
      _initGrid();
    }
  }

  void _initGrid() {
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

  void _initSwarm() {
    for (int i = 0; i < columns * rows; i++) {
      final enemy = Enemy(row: 0, col: i, type: _rng.nextInt(3));
      enemy.hitPoints = 1;
      final x = 30 + _rng.nextDouble() * (gameRef.size.x - 60);
      final y = -20 - _rng.nextDouble() * 200 - (i * 30);
      enemy.position = Vector2(x, y);
      enemy.visible = true;
      enemies.add(enemy);
      add(enemy);
      _swarmStates[enemy] = _SwarmState(
        phase: _rng.nextDouble() * 2 * pi,
        amplitude: 20 + _rng.nextDouble() * 30,
        driftSpeed: 25 + _rng.nextDouble() * 35,
        diveTimer: 2.5 + _rng.nextDouble() * 3,
        baseX: x,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isGameStarted || gameRef.isGameOver) return;

    if (isSwarm) {
      _updateSwarm(dt);
    } else {
      _updateGrid(dt);
    }
  }

  void _updateGrid(double dt) {
    if (frozen) {
      _fireTimer += dt;
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

    final horizontalSpeed = _stepSize / adjustedInterval;
    final downSpeed = _stepSize / (adjustedInterval * _downPhaseRatio);

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

    _fireTimer += dt;
    if (_fireTimer >= _fireInterval / speedFactor) {
      _fireTimer = 0.0;
      _fireFromLowestRow();
    }
  }

  void _updateSwarm(double dt) {
    if (frozen) {
      _fireTimer += dt;
      if (_fireTimer >= _fireInterval * 0.5) {
        _fireTimer = 0.0;
        _fireRandomEnemy();
      }
      return;
    }

    final playerX = gameRef.player.position.x;

    for (final enemy in enemies) {
      if (!enemy.visible) continue;
      final state = _swarmStates[enemy];
      if (state == null) continue;

      if (state.isDiving) {
        state.diveCooldown -= dt;
        final dx = playerX - enemy.position.x;
        enemy.position.x += dx.sign * 180 * dt;
        enemy.position.y += 120 * dt;
        if (state.diveCooldown <= 0 || enemy.position.y > gameRef.size.y + 40) {
          state.isDiving = false;
          state.baseX = 30 + _rng.nextDouble() * (gameRef.size.x - 60);
          enemy.position = Vector2(state.baseX, -20 - _rng.nextDouble() * 40);
        }
      } else {
        state.phase += dt * 1.5;
        state.diveCooldown += dt;
        final sway = sin(state.phase) * 60 * dt;
        enemy.position.x += sway;
        enemy.position.y += state.driftSpeed * dt;
        enemy.position.x = enemy.position.x.clamp(15, gameRef.size.x - 15);

        if (enemy.position.y > gameRef.size.y + 30) {
          state.baseX = 30 + _rng.nextDouble() * (gameRef.size.x - 60);
          enemy.position = Vector2(state.baseX, -20 - _rng.nextDouble() * 50);
        }

        if (state.diveCooldown >= state.diveTimer) {
          state.isDiving = true;
          state.diveCooldown = 0;
          state.diveTimer = 2.5 + _rng.nextDouble() * 3;
        }
      }
    }

    _fireTimer += dt;
    if (_fireTimer >= _fireInterval * 0.6) {
      _fireTimer = 0.0;
      _fireRandomEnemy();
    }
  }

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

  void _fireRandomEnemy() {
    final visible = enemies.where((e) => e.visible).toList();
    if (visible.isEmpty) return;
    final shooter = visible[_rng.nextInt(visible.length)];
    gameRef.spawnEnemyBullet(shooter.position + position);
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
    _swarmStates.clear();

    if (isSwarm) {
      _resetSwarm();
    } else {
      _resetGrid();
    }
  }

  void _resetGrid() {
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

  void _resetSwarm() {
    for (int i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      enemy.hitPoints = 1;
      final x = 30 + _rng.nextDouble() * (gameRef.size.x - 60);
      final y = -20 - _rng.nextDouble() * 50;
      enemy.position = Vector2(x, y);
      enemy.visible = true;
      _swarmStates[enemy] = _SwarmState(
        phase: _rng.nextDouble() * 2 * pi,
        amplitude: 20 + _rng.nextDouble() * 30,
        driftSpeed: 25 + _rng.nextDouble() * 35,
        diveTimer: 2.5 + _rng.nextDouble() * 3,
        baseX: x,
      );
    }
  }
}
