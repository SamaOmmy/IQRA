import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// Plays the adhan while the app is open (Windows reminders and the settings preview). On Android, scheduled reminders use
/// the same recording as the notification sound, so they play even when the app is closed.
class AdhanPlayer {
  static Player? _player;

  static const names = ['Madinah', 'Casablanca', 'Ramadan', 'Calm', 'Classic'];

  /// [sound] 1..5 is one of the recordings; 0 plays the file at [file] (one the person picked).
  static Future<void> play({int sound = 1, String? file}) async {
    try {
      _player ??= Player();
      final src = sound == 0 && file != null ? Media(file) : Media('asset:///assets/audio/adhan_${sound.clamp(1, 5)}.ogg');
      await _player!.open(src);
    } catch (e) {
      debugPrint('could not play the adhan: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
