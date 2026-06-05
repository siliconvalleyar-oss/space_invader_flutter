import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import '../components/player.dart';
import '../components/invader_grid.dart';
import '../components/bullet.dart';
import '../components/enemy.dart';
import '../components/explosion.dart';
import '../components/starfield.dart';
import '../components/collision_utils.dart';
import '../components/power_up.dart';
import '../components/main_menu.dart';
import '../components/level_select.dart';
import '../components/screen_transition.dart';
import '../utils/high_score_manager.dart';

/// Level configuration for progressive difficulty.
class LevelConfig {
  final int level;
  final int gridColumns;
  final int gridRows;
  final double moveInterval;
  final double fireInterval;
  final double stepSize;
  final bool isBossLevel;
  final int bossHp;

  const LevelConfig({
    required this.level,
    this.gridColumns = 5,
    this.gridRows = 3,
    this.moveInterval = 0.8,
    this.fireInterval = 1.2,
    this.stepSize = 20,
    this.isBossLevel = false,
    this.bossHp = 10,
  });

  static const List<LevelConfig> levels = [
    LevelConfig(level: 1, gridColumns: 5, gridRows: 3, moveInterval: 0.8, fireInterval: 1.2, stepSize: 20),
    LevelConfig(level: 2, gridColumns: 6, gridRows: 3, moveInterval: 0.7, fireInterval: 1.0, stepSize: 22),
    LevelConfig(level: 3, gridColumns: 6, gridRows: 4, moveInterval: 0.6, fireInterval: 0.9, stepSize: 24),
    LevelConfig(level: 4, gridColumns: 7, gridRows: 4, moveInterval: 0.5, fireInterval: 0.8, stepSize: 26),
    LevelConfig(level: 5, gridColumns: 5, gridRows: 3, moveInterval: 0.7, fireInterval: 1.0, stepSize: 22, isBossLevel: true, bossHp: 15),
    LevelConfig(level: 6, gridColumns: 6, gridRows: 4, moveInterval: 0.45, fireInterval: 0.7, stepSize: 28),
    LevelConfig(level: 7, gridColumns: 7, gridRows: 5, moveInterval: 0.4, fireInterval: 0.6, stepSize: 30),
  ];
}

/// Game state machine.
enum GameState { menu, levelSelect, playing }

/// Main Space Invaders game class.
class SpaceInvadersGame extends FlameGame with KeyboardEvents {
  late Player player;
  InvaderGrid? invaderGrid;
  Boss? boss;
  late Starfield starfield;

  // Alpha maps for pixel-perfect collision
  AlphaMap? _playerAlpha;
  final Map<Enemy, AlphaMap> _enemyAlphas = {};
  AlphaMap? _bossAlpha;

  int score = 0;
  int lives = 3;
  int currentLevel = 0;
  bool isTransitioning = false;

  double invulnerabilityTimer = 0.0;
  static const double invulnerabilityDuration = 1.0;

  double fireTimer = 0.0;
  static const double fireCooldown = 0.2;
  bool _gameJustStarted = true;

  // Power-up state
  double shieldTimer = 0.0;
  double tripleShotTimer = 0.0;
  double freezeTimer = 0.0;
  double spreadShotTimer = 0.0;
  static const double powerUpDuration = 6.0;
  final List<PowerUp> _powerUps = [];

  final List<Bullet> playerBullets = [];
  final List<Bullet> enemyBullets = [];

  TextComponent? scoreText;
  TextComponent? livesText;
  TextComponent? levelText;
  TextComponent? highScoreText;
  TextComponent? powerUpHud;
  TextComponent? gameOverText;
  bool isGameOver = false;
  bool isGameStarted = false;

  // Game state management
  GameState _gameState = GameState.menu;
  int unlockedLevel = 0;
  late MainMenu mainMenu;
  late LevelSelect levelSelect;
  late ScreenTransition _screenTransition;
  int get highScore => HighScoreManager.highScore;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Load high score
    await HighScoreManager.load();

    // Starfield background
    starfield = Starfield();
    starfield.priority = -100;
    add(starfield);

    // Player (hidden until game starts)
    player = Player();
    player.position = Vector2(size.x / 2, size.y - 80);
    player.priority = 50;
    player.visible = false;
    add(player);

    // Precompute player alpha map
    try {
      if (player.sprite != null) {
        _playerAlpha = await AlphaMap.fromSprite(player.sprite!);
      }
    } catch (_) {}

    // Score HUD
    scoreText = TextComponent(
      text: 'SCORE: 0',
      textRenderer: _buildTextRenderer(Colors.cyanAccent),
      position: Vector2(10, 10),
      priority: 100,
    );
    add(scoreText!);

    // Lives HUD
    livesText = TextComponent(
      text: 'LIVES: 3',
      textRenderer: _buildTextRenderer(Colors.orangeAccent),
      position: Vector2(size.x - 120, 10),
      priority: 100,
    );
    add(livesText!);

    // Level HUD
    levelText = TextComponent(
      text: 'LEVEL 1',
      textRenderer: _buildTextRenderer(Colors.amberAccent, 16),
      position: Vector2(size.x / 2, 10),
      anchor: Anchor.topCenter,
      priority: 100,
    );
    add(levelText!);

    // High Score HUD (below score)
    highScoreText = TextComponent(
      text: '',
      textRenderer: _buildTextRenderer(Colors.purpleAccent, 14),
      position: Vector2(10, 32),
      priority: 100,
    );
    add(highScoreText!);

    // Power-up HUD
    powerUpHud = TextComponent(
      text: '',
      textRenderer: _buildTextRenderer(Colors.white70, 12),
      position: Vector2(10, 52),
      priority: 100,
    );
    add(powerUpHud!);

    // Pre-create level (hidden behind menu) so everything is ready when game starts
    invaderGrid = null;
    boss = null;
    _startLevel(0);

    // Game Over text
    gameOverText = TextComponent(
      text: '',
      textRenderer: _buildTextRenderer(Colors.redAccent, 36),
      position: Vector2(size.x / 2, size.y / 2 - 20),
      anchor: Anchor.center,
      priority: 200,
    );
    add(gameOverText!);

    // Main menu (shown first) — hides the pre-created level
    mainMenu = MainMenu()
      ..size = size
      ..priority = 500;
    add(mainMenu);

    // Level select (hidden until called)
    levelSelect = LevelSelect()
      ..size = size
      ..priority = 500;

    // Screen transition overlay (idle until used)
    _screenTransition = ScreenTransition()
      ..size = size
      ..priority = 600;
    add(_screenTransition);

    // Hide player until game starts
    player.visible = false;
  }

  TextPaint _buildTextRenderer(Color color, [double size = 20]) {
    return TextPaint(
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(color: color.withValues(alpha: 0.8), blurRadius: 8),
          Shadow(color: color.withValues(alpha: 0.4), blurRadius: 16),
        ],
      ),
    );
  }

  void _startLevel(int levelIndex) {
    currentLevel = levelIndex;
    final config = LevelConfig.levels[levelIndex.clamp(0, LevelConfig.levels.length - 1)];

    if (invaderGrid != null) { remove(invaderGrid!); invaderGrid = null; }
    if (boss != null) { remove(boss!); boss = null; }
    _enemyAlphas.clear();
    _bossAlpha = null;

    if (config.isBossLevel) {
      boss = Boss(maxHp: config.bossHp);
      boss!.position = Vector2(size.x / 2, 60);
      boss!.priority = 40;
      add(boss!);
      // Compute boss alpha map after load
      Future.delayed(const Duration(milliseconds: 100), () async {
        if (boss != null && boss!.sprite != null) {
          _bossAlpha = await AlphaMap.fromSprite(boss!.sprite!);
        }
      });
      invaderGrid = InvaderGrid(
        columns: 3, rows: 2,
        moveInterval: config.moveInterval * 1.3,
        fireInterval: config.fireInterval * 1.5,
        stepSize: config.stepSize,
      );
      invaderGrid!.position = Vector2(size.x / 2, 140);
      invaderGrid!.priority = 30;
      add(invaderGrid!);
    } else {
      invaderGrid = InvaderGrid(
        columns: config.gridColumns, rows: config.gridRows,
        moveInterval: config.moveInterval,
        fireInterval: config.fireInterval,
        stepSize: config.stepSize,
      );
      invaderGrid!.position = Vector2(size.x / 2, 80);
      invaderGrid!.priority = 30;
      add(invaderGrid!);
    }

    // Compute enemy alpha maps after they load
    Future.delayed(const Duration(milliseconds: 200), () async {
      for (final enemy in (invaderGrid?.enemies ?? [])) {
        if (enemy.sprite != null && !_enemyAlphas.containsKey(enemy)) {
          _enemyAlphas[enemy] = await AlphaMap.fromSprite(enemy.sprite!);
        }
      }
    });

    levelText?.text = 'LEVEL ${config.level}';
    starfield.setSpeedLevel(config.level);
    isTransitioning = false;
  }

  void _nextLevel() {
    _screenTransition.start(() {
      _clearBullets();
      final nextIndex = currentLevel + 1;
      if (nextIndex >= LevelConfig.levels.length) {
        _triggerVictory();
        return;
      }
      // Reset power-up timers on level transition for fairness
      freezeTimer = 0.0;
      shieldTimer = 0.0;
      tripleShotTimer = 0.0;
      spreadShotTimer = 0.0;
      player.shieldActive = false;
      _playSound('level_up.wav');
      _startLevel(nextIndex);
    });
  }

  void _triggerVictory() {
    isGameOver = true;
    final oldHS = HighScoreManager.highScore;
    HighScoreManager.tryUpdate(score);
    final isNew = score > oldHS;
    final hsText = isNew ? '\n🏆 NEW HIGH SCORE!' : '\nHI: ${HighScoreManager.highScore}';
    gameOverText?.text = '🎉 VICTORY!\n\nScore: $score$hsText\n\nTap to Play Again';
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameState != GameState.playing || isGameOver || isTransitioning) return;

    // Auto-fire
    fireTimer += dt;
    if (fireTimer >= fireCooldown && player.visible) {
      fireTimer = 0.0;
      _spawnPlayerBullet(playSound: _gameJustStarted);
      _gameJustStarted = false;
    }

    // Invulnerability timer
    if (invulnerabilityTimer > 0) {
      invulnerabilityTimer -= dt;
      player.visible = (invulnerabilityTimer * 10).toInt() % 2 == 0;
      if (invulnerabilityTimer <= 0) player.visible = true;
    }

    // Power-up timers
    if (shieldTimer > 0) {
      shieldTimer -= dt;
      player.shieldActive = shieldTimer > 0;
      if (shieldTimer <= 0) player.shieldActive = false;
    }
    if (tripleShotTimer > 0) {
      tripleShotTimer -= dt;
    }
    if (freezeTimer > 0) {
      freezeTimer -= dt;
      if (freezeTimer <= 0) {
        if (invaderGrid != null) invaderGrid!.frozen = false;
        if (boss != null) boss!.frozen = false;
      }
    }
    if (spreadShotTimer > 0) {
      spreadShotTimer -= dt;
    }
    // Clean up collected/expired power-ups
    _powerUps.removeWhere((p) => !p.visible);

    _checkCollisions();
    _checkGameOver();
    _checkLevelComplete();

    scoreText?.text = 'SCORE: $score';
    livesText?.text = 'LIVES: $lives';
    _updatePowerUpHud();
  }

  void _checkCollisions() {
    // Player bullets vs enemies (alpha collision)
    for (final bullet in playerBullets.toList()) {
      if (!bullet.visible) continue;
      bool hit = false;

      if (invaderGrid != null) {
        for (final enemy in invaderGrid!.enemies.toList()) {
          if (!enemy.visible) continue;

          // Check alpha collision if alpha map exists, otherwise bounding box
          bool collision = false;
          final enemyAlpha = _enemyAlphas[enemy];
          if (enemyAlpha != null && _playerAlpha != null) {
            collision = CollisionUtils.checkAlphaCollision(bullet, _playerAlpha!, enemy, enemyAlpha, step: 1);
          } else {
            collision = bullet.toRect().overlaps(enemy.toRect());
          }

          if (collision) {
            bullet.removeFromParent();
            playerBullets.remove(bullet);
            enemy.takeDamage();
            if (!enemy.visible) {
              score += 10;
              _spawnExplosion(enemy.position + (invaderGrid?.position ?? Vector2.zero()), const Color(0xFFFF6644));
              _playSound('explosion.wav');
              HapticFeedback.lightImpact();
              _maybeSpawnPowerUp(enemy.position + (invaderGrid?.position ?? Vector2.zero()));
            }
            hit = true;
            break;
          }
        }
      }

      if (!hit && boss != null && boss!.visible && bullet.visible) {
        bool collision = false;
        if (_bossAlpha != null && _playerAlpha != null) {
          collision = CollisionUtils.checkAlphaCollision(bullet, _playerAlpha!, boss!, _bossAlpha!, step: 1);
        } else {
          collision = bullet.toRect().overlaps(boss!.toRect());
        }

        if (collision) {
          bullet.removeFromParent();
          playerBullets.remove(bullet);
          boss!.takeDamage();
          if (!boss!.visible) {
            score += 50;
            _spawnExplosion(boss!.position, const Color(0xFFFFAA00));
            _spawnExplosion(boss!.position + Vector2(-15, -10), const Color(0xFFFF6644));
            _spawnExplosion(boss!.position + Vector2(15, 10), const Color(0xFFFFAA00));
            _playSound('explosion.wav');
            HapticFeedback.heavyImpact();
          }
        }
      }
    }

    // Enemy bullets vs player (bounding box with shrink for performance)
    for (final bullet in enemyBullets.toList()) {
      if (!bullet.visible || !player.visible) continue;

      final collision = CollisionUtils.checkBulletCollision(bullet, player, shrink: 0.2);

      if (collision) {
        bullet.removeFromParent();
        enemyBullets.remove(bullet);
        // Shield absorbs damage
        if (shieldTimer > 0) {
          _spawnExplosion(player.position, const Color(0xFF44AAFF));
          _playSound('player_hit.wav');
          continue;
        }
        if (invulnerabilityTimer <= 0) {
          lives--;
          invulnerabilityTimer = invulnerabilityDuration;
          _playSound('player_hit.wav');
          HapticFeedback.mediumImpact();
          _spawnExplosion(player.position, const Color(0xFFFF2200));
          for (final eb in enemyBullets.toList()) { eb.removeFromParent(); enemyBullets.remove(eb); }
          if (lives <= 0) _triggerGameOver();
        }
      }
    }

    // Power-ups vs player collection
    for (final pu in _powerUps.toList()) {
      if (!pu.visible || !player.visible) continue;
      if (pu.toRect().overlaps(player.toRect())) {
        _collectPowerUp(pu);
        pu.removeFromParent();
        _powerUps.remove(pu);
      }
    }

    playerBullets.removeWhere((b) => !b.visible);
    enemyBullets.removeWhere((b) => !b.visible);
  }

  void _spawnPlayerBullet({bool playSound = true}) {
    if (playSound) {
      _playSound('shoot.wav');
      HapticFeedback.selectionClick();
    }

    if (spreadShotTimer > 0) {
      // Spread shot: 5 bullets in wide fan
      final offsets = [-24.0, -12.0, 0.0, 12.0, 24.0];
      for (final offset in offsets) {
        final bullet = Bullet(
          position: Vector2(player.position.x + offset, player.position.y - 20),
          isPlayerBullet: true,
        );
        bullet.priority = 60;
        playerBullets.add(bullet);
        add(bullet);
      }
    } else if (tripleShotTimer > 0) {
      // Triple shot: 3 bullets in spread pattern
      final offsets = [-12.0, 0.0, 12.0];
      for (final offset in offsets) {
        final bullet = Bullet(
          position: Vector2(player.position.x + offset, player.position.y - 20),
          isPlayerBullet: true,
        );
        bullet.priority = 60;
        playerBullets.add(bullet);
        add(bullet);
      }
    } else {
      final bullet = Bullet(
        position: Vector2(player.position.x, player.position.y - 20),
        isPlayerBullet: true,
      );
      bullet.priority = 60;
      playerBullets.add(bullet);
      add(bullet);
    }
  }

  void spawnEnemyBullet(Vector2 position) {
    final bullet = Bullet(
      position: Vector2(position.x, position.y + 10),
      isPlayerBullet: false,
    );
    bullet.priority = 60;
    enemyBullets.add(bullet);
    add(bullet);
  }

  void _spawnExplosion(Vector2 position, Color color) {
    final explosion = Explosion(
      position: position,
      color: color,
      particleCount: 12,
      duration: 0.5,
    );
    explosion.priority = 70;
    add(explosion);
  }

  /// Spawn a power-up when an enemy is destroyed.
  /// Chance decreases in higher levels for balanced difficulty.
  void _maybeSpawnPowerUp(Vector2 position) {
    final chance = _powerUpChance();
    if (Random().nextDouble() > chance) return;

    final types = [
      PowerUpType.shield, PowerUpType.triple, PowerUpType.extraLife,
      PowerUpType.freeze, PowerUpType.spread, PowerUpType.bomb,
    ];
    final type = types[Random().nextInt(types.length)];

    final pu = PowerUp(position: position, type: type);
    pu.priority = 65;
    _powerUps.add(pu);
    add(pu);
  }

  /// Returns power-up spawn probability based on current level.
  /// Higher levels = lower chance (more challenge, more rewarding).
  double _powerUpChance() {
    return (0.28 - currentLevel * 0.025).clamp(0.10, 0.28);
  }

  /// Handle power-up collection by the player.
  void _collectPowerUp(PowerUp pu) {
    _playPowerUpSound(pu.type);
    HapticFeedback.lightImpact();

    switch (pu.type) {
      case PowerUpType.shield:
        shieldTimer = powerUpDuration;
        player.shieldActive = true;
        _showPowerUpLabel('SHIELD', const Color(0xFF44AAFF));
        break;
      case PowerUpType.triple:
        tripleShotTimer = powerUpDuration;
        _showPowerUpLabel('TRIPLE', const Color(0xFFFFAA00));
        break;
      case PowerUpType.extraLife:
        lives++;
        _showPowerUpLabel('+1 UP', const Color(0xFF44FF44));
        livesText?.text = 'LIVES: $lives';
        break;
      case PowerUpType.freeze:
        freezeTimer = powerUpDuration;
        if (invaderGrid != null) invaderGrid!.frozen = true;
        if (boss != null) boss!.frozen = true;
        _showPowerUpLabel('❄️ FREEZE', const Color(0xFF88CCFF));
        break;
      case PowerUpType.spread:
        spreadShotTimer = powerUpDuration;
        _showPowerUpLabel('🔥 SPREAD', const Color(0xFFFF8800));
        break;
      case PowerUpType.bomb:
        _activateBomb();
        _showPowerUpLabel('💥 BOMB', const Color(0xFFFF2200));
        break;
    }
  }

  /// Start a new game from the main menu (level 0).
  void startGameFromMenu() {
    _screenTransition.start(() {
      _playSound('shoot.wav');
      _gameState = GameState.playing;
      remove(mainMenu);
      _doStartGame();
    });
  }

  /// Show the level select screen.
  void showLevelSelect() {
    _screenTransition.start(() {
      _playSound('level_up.wav');
      _gameState = GameState.levelSelect;
      remove(mainMenu);
      add(levelSelect);
    });
  }

  /// Return to the main menu.
  void showMainMenu() {
    _screenTransition.start(() {
      _playSound('shoot.wav');
      _gameState = GameState.menu;
      remove(levelSelect);
      add(mainMenu);
    });
  }

  /// Start a game from the level select at a specific level.
  void startLevelFromSelect(int levelIndex) {
    _screenTransition.start(() {
      _playSound('shoot.wav');
      _gameState = GameState.playing;
      remove(levelSelect);
      _doStartGame();
      // Override to start at selected level
      currentLevel = levelIndex;
      _startLevel(levelIndex);
    });
  }

  /// Internal: set up the game for playing.
  void _doStartGame() {
    isGameStarted = true;
    player.visible = true;
    // Level already pre-created in onLoad(), no need to recreate
    // Just reset power-up state and game vars
    score = 0;
    lives = 3;
    invulnerabilityTimer = 0.0;
    fireTimer = 0.0;
    _gameJustStarted = true;
    scoreText?.text = 'SCORE: 0';
    livesText?.text = 'LIVES: 3';
    levelText?.text = 'LEVEL 1';
    // Ensure the grid is reset to level 0
    _resetLevel(0);
  }

  /// Show a brief floating text label for power-up collection.
  void _showPowerUpLabel(String text, Color color) {
    final label = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.8), blurRadius: 8),
            Shadow(color: color.withValues(alpha: 0.4), blurRadius: 16),
          ],
        ),
      ),
      position: Vector2(size.x / 2, size.y / 2 - 40),
      anchor: Anchor.center,
      priority: 200,
    );
    add(label);
    // Remove after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      label.removeFromParent();
    });
  }

  /// Show remaining time of active power-ups on the HUD.
  void _updatePowerUpHud() {
    final parts = <String>[];
    if (shieldTimer > 0) parts.add('🛡️${shieldTimer.toStringAsFixed(1)}s');
    if (tripleShotTimer > 0) parts.add('🔱${tripleShotTimer.toStringAsFixed(1)}s');
    if (spreadShotTimer > 0) parts.add('🔥${spreadShotTimer.toStringAsFixed(1)}s');
    if (freezeTimer > 0) parts.add('❄️${freezeTimer.toStringAsFixed(1)}s');
    powerUpHud?.text = parts.isNotEmpty ? parts.join('  ') : '';
  }

  /// Destroy all enemies on screen instantly with explosions.
  void _activateBomb() {
    if (invaderGrid != null) {
      for (final enemy in invaderGrid!.enemies) {
        if (enemy.visible) {
          enemy.visible = false;
          score += 10;
          _spawnExplosion(enemy.position + invaderGrid!.position, const Color(0xFFFF6644));
        }
      }
    }
    if (boss != null && boss!.visible) {
      boss!.visible = false;
      score += 50;
      _spawnExplosion(boss!.position, const Color(0xFFFFAA00));
      _spawnExplosion(boss!.position + Vector2(-15, -10), const Color(0xFFFF6644));
      _spawnExplosion(boss!.position + Vector2(15, 10), const Color(0xFFFFAA00));
    }
    _playSound('explosion.wav');
    HapticFeedback.heavyImpact();
  }

  /// Play a sound file from assets/sounds.
  void _playSound(String name) {
    try {
      FlameAudio.play('sounds/$name');
    } catch (_) {}
  }

  /// Play the power-up collection sound with a pitch based on power-up type.
  /// Uses setPlaybackRate on the AudioPlayer to create different tones.
  void _playPowerUpSound(PowerUpType type) {
    try {
      double pitch;
      switch (type) {
        case PowerUpType.shield:
          pitch = 0.75;   // low, bassy — solid defense
          break;
        case PowerUpType.triple:
          pitch = 1.0;    // normal
          break;
        case PowerUpType.extraLife:
          pitch = 1.25;   // higher, bright — celebratory
          break;
        case PowerUpType.freeze:
          pitch = 0.65;   // lowest — icy, cold
          break;
        case PowerUpType.spread:
          pitch = 0.9;    // slightly lower — warm
          break;
        case PowerUpType.bomb:
          pitch = 1.5;    // highest — intense burst
          break;
      }
      FlameAudio.play('sounds/level_up.wav').then((player) {
        player?.setPlaybackRate(pitch);
      });
    } catch (_) {}
  }

  void _checkLevelComplete() {
    bool complete = false;
    if (boss != null) {
      if (!boss!.visible && invaderGrid != null && invaderGrid!.allDestroyed) complete = true;
    } else if (invaderGrid != null && invaderGrid!.allDestroyed) {
      complete = true;
    }
    if (complete) {
      isTransitioning = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextLevel();
      });
    }
  }

  void _clearBullets() {
    for (final b in playerBullets.toList()) b.removeFromParent();
    for (final b in enemyBullets.toList()) b.removeFromParent();
    playerBullets.clear();
    enemyBullets.clear();
  }

  void _checkGameOver() {
    if (invaderGrid != null) {
      for (final enemy in invaderGrid!.enemies) {
        if (enemy.visible && enemy.position.y + 20 >= size.y - 100) {
          _triggerGameOver();
          return;
        }
      }
    }
  }

  void _triggerGameOver() {
    isGameOver = true;
    _playSound('game_over.wav');
    _spawnExplosion(player.position, const Color(0xFFFF0000));
    player.visible = false;
    final oldHS = HighScoreManager.highScore;
    HighScoreManager.tryUpdate(score);
    final isNew = score > oldHS;
    final hsText = isNew ? '\n🏆 NEW HIGH SCORE!' : '\nHI: ${HighScoreManager.highScore}';
    gameOverText?.text = '💀 GAME OVER\n\nScore: $score$hsText\n\nTap to Restart';
  }

  /// Reset the currently loaded level without recreating components.
  void _resetLevel(int levelIndex) {
    currentLevel = levelIndex;
    final config = LevelConfig.levels[levelIndex.clamp(0, LevelConfig.levels.length - 1)];

    if (invaderGrid != null) {
      invaderGrid!.reset();
    }
    if (boss != null && config.isBossLevel) {
      boss!.hitPoints = config.bossHp;
      boss!.visible = true;
    } else if (boss != null) {
      boss!.visible = false;
    }

    _enemyAlphas.clear();
    _bossAlpha = null;

    levelText?.text = 'LEVEL ${config.level}';
    starfield.setSpeedLevel(config.level);
    isTransitioning = false;
  }

  void _resetGame() {
    if (_screenTransition.isActive) return;
    _screenTransition.start(() {
      _clearBullets();
      player.position = Vector2(size.x / 2, size.y - 80);
      player.visible = true;
      invulnerabilityTimer = 0.0;
      score = 0;
      lives = 3;
      isGameOver = false;
      gameOverText?.text = '';
      isGameStarted = true;
      isTransitioning = false;
      _gameJustStarted = true;
      // Reset power-up state
      shieldTimer = 0.0;
      tripleShotTimer = 0.0;
      freezeTimer = 0.0;
      spreadShotTimer = 0.0;
      player.shieldActive = false;
      if (invaderGrid != null) invaderGrid!.frozen = false;
      if (boss != null) boss!.frozen = false;
      _powerUps.clear();
      _resetLevel(0);
    });
  }

  void onExternalPanUpdate(double dx) {
    if (_gameState != GameState.playing || isGameOver) return;
    player.position.x += dx;
    player.position.x = player.position.x.clamp(30.0, size.x - 30.0);
  }

  void onExternalTapAt(Vector2 position) {
    if (_screenTransition.isActive) return;
    switch (_gameState) {
      case GameState.menu:
        mainMenu.handleTap(position);
        break;
      case GameState.levelSelect:
        levelSelect.handleTap(position);
        break;
      case GameState.playing:
        if (isGameOver) _resetGame();
        break;
    }
  }

  void onExternalFireTap() {
    if (_gameState != GameState.playing) return;
    if (isGameOver) { _resetGame(); return; }
    _spawnPlayerBullet();
    _gameJustStarted = false;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_screenTransition.isActive) return KeyEventResult.handled;
    if (_gameState == GameState.menu) {
      if (keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(LogicalKeyboardKey.enter)) {
        startGameFromMenu();
      }
      return KeyEventResult.handled;
    }
    if (_gameState == GameState.levelSelect) {
      return KeyEventResult.handled;
    }
    if (_gameState != GameState.playing) return KeyEventResult.handled;
    if (isGameOver) {
      if (keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(LogicalKeyboardKey.enter)) {
        _resetGame();
      }
      return KeyEventResult.handled;
    }
    const speed = 300.0;
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA))
      player.position.x -= speed * 0.016;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD))
      player.position.x += speed * 0.016;
    if (keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(LogicalKeyboardKey.enter)) {
      _spawnPlayerBullet();
    }
    player.position.x = player.position.x.clamp(30.0, size.x - 30.0);
    return KeyEventResult.handled;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    livesText?.position = Vector2(size.x - 120, 10);
    levelText?.position = Vector2(size.x / 2, 10);
    gameOverText?.position = Vector2(size.x / 2, size.y / 2 - 20);
  }
}
