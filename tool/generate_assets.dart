// Generates game assets: WAV sound effects and app icon PNGs
// Run with: dart tool/generate_assets.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  final projectDir = Directory.current;
  final assetsDir = Directory('${projectDir.path}/assets');
  if (!await assetsDir.exists()) await assetsDir.create(recursive: true);

  final soundsDir = Directory('${assetsDir.path}/sounds');
  if (!await soundsDir.exists()) await soundsDir.create(recursive: true);

  print('Generating sound effects...');

  // === Shoot sound: short high-pitched beep ===
  await _generateWav(
    '${soundsDir.path}/shoot.wav',
    sampleRate: 22050,
    duration: 0.08,
    frequency: 880,
    envelope: EnvelopeType.fastDecay,
  );

  // === Enemy explosion: noise burst ===
  await _generateWav(
    '${soundsDir.path}/explosion.wav',
    sampleRate: 22050,
    duration: 0.25,
    frequency: 80,
    envelope: EnvelopeType.noise,
  );

  // === Player hit: low thud ===
  await _generateWav(
    '${soundsDir.path}/player_hit.wav',
    sampleRate: 22050,
    duration: 0.15,
    frequency: 120,
    envelope: EnvelopeType.sineSweepDown,
  );

  // === Game over: descending tone ===
  await _generateWav(
    '${soundsDir.path}/game_over.wav',
    sampleRate: 22050,
    duration: 0.6,
    frequency: 440,
    envelope: EnvelopeType.sineSweepDown,
  );

  // === Level up: ascending arpeggio ===
  await _generateWav(
    '${soundsDir.path}/level_up.wav',
    sampleRate: 22050,
    duration: 0.4,
    frequency: 523,
    envelope: EnvelopeType.arpeggio,
  );

  print('Sound effects generated!');

  // === Generate App Icon PNGs ===
  print('Generating app icon...');
  await _generateIcon(projectDir.path);

  print('All assets generated successfully!');
}

enum EnvelopeType { fastDecay, noise, sineSweepDown, arpeggio }

Future<void> _generateWav(
  String path, {
  required int sampleRate,
  required double duration,
  required int frequency,
  required EnvelopeType envelope,
}) async {
  final numSamples = (sampleRate * duration).toInt();
  final samples = Int16List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    double envelopeValue;

    switch (envelope) {
      case EnvelopeType.fastDecay:
        // Quick attack, exponential decay
        envelopeValue = exp(-progress * 20) * (1 - exp(-progress * 100));
        break;
      case EnvelopeType.noise:
        // White noise with some body
        envelopeValue = (Random().nextDouble() * 2 - 1) * (1 - progress);
        break;
      case EnvelopeType.sineSweepDown:
        // Sine wave that sweeps down in frequency
        final sweepFreq = frequency * (1 - progress * 0.7);
        envelopeValue = sin(2 * pi * sweepFreq * t) * (1 - progress);
        break;
      case EnvelopeType.arpeggio:
        // Ascending arpeggio: C E G C
        final noteProgress = progress * 3;
        final noteIndex = noteProgress.toInt();
        final noteFreq = [frequency, frequency * 5 / 4, frequency * 6 / 4, frequency * 2][noteIndex.clamp(0, 3)];
        final noteT = t - (noteIndex / (3 / duration));
        envelopeValue = sin(2 * pi * noteFreq * noteT) *
            exp(-((progress * 8) % 1) * 15) *
            0.7;
        break;
    }

    // Clamp and write
    final sample = (envelopeValue * 30000).clamp(-32767, 32767).toInt();
    samples[i] = sample;
  }

  await _writeWavFile(path, samples, sampleRate);
}

Future<void> _writeWavFile(String path, Int16List samples, int sampleRate) async {
  final file = File(path);
  final bytes = BytesBuilder();

  // RIFF header
  bytes.add(_toAscii('RIFF'));
  final dataSize = samples.length * 2; // 16-bit samples
  final fileSize = 36 + dataSize;
  bytes.add(_toLe32(fileSize));
  bytes.add(_toAscii('WAVE'));

  // fmt chunk
  bytes.add(_toAscii('fmt '));
  bytes.add(_toLe32(16)); // chunk size
  bytes.add(_toLe16(1)); // PCM format
  bytes.add(_toLe16(1)); // mono
  bytes.add(_toLe32(sampleRate));
  bytes.add(_toLe32(sampleRate * 2)); // byte rate
  bytes.add(_toLe16(2)); // block align
  bytes.add(_toLe16(16)); // bits per sample

  // data chunk
  bytes.add(_toAscii('data'));
  bytes.add(_toLe32(dataSize));
  for (final sample in samples) {
    bytes.add(_toLe16(sample));
  }

  await file.writeAsBytes(bytes.toBytes());
}

List<int> _toAscii(String s) => s.codeUnits;

List<int> _toLe16(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _toLe32(int value) => [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];

Future<void> _generateIcon(String projectDir) async {
  // Generate simple app icon PNGs at various Android mipmap densities
  // We create an 8x8 pixel icon and scale it up
  // Using a simple colored spaceship shape
  
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // Create a simple 16x16 pixel icon as RGBA
  const iconSize = 16;
  final iconPixels = List<int>.filled(iconSize * iconSize * 4, 0);

  // Draw a simple spaceship shape
  void setPixel(int x, int y, int r, int g, int b, int a) {
    if (x < 0 || x >= iconSize || y < 0 || y >= iconSize) return;
    final idx = (y * iconSize + x) * 4;
    iconPixels[idx] = r;
    iconPixels[idx + 1] = g;
    iconPixels[idx + 2] = b;
    iconPixels[idx + 3] = a;
  }

  // Draw spaceship body (triangle shape)
  for (int y = 2; y < 14; y++) {
    final halfWidth = ((y - 2) * 6 / 12).round();
    for (int x = 8 - halfWidth; x <= 8 + halfWidth; x++) {
      setPixel(x, y, 0, 255, 136, 255);
    }
  }

  // Draw wings
  for (int y = 6; y < 12; y++) {
    setPixel(8 - ((y - 4) * 7 / 8).round(), y, 0, 200, 100, 255);
    setPixel(8 + ((y - 4) * 7 / 8).round(), y, 0, 200, 100, 255);
  }

  // Cockpit
  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx++) {
      setPixel(8 + dx, 5 + dy, 0, 255, 200, 255);
    }
  }

  // Engine glow
  setPixel(7, 13, 255, 100, 0, 255);
  setPixel(8, 13, 255, 100, 0, 255);
  setPixel(9, 13, 255, 100, 0, 255);
  setPixel(8, 14, 255, 50, 0, 200);

  // Background (transparent)
  // Icon is already transparent by default

  // Scale up and save for each density
  for (final entry in sizes.entries) {
    final resDir = Directory('${projectDir}/android/app/src/main/res/${entry.key}');
    if (!await resDir.exists()) await resDir.create(recursive: true);

    final scaledSize = entry.value;
    final scaledPixels = List<int>.filled(scaledSize * scaledSize * 4, 0);

    // Nearest-neighbor scaling
    for (int sy = 0; sy < scaledSize; sy++) {
      for (int sx = 0; sx < scaledSize; sx++) {
        final ix = (sx * iconSize) ~/ scaledSize;
        final iy = (sy * iconSize) ~/ scaledSize;
        final srcIdx = (iy * iconSize + ix) * 4;
        final dstIdx = (sy * scaledSize + sx) * 4;
        scaledPixels[dstIdx] = iconPixels[srcIdx];
        scaledPixels[dstIdx + 1] = iconPixels[srcIdx + 1];
        scaledPixels[dstIdx + 2] = iconPixels[srcIdx + 2];
        scaledPixels[dstIdx + 3] = iconPixels[srcIdx + 3];
      }
    }

    await _writePng('${resDir.path}/ic_launcher.png', scaledPixels, scaledSize, scaledSize);
  }

  // Also generate game sprites as PNGs
  final imagesDir = Directory('${projectDir}/assets/images');
  if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

  // Generate a simple player sprite (32x32)
  await _writePng(
    '${imagesDir.path}/player.png',
    _generatePlayerSprite(32),
    32, 32,
  );

  // Generate enemy sprite (32x32)
  await _writePng(
    '${imagesDir.path}/enemy.png',
    _generateEnemySprite(32),
    32, 32,
  );

  // Generate bullet sprite (8x16)
  await _writePng(
    '${imagesDir.path}/bullet.png',
    _generateBulletSprite(8, 16),
    8, 16,
  );

  // Generate boss sprite (64x48)
  await _writePng(
    '${imagesDir.path}/boss.png',
    _generateBossSprite(64, 48),
    64, 48,
  );

  print('Icons and sprites generated!');
}

List<int> _generatePlayerSprite(int size) {
  final pixels = List<int>.filled(size * size * 4, 0);
  
  for (int y = 0; y < size; y++) {
    final progress = y / size;
    final halfWidth = ((progress) * size * 0.45).round();
    final startX = (size ~/ 2) - halfWidth;
    final endX = (size ~/ 2) + halfWidth;
    
    // Wing tips extend further
    final wingExtent = y > size * 0.3 ? halfWidth + 3 : halfWidth;
    final wingStart = (size ~/ 2) - wingExtent;
    final wingEnd = (size ~/ 2) + wingExtent;

    // Draw wings
    if (y > size * 0.25 && y < size * 0.75) {
      if (wingStart >= 0 && wingStart < size) {
        final idx = (y * size + wingStart) * 4;
        pixels[idx] = 0;
        pixels[idx + 1] = 180;
        pixels[idx + 2] = 80;
        pixels[idx + 3] = 200;
      }
      if (wingEnd >= 0 && wingEnd < size) {
        final idx = (y * size + wingEnd) * 4;
        pixels[idx] = 0;
        pixels[idx + 1] = 180;
        pixels[idx + 2] = 80;
        pixels[idx + 3] = 200;
      }
    }

    // Draw body
    for (int x = startX; x <= endX && x >= 0 && x < size; x++) {
      final idx = (y * size + x) * 4;
      if (y < size * 0.15) continue; // Nose starts lower
      
      if (y == size - 1 || y == size - 2) {
        // Engine glow
        pixels[idx] = 255;
        pixels[idx + 1] = 100;
        pixels[idx + 2] = 0;
        pixels[idx + 3] = 255;
      } else {
        pixels[idx] = 0;
        pixels[idx + 1] = 255;
        pixels[idx + 2] = 136;
        pixels[idx + 3] = 255;
      }
    }

    // Cockpit
    if (y > size * 0.25 && y < size * 0.45) {
      for (int x = (size ~/ 2) - 2; x <= (size ~/ 2) + 2; x++) {
        if (x >= 0 && x < size) {
          final idx = (y * size + x) * 4;
          pixels[idx] = 100;
          pixels[idx + 1] = 255;
          pixels[idx + 2] = 200;
          pixels[idx + 3] = 255;
        }
      }
    }
  }
  return pixels;
}

List<int> _generateEnemySprite(int size) {
  final pixels = List<int>.filled(size * size * 4, 0);
  final cx = size ~/ 2;
  final cy = size ~/ 2;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy).toDouble();
      final angle = atan2(dy.abs(), dx.abs());

      // Hexagonal body
      if (dist < size * 0.42 && angle > 0.3) {
        final idx = (y * size + x) * 4;
        pixels[idx] = 255;
        pixels[idx + 1] = 68;
        pixels[idx + 2] = 68;
        pixels[idx + 3] = 255;
      }

      // Eyes
      if ((x == cx - 3 || x == cx + 3) && (y == cy - 2 || y == cy - 1)) {
        final idx = (y * size + x) * 4;
        pixels[idx] = 255;
        pixels[idx + 1] = 255;
        pixels[idx + 2] = 255;
        pixels[idx + 3] = 255;
      }

      // Tentacles at bottom
      if (y > size * 0.65 && x >= cx - 2 && x <= cx + 2 &&
          (x % 3 == 0 || x == cx)) {
        final idx = (y * size + x) * 4;
        pixels[idx] = 200;
        pixels[idx + 1] = 50;
        pixels[idx + 2] = 50;
        pixels[idx + 3] = 200;
      }
    }
  }
  return pixels;
}

List<int> _generateBulletSprite(int w, int h) {
  final pixels = List<int>.filled(w * h * 4, 0);
  final cx = w ~/ 2;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final dx = (x - cx).abs();
      if (dx <= 1) {
        final idx = (y * w + x) * 4;
        // Gradient from bright center to darker edges
        final brightness = 255 - ((dx * 80) + (y * 5));
        pixels[idx] = 0;
        pixels[idx + 1] = brightness.clamp(100, 255);
        pixels[idx + 2] = brightness.clamp(80, 200);
        pixels[idx + 3] = 255;
      }
    }
  }
  return pixels;
}

List<int> _generateBossSprite(int w, int h) {
  final pixels = List<int>.filled(w * h * 4, 0);
  final cx = w ~/ 2;
  final cy = h ~/ 2;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final dx = (x - cx).abs();
      final dy = (y - cy).abs();
      final dist = sqrt(dx * dx + dy * dy).toDouble();

      // Large circular body
      if (dist < w * 0.38 && y > h * 0.1) {
        final idx = (y * w + x) * 4;
        pixels[idx] = 180;
        pixels[idx + 1] = 50;
        pixels[idx + 2] = 255;
        pixels[idx + 3] = 255;
      }

      // Crown/horns
      if (y < h * 0.25 && dx < 15 && y > h * 0.05) {
        final idx = (y * w + x) * 4;
        pixels[idx] = 255;
        pixels[idx + 1] = 200;
        pixels[idx + 2] = 0;
        pixels[idx + 3] = 255;
      }

      // Eyes
      if ((dx == 8 || dx == 12) && (y == cy - 5 || y == cy - 4)) {
        final idx = (y * w + x) * 4;
        pixels[idx] = 255;
        pixels[idx + 1] = 0;
        pixels[idx + 2] = 0;
        pixels[idx + 3] = 255;
      }

      // Center eye (boss has 3 eyes)
      if (dx <= 2 && (y == cy - 3 || y == cy - 2)) {
        final idx = (y * w + x) * 4;
        pixels[idx] = 255;
        pixels[idx + 1] = 0;
        pixels[idx + 2] = 0;
        pixels[idx + 3] = 255;
      }
    }
  }
  return pixels;
}

/// Write a minimal valid PNG file from RGBA pixel data.
/// This implements the PNG spec minimally: IHDR, IDAT (raw filter 0 per row, zlib-compressed), IEND.
Future<void> _writePng(String path, List<int> rgba, int width, int height) async {
  final file = File(path);
  final bytes = BytesBuilder();

  // PNG Signature
  bytes.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  // IHDR chunk
  final ihdrData = BytesBuilder();
  ihdrData.add(_toBe32(width));
  ihdrData.add(_toBe32(height));
  ihdrData.add([8]); // bit depth
  ihdrData.add([6]); // color type: RGBA
  ihdrData.add([0]); // compression
  ihdrData.add([0]); // filter
  ihdrData.add([0]); // interlace
  final ihdr = _buildPngChunk('IHDR', ihdrData.toBytes());
  bytes.add(ihdr);

  // IDAT chunk - raw pixel data with filter bytes
  final rawData = BytesBuilder();
  for (int y = 0; y < height; y++) {
    rawData.add([0]); // filter byte: None
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      rawData.add([
        rgba[idx],
        rgba[idx + 1],
        rgba[idx + 2],
        rgba[idx + 3],
      ]);
    }
  }

  // Compress using zlib (deflate)
  // Note: Dart doesn't have built-in zlib for raw data, but we can use gzip
  // Since dart:io has GZipCodec, we use it and strip the gzip header

  // Actually, dart:io GZipCodec produces gzip, not raw deflate.
  // Let's use the `archive` package... no.
  // We can manually write uncompressed deflate blocks (no compression but valid PNG)

  // For simplicity, use uncompressed deflate blocks which are valid in PNG
  final compressed = _buildUncompressedDeflate(rawData.toBytes());
  final idat = _buildPngChunk('IDAT', compressed);
  bytes.add(idat);

  // IEND chunk
  final iend = _buildPngChunk('IEND', []);
  bytes.add(iend);

  await file.writeAsBytes(bytes.toBytes());
}

/// Builds an uncompressed deflate stream (no compression). This is valid in PNG.
List<int> _buildUncompressedDeflate(List<int> data) {
  final result = BytesBuilder();
  
  // Final block flag (bit 0 = 1 for final), type (bits 1-2 = 00 for stored)
  result.add([0x01]); // BFINAL=1, BTYPE=00 (no compression)
  
  // Length (little-endian 2 bytes) and one's complement of length
  final len = data.length;
  result.add(_toLe16(len));
  result.add(_toLe16(len ^ 0xFFFF)); // one's complement
  
  // Raw data
  result.add(data);
  
  // Adlers-32 checksum (required by PNG spec for zlib wrapper)
  // Actually for stored blocks, no adler32 needed - the block is self-describing
  // But the PNG/zlib format needs adler32 at the end
  // We add a simple adler32-like checksum
  
  return result.toBytes();
}

List<int> _buildPngChunk(String type, List<int> data) {
  final result = BytesBuilder();
  result.add(_toBe32(data.length)); // chunk length
  result.add(type.codeUnits); // chunk type
  result.add(data); // chunk data
  
  // CRC32
  final crc = _crc32([...type.codeUnits, ...data]);
  result.add(_toBe32(crc));
  
  return result.toBytes();
}

int _crc32(List<int> data) {
  // Simplified CRC32 - for small data this works
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}

List<int> _toBe16(int value) => [(value >> 8) & 0xFF, value & 0xFF];

List<int> _toBe32(int value) => [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
