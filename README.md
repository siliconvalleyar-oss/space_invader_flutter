# 🚀 Space Invaders

Classic Space Invaders game built with **Flutter** and **Flame** engine.  
Optimized for **Android mobile** with touch controls.

## 📱 Features

- **Touch controls**: Drag to move, tap fire button to shoot
- **7 progressive levels** with increasing difficulty
- **Boss fights** every 5th level
- **Pixel-perfect collision** using sprite alpha channels
- **Particle explosions** with impact sprite effects
- **Scrolling starfield** with planet decorations
- **Full sound effects** (shoot, explosion, hit, level up, game over)
- **Haptic feedback** on collisions
- **Smooth enemy movement** with continuous velocity
- **3 enemy types** with different sprites per row

## 🎮 Controls

| Control | Action |
|---------|--------|
| **Drag** (anywhere) | Move player left/right |
| **Fire button** (right side) | Shoot |
| **Tap** (center) | Start / Restart |

## 📦 Project Structure

```
lib/
├── main.dart                    # App entry + fire button overlay
├── game/
│   └── space_invaders_game.dart # Main game logic
├── components/
│   ├── player.dart              # Player ship (nave_00.png)
│   ├── enemy.dart               # Enemies + Boss sprites
│   ├── bullet.dart              # Bullets with color tint
│   ├── invader_grid.dart        # Enemy formation + smooth movement
│   ├── explosion.dart           # Particle effects
│   ├── starfield.dart           # Background stars + planets
│   └── collision_utils.dart     # Alpha-channel collision
├── assets/
│   ├── images/                  # Sprites (ships, enemies, bullets, planets)
│   └── sounds/                  # WAV effects
```

## 📜 Version History

### v1.0.0 — Initial Release
- Basic game loop with Flame engine
- Auto-fire, touch movement
- 7 levels with progressive difficulty
- Boss enemy with triple-shot attack

### v1.1.0 — Asset Integration
- **Sprites**: Player uses `nave_00.png`, enemies use `enemy_00/01/02.png`, boss uses `boss.png`, bullets use `bullet.png`
- **Sounds**: Full audio with `flame_audio` (shoot, explosion, hit, level up, game over)
- **Fire button**: Red circle overlay on right side for mobile
- **Particle explosions**: Impact sprite + expanding particles on enemy death
- **Starfield background**: Scrolling stars + planet decorations

### v1.2.0 — Mobile Polish
- **Pixel-perfect collision**: Alpha channel-based detection — only visible pixels collide
- **Smooth enemy movement**: Continuous velocity replaces discrete step movement
- **Haptic feedback**: Vibration on hit (light) and explosion (heavy)
- **Fixed player visibility**: Uses `nave_00.png` (88×118) with proper scaling
- **Improved auto-fire**: Faster cooldown (200ms), starts immediately after first tap
- **Professional .gitignore**: Flutter-optimized ignore patterns

## 🛠️ Build & Install

```bash
# Debug build
flutter build apk --debug

# Release build (requires signing)
flutter build apk --release

# Install on connected device
flutter install
# OR
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 🧩 Dependencies

- **Flutter** ≥3.6.0
- **Flame** ≥1.20.0 (game engine)
- **Flame Audio** ≥2.1.0 (sound effects)

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
