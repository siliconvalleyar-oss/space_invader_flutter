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

## 🎮 Power-ups

| Type | Sprite | Effect |
|------|--------|--------|
| 🛡️ **Shield** | `nave_02.png` | Absorbs damage for 6s |
| 🔱 **Triple** | `disparo_de_nave_triple_00.png` | 3-way spread shot for 6s |
| ❤️ **ExtraLife** | `nave_04.png` | +1 life instantly |
| ❄️ **Freeze** | `nave_03.png` | Freezes enemies for 6s (they fire faster) |
| 🔥 **Spread** | `disparo_de_nave_01.png` | 5-way wide spread shot for 6s |
| 💥 **Bomb** | `disparo_de_nave_02.png` | Destroys all enemies on screen instantly |

Power-ups drop from destroyed enemies with decreasing probability as levels progress (28% → 10%).

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
│   ├── collision_utils.dart     # Alpha-channel collision
│   └── power_up.dart            # Power-up items with entry animation
├── utils/
│   └── high_score_manager.dart  # Persistent high score (SharedPreferences)
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

### v1.2.1 — Visible Bullets
- **Player bullets**: Now use `disparo_de_nave_00.png` (16×32) with bright green glow + white core
- **Enemy bullets**: Use `bullet.png` with red tint (12×24)
- **Larger glow**: Blur radius increased from 6 → 12 for mobile visibility

### v1.2.2 — Audio Fix
- **Fixed sound paths**: WAV files at `assets/sounds/` now referenced as `sounds/name.wav`
- **Removed broken preload**: `loadAll()` was silently failing, blocking all sounds — now loads on-demand

### v1.3.0 — Power-ups
- **3 power-up types**: Shield (`nave_02.png`), Triple shot (`disparo_de_nave_triple_00.png`), Extra life (`nave_04.png`)
- **Drop system**: 20% chance from destroyed enemies, falls down at 60px/s
- **Shield mechanic**: Absorbs damage, blue pulsating shield visual for 6s
- **Triple shot**: 3 parallel bullets with 12px spread for 6s
- **Extra life**: +1 life instantly with green label
- **Visual effects**: Floating glow rings, bobbing animation, pulsing border
- **Collection feedback**: Floating label + sound + haptic on pickup

### v1.3.1 — Persistent High Scores
- **HighScoreManager**: Static class using `shared_preferences` for persistent storage
- **Start screen**: Shows current high score (HI: {score})
- **Game Over/Victory**: Compares score, shows "🏆 NEW HIGH SCORE!" when beaten
- **Robust detection**: Correctly handles ties and edge cases with oldHS capture

### v1.4.0 — Enhanced Power-ups & Difficulty Scaling
- **3 new power-ups**: Freeze (❄️ `nave_03.png`), Spread (🔥 `disparo_de_nave_01.png`), Bomb (💥 `disparo_de_nave_02.png`)
- **6 total power-up types**: Shield, Triple, ExtraLife, Freeze, Spread, Bomb
- **Power-up HUD**: Shows remaining time for active power-ups (`🛡️4.2s 🔱3.1s 🔥5.0s ❄️2.5s`)
- **Freeze mechanic**: Enemies stop moving but fire 30% faster (risk/reward), 6s duration
- **Spread shot**: 5 bullets in wide fan (-24 to +24 offset), overrides triple when active
- **Bomb**: Instant screen clear with explosions + score for all visible enemies + boss
- **Progressive difficulty**: Spawn chance scales down with level (28% → 10%)
- **Level transition cleanup**: All power-up timers reset between levels for fairness

### v1.4.1 — Power-up Entry Animations
- **Spawn animation**: Fade-in (0→1) + full rotation (360°) + scale-up (0.3→1.0) over 0.5s
- **Ease-out cubic**: Smooth fast-start, slow-end curve
- **Pause before falling**: 0.15s delay so the entry animation plays at the spawn point
- **Seamless transition**: Bobbing and glow animations smoothly take over after entry

### v1.4.2 — Freeze Visual Effects
- **Blue tint overlay**: Semi-transparent blue layer on frozen enemies (`0x6644CCFF`)
- **Ice crystal particles**: 5 crystals (8 for Boss) orbiting with twinkle animation
- **Shimmer lines**: Bright white lines pulsing across frozen sprites
- **Boss freeze visuals**: Larger crystals, dual shimmer lines, blue aura replaces red aura
- **Frozen propagation**: `InvaderGrid.frozen` setter propagates to all `Enemy` components

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
