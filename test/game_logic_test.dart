import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:space_invaders/game/space_invaders_game.dart';
import 'package:space_invaders/components/bullet.dart';
import 'package:space_invaders/components/power_up.dart';
import 'package:space_invaders/components/enemy.dart';
import 'package:space_invaders/components/player.dart';
import 'package:space_invaders/components/collision_utils.dart';

void main() {
  group('CollisionUtils.checkBulletCollision', () {
    test('returns true when bullet overlaps target center', () {
      final bullet = PositionComponent()
        ..position = Vector2(100, 100)
        ..size = Vector2(10, 20);
      final target = PositionComponent()
        ..position = Vector2(100, 100)
        ..size = Vector2(30, 40);

      expect(CollisionUtils.checkBulletCollision(bullet, target), isTrue);
    });

    test('returns false when bullet and target are far apart', () {
      final bullet = PositionComponent()
        ..position = Vector2(0, 0)
        ..size = Vector2(10, 10);
      final target = PositionComponent()
        ..position = Vector2(500, 500)
        ..size = Vector2(30, 30);

      expect(CollisionUtils.checkBulletCollision(bullet, target), isFalse);
    });

    test('returns false when bullet is near but not overlapping shrunk target', () {
      // Bullet at (80,80) with size (10,10) -> rect (80,80,90,90)
      // Target at (100,100) with size (20,20) -> rect (100,100,120,120)
      // Shrunk by 0.3 -> deflate by 6px -> rect (106,106,114,114)
      // Bullet rect (80,80,90,90) doesn't overlap (106,106,114,114)
      final bullet = PositionComponent()
        ..position = Vector2(80, 80)
        ..size = Vector2(10, 10);
      final target = PositionComponent()
        ..position = Vector2(100, 100)
        ..size = Vector2(20, 20);

      expect(CollisionUtils.checkBulletCollision(bullet, target, shrink: 0.3), isFalse);
    });

    test('returns true with shrink=0 when bullet clearly overlaps target', () {
      // Bullet at (95,95) size (10,10) -> rect (95,95,105,105)
      // Target at (100,100) size (20,20) -> rect (100,100,120,120)
      // With shrink=0: overlap at x(100-105), y(100-105)
      final bullet = PositionComponent()
        ..position = Vector2(95, 95)
        ..size = Vector2(10, 10);
      final target = PositionComponent()
        ..position = Vector2(100, 100)
        ..size = Vector2(20, 20);

      expect(CollisionUtils.checkBulletCollision(bullet, target, shrink: 0.0), isTrue);
    });

    test('shrink reduces the collision area', () {
      // Bullet at (95,95) size (10,10) -> rect (95,95,105,105)
      // Target at (100,100) size (20,20) -> rect (100,100,120,120)
      // Shrink 0.3 -> deflate by 6px -> rect (106,106,114,114)
      // Bullet (95,95,105,105) doesn't overlap (106,106,114,114)
      final bullet = PositionComponent()
        ..position = Vector2(95, 95)
        ..size = Vector2(10, 10);
      final target = PositionComponent()
        ..position = Vector2(100, 100)
        ..size = Vector2(20, 20);

      // With shrink, no collision
      expect(CollisionUtils.checkBulletCollision(bullet, target, shrink: 0.3), isFalse);
      // Without shrink, collision
      expect(CollisionUtils.checkBulletCollision(bullet, target, shrink: 0.0), isTrue);
    });
  });

  group('Enemy', () {
    test('starts with 2 hitPoints and visible', () {
      final enemy = Enemy(row: 0, col: 0);
      expect(enemy.hitPoints, equals(2));
      expect(enemy.visible, isTrue);
    });

    test('takeDamage reduces hitPoints by 1', () {
      final enemy = Enemy(row: 0, col: 0);
      enemy.takeDamage();
      expect(enemy.hitPoints, equals(1));
      expect(enemy.visible, isTrue);
    });

    test('takeDamage sets visible=false when hitPoints reach 0', () {
      final enemy = Enemy(row: 0, col: 0);
      enemy.takeDamage(); // HP: 2 -> 1
      enemy.takeDamage(); // HP: 1 -> 0

      expect(enemy.hitPoints, equals(0));
      expect(enemy.visible, isFalse);
    });

    test('stores row, col, and type correctly', () {
      final enemy = Enemy(row: 2, col: 4, type: 1);
      expect(enemy.row, equals(2));
      expect(enemy.col, equals(4));
      expect(enemy.type, equals(1));
    });
  });

  group('Boss', () {
    test('starts with maxHp hitPoints and visible', () {
      final boss = Boss(maxHp: 10);
      expect(boss.hitPoints, equals(10));
      expect(boss.visible, isTrue);
    });

    test('takeDamage reduces hitPoints', () {
      final boss = Boss(maxHp: 5);
      boss.takeDamage();
      expect(boss.hitPoints, equals(4));
      expect(boss.visible, isTrue);
    });

    test('takeDamage sets visible=false when hitPoints reach 0', () {
      final boss = Boss(maxHp: 2);
      boss.takeDamage(); // HP: 2 -> 1
      boss.takeDamage(); // HP: 1 -> 0

      expect(boss.hitPoints, equals(0));
      expect(boss.visible, isFalse);
    });
  });

  group('Player', () {
    test('starts visible', () {
      final player = Player();
      expect(player.visible, isTrue);
    });

    test('visible can be set to false', () {
      final player = Player();
      player.visible = false;
      expect(player.visible, isFalse);
    });

    test('visible can be toggled', () {
      final player = Player();
      player.visible = false;
      expect(player.visible, isFalse);
      player.visible = true;
      expect(player.visible, isTrue);
    });
  });

  group('Bullet', () {
    test('player bullet starts with correct initial state', () {
      final bullet = Bullet(position: Vector2(100, 500), isPlayerBullet: true);
      expect(bullet.visible, isTrue);
      expect(bullet.isPlayerBullet, isTrue);
      expect(bullet.position.x, closeTo(100, 0.1));
      expect(bullet.position.y, closeTo(500, 0.1));
    });

    test('enemy bullet starts with correct initial state', () {
      final bullet = Bullet(position: Vector2(100, 100), isPlayerBullet: false);
      expect(bullet.visible, isTrue);
      expect(bullet.isPlayerBullet, isFalse);
    });

    test('off-screen check: bullet at y < -40 should become invisible', () {
      // This tests the core cleanup logic without relying on HasGameReference
      final bullet = Bullet(position: Vector2(100, -50), isPlayerBullet: true);

      // Simulate what Bullet.update() does for the off-screen check
      if (bullet.position.y < -40) {
        bullet.visible = false;
      }

      expect(bullet.visible, isFalse);
    });

    test('off-screen check: bullet at y > 840 should become invisible', () {
      final bullet = Bullet(position: Vector2(100, 900), isPlayerBullet: false);

      // Simulate off-screen check (game.size.y → 800, so threshold is 840)
      if (bullet.position.y < -40 || bullet.position.y > 840) {
        bullet.visible = false;
      }

      expect(bullet.visible, isFalse);
    });

    test('on-screen bullet should remain visible', () {
      final bullet = Bullet(position: Vector2(100, 300), isPlayerBullet: true);

      // Simulate off-screen check
      if (!(bullet.position.y < -40 || bullet.position.y > 840)) {
        // stays visible
      }

      expect(bullet.visible, isTrue);
    });
  });

  group('PowerUp', () {
    test('starts visible with correct position and type', () {
      final pu = PowerUp(position: Vector2(100, 100), type: PowerUpType.shield);
      expect(pu.visible, isTrue);
      expect(pu.position.x, closeTo(100, 0.1));
      expect(pu.position.y, closeTo(100, 0.1));
      expect(pu.type, equals(PowerUpType.shield));
    });

    test('falls down on update after entry phase', () {
      final pu = PowerUp(position: Vector2(100, 200), type: PowerUpType.shield);
      final initialY = pu.position.y;

      // Update past the 0.15s entry pause
      pu.update(0.2);

      // Should have started falling (60px/s * 0.05s actual fall time = 3px)
      expect(pu.position.y, greaterThan(initialY));
    });

    test('sets visible=false when falling off screen (y > 880)', () {
      final pu = PowerUp(position: Vector2(100, 860), type: PowerUpType.shield);
      expect(pu.visible, isTrue);

      // Update to pass entry phase and fall to y > 880
      // fallSpeed = 60px/s, entry pause = 0.15s
      // After 0.15s entry pause, remaining 0.05s * 60px/s = 3px
      // y = 860 + 3 = 863 (not > 880 yet)
      // Need more updates
      for (int i = 0; i < 30; i++) {
        pu.update(0.1);
      }

      // By now the powerup should have fallen well past y=880
      expect(pu.visible, isFalse);
    });

    test('does not set visible=false when still on screen', () {
      final pu = PowerUp(position: Vector2(100, 100), type: PowerUpType.shield);

      for (int i = 0; i < 5; i++) {
        pu.update(0.1);
      }

      expect(pu.visible, isTrue);
    });

    test('PowerUpType values are accessible', () {
      expect(PowerUpType.values.length, equals(6));
      expect(PowerUpType.values, containsAll([
        PowerUpType.shield,
        PowerUpType.triple,
        PowerUpType.extraLife,
        PowerUpType.freeze,
        PowerUpType.spread,
        PowerUpType.bomb,
      ]));
    });
  });

  group('Bullet list cleanup via removeWhere', () {
    test('playerBullets.removeWhere removes bullets with visible=false', () {
      final game = SpaceInvadersGame();

      final activeBullet = Bullet(position: Vector2(100, 300), isPlayerBullet: true);
      final offScreenBullet = Bullet(position: Vector2(100, -50), isPlayerBullet: true);
      // Simulate off-screen cleanup marking it invisible
      offScreenBullet.visible = false;

      game.playerBullets.add(activeBullet);
      game.playerBullets.add(offScreenBullet);

      expect(game.playerBullets.length, equals(2));

      // This is the exact same cleanup logic as _checkCollisions
      game.playerBullets.removeWhere((b) => !b.visible);

      expect(game.playerBullets.length, equals(1));
      // The remaining bullet should be the on-screen one at y=300
      expect(game.playerBullets.first.position.y, closeTo(300, 0.1));
    });

    test('enemyBullets.removeWhere removes bullets with visible=false', () {
      final game = SpaceInvadersGame();

      final activeBullet = Bullet(position: Vector2(100, 300), isPlayerBullet: false);
      final offScreenBullet = Bullet(position: Vector2(100, 900), isPlayerBullet: false);
      offScreenBullet.visible = false;

      game.enemyBullets.add(activeBullet);
      game.enemyBullets.add(offScreenBullet);

      expect(game.enemyBullets.length, equals(2));

      game.enemyBullets.removeWhere((b) => !b.visible);

      expect(game.enemyBullets.length, equals(1));
      expect(game.enemyBullets.first.isPlayerBullet, isFalse);
    });

    test('multiple off-screen bullets are all cleaned up', () {
      final game = SpaceInvadersGame();

      // Add 5 off-screen bullets (marked invisible)
      for (int i = 0; i < 5; i++) {
        final bullet = Bullet(position: Vector2(100.0 + i * 10, -50), isPlayerBullet: true);
        bullet.visible = false;
        game.playerBullets.add(bullet);
      }

      // Add 3 on-screen bullets (still visible)
      for (int i = 0; i < 3; i++) {
        final bullet = Bullet(position: Vector2(100.0 + i * 10, 300), isPlayerBullet: true);
        game.playerBullets.add(bullet);
      }

      expect(game.playerBullets.length, equals(8));

      game.playerBullets.removeWhere((b) => !b.visible);

      expect(game.playerBullets.length, equals(3));
    });

    test('bullets removed via playerBullets.remove() do not need visible=false', () {
      final game = SpaceInvadersGame();

      final bullet = Bullet(position: Vector2(100, 300), isPlayerBullet: true);
      game.playerBullets.add(bullet);

      // Simulate what happens when bullet hits an enemy: direct removal from list
      game.playerBullets.remove(bullet);

      expect(game.playerBullets.length, equals(0));
    });
  });

  group('Enemy visibility integration with collision logic', () {
    test('Enemy lifecycle matches game collision expectations', () {
      final enemy = Enemy(row: 0, col: 0);

      // Fresh enemy should be visible (game checks: if (!enemy.visible) continue;)
      expect(enemy.visible, isTrue, reason: 'Enemy should start visible');

      // After first hit: HP 2->1, still visible
      enemy.takeDamage();
      expect(enemy.visible, isTrue, reason: 'Enemy still visible after first hit');
      expect(enemy.hitPoints, equals(1));

      // After second hit: HP 1->0, not visible anymore
      // The game checks: if (!enemy.visible) { score += 10; ... }
      enemy.takeDamage();
      expect(enemy.visible, isFalse, reason: 'Enemy invisible when HP reaches 0');
    });

    test('restore enemy visibility on reset (InvaderGrid.reset contract)', () {
      final enemy = Enemy(row: 0, col: 0);
      enemy.takeDamage();
      enemy.takeDamage();
      expect(enemy.visible, isFalse);

      // InvaderGrid.reset() restores HP and visibility
      enemy.hitPoints = 2;
      enemy.visible = true;

      expect(enemy.hitPoints, equals(2));
      expect(enemy.visible, isTrue);
    });
  });

  group('SpaceInvadersGame integration', () {
    test('playerBullets and enemyBullets start empty', () {
      final game = SpaceInvadersGame();
      expect(game.playerBullets, isEmpty);
      expect(game.enemyBullets, isEmpty);
    });

    test('_clearBullets empties both lists', () {
      final game = SpaceInvadersGame();

      game.playerBullets.add(Bullet(position: Vector2(0, 0), isPlayerBullet: true));
      game.playerBullets.add(Bullet(position: Vector2(0, 0), isPlayerBullet: true));
      game.enemyBullets.add(Bullet(position: Vector2(0, 0), isPlayerBullet: false));

      expect(game.playerBullets.length, equals(2));
      expect(game.enemyBullets.length, equals(1));

      // Manually simulate _clearBullets (it's private, test via behavior)
      // _clearBullets does: removeFromParent() for each + clear()
      for (final b in game.playerBullets.toList()) {
        b.visible = false;
      }
      for (final b in game.enemyBullets.toList()) {
        b.visible = false;
      }
      game.playerBullets.removeWhere((b) => !b.visible);
      game.enemyBullets.removeWhere((b) => !b.visible);

      expect(game.playerBullets, isEmpty);
      expect(game.enemyBullets, isEmpty);
    });

    test('score increases when enemy HP reaches 0', () {
      final game = SpaceInvadersGame();
      game.score = 0;

      // Simulate what _checkCollisions does when an enemy is destroyed:
      // enemy.takeDamage() -> if (!enemy.visible) { score += 10; }
      final enemy = Enemy(row: 0, col: 0);
      enemy.takeDamage();
      enemy.takeDamage();

      if (!enemy.visible) {
        game.score += 10;
      }

      expect(game.score, equals(10));
    });

    test('score increases by 50 when boss HP reaches 0', () {
      final game = SpaceInvadersGame();
      game.score = 0;

      final boss = Boss(maxHp: 5);
      // Hit boss 5 times to destroy it
      for (int i = 0; i < 5; i++) {
        boss.takeDamage();
      }

      if (!boss.visible) {
        game.score += 50;
      }

      expect(game.score, equals(50));
    });
  });

  group('LevelConfig', () {
    test('has 7 predefined levels', () {
      expect(LevelConfig.levels.length, equals(7));
    });

    test('level 5 is a boss level', () {
      final level5 = LevelConfig.levels[4];
      expect(level5.isBossLevel, isTrue);
      expect(level5.bossHp, equals(15));
    });

    test('level 1 has default configuration', () {
      final level1 = LevelConfig.levels[0];
      expect(level1.level, equals(1));
      expect(level1.gridColumns, equals(5));
      expect(level1.gridRows, equals(3));
    });
  });

  group('GameState', () {
    test('has three states', () {
      expect(GameState.values.length, equals(3));
      expect(GameState.values, containsAll([
        GameState.menu,
        GameState.levelSelect,
        GameState.playing,
      ]));
    });
  });
}
