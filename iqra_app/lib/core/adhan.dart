import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// Plays the adhan while the app is open (Windows reminders and the settings preview). On Android, scheduled reminders use
/// the same recording as the notification sound, so they play even when the app is closed.
class AdhanPlayer {
  static Player? _player;

  static Future<void> play() async {
    try {
      _player ??= Player();
      await _player!.open(Media('asset:///assets/audio/adhan.mp3'));
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
