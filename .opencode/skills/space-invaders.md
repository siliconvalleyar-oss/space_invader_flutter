# Space Invaders — Flutter Flame Game

## Build & Run

```bash
flutter run -d <device-id>
```

## Known Issues

### "Could not decompress image" — PNG fails en Impeller/Vulkan
- Síntoma: sprites no se renderizan (fallback visual en su lugar), assertion `sprite != null` en `SpriteComponent.onMount()`.
- Causa: el decoder de Impeller no puede descomprimir ciertos PNG 8-bit RGBA en este device.
- Solución aplicada: **Todos los componentes que antes extendían `SpriteComponent` ahora extienden `PositionComponent`**:
  - `Bullet`, `Player`, `Enemy`, `Boss`, `PowerUp`
  - El sprite se carga en un campo `Sprite? _sprite` / `Sprite? sprite` (público para alpha maps).
  - `onLoad()` envuelve `Sprite.load()` en try/catch; si falla, `sprite` queda `null`.
  - `render()` dibuja un fallback visual (rectángulo coloreado, glow, etc.) cuando `sprite == null`.

### Colisión bullet-enemigo no funciona
- Síntoma: balas pasan de largo, enemigos solo mueren cuando un "planeta" les cae encima.
- Causa raíz: `checkAlphaCollision()` y `checkBulletCollision()` usaban `toRect()` que retorna rect en **coordenadas locales del padre**. La bala (hija del game) y el enemigo (hijo de la grilla) tenían rects en espacios distintos.
- Solución: cambiar `toRect()` → `toAbsoluteRect()` en todas las comparaciones de colisión, incluyendo fallbacks cuando los alpha maps son null.
- Archivos: `collision_utils.dart`, `space_invaders_game.dart`.

### Freeze después de ~5 disparos
- Síntoma: juego se congela tras varios disparos.
- Causa: `Bullet.update()` llamaba `removeFromParent()` pero **nunca seteaba `visible = false`**. `removeWhere` en `_checkCollisions` nunca limpiaba la lista `playerBullets`, que crecía sin control, y cada frame chequeaba todas las balas acumuladas contra todos los enemigos.
- Solución: agregar `visible = false;` antes de `removeFromParent()` en el off‑screen check de `Bullet.update()`.

## Arquitectura

### Componentes visuales (tolerantes a sprite nulo)

| Clase | Extiende | Sprite field | Fallback visual |
|-------|----------|-------------|-----------------|
| Player | `PositionComponent` | `sprite` | RRect verde-azul |
| Enemy | `PositionComponent` | `sprite` | Rect coloreado según hitPoints |
| Boss | `PositionComponent` | `sprite` | Rect coloreado según HP |
| Bullet | `PositionComponent` | `_sprite` | Glow + core line (jugador) / glow (enemigo) |
| PowerUp | `PositionComponent` | `sprite` | Círculo con glow (ya existente) |
| Explosion | `Component` | `_impactSprite` | Solo partículas si sprite null |
| Starfield | `Component` | N/A (sprites en _Planet) | Planetas no se crean si falla carga |

### Colisiones

- **Player bullets vs enemies**: `checkAlphaCollision(bullet, _playerAlpha, enemy, enemyAlpha, step: 2)` con `toAbsoluteRect()`.
- **Fallback** (cuando alpha maps son null por sprite fallido): bounding box con `toAbsoluteRect()`.
- **Enemy bullets vs player**: `checkBulletCollision(bullet, player, shrink: 0.2)` con `toAbsoluteRect()`.
- **Power-ups vs player**: bounding box con `toAbsoluteRect()`.

### Input

- **Movimiento**: `onPanUpdate` (drag horizontal).
- **Disparo**: `onTapUp` sobre el área del juego (llama a `_spawnPlayerBullet`).
- **Botón de fuego** (opcional): overlay derecho en `main.dart` llama a `onExternalFireTap()`.

## Debugging

Para logs de colisión, descomentar `debugPrint` en `_checkCollisions()` de `space_invaders_game.dart`.

## Assets

Los PNG deben ser 8-bit RGBA. Si el device no los descomprime (Impeller/Vulkan), se muestran fallbacks visuales. Para regenerar assets con formato compatible, convertir a PNG 32-bit o usar `pngcrush`.
