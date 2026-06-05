import 'package:shared_preferences/shared_preferences.dart';

/// Manages high score persistence using shared_preferences.
class HighScoreManager {
  static const String _key = 'space_invaders_high_score';
  static int _highScore = 0;
  static bool _loaded = false;

  /// Load the saved high score from disk.
  /// Must be called once at game startup.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highScore = prefs.getInt(_key) ?? 0;
      _loaded = true;
    } catch (_) {
      _highScore = 0;
      _loaded = true;
    }
  }

  /// Get the current high score.
  static int get highScore => _loaded ? _highScore : 0;

  /// Update high score if [score] is higher.
  /// Returns true if a new high score was set.
  static Future<bool> tryUpdate(int score) async {
    if (score <= _highScore) return false;
    _highScore = score;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, _highScore);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset high score (for testing).
  static Future<void> reset() async {
    _highScore = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, 0);
    } catch (_) {}
  }
}
