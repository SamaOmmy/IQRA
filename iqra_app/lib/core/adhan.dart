import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// Plays the adhan while the app is open (Windows reminders and the settings preview). On Android, scheduled reminders use
/// the same recording as the notification sound, so they play even when the app is closed.
class AdhanPlayer {
  static Player? _player;

  static const files = ['adhan.mp3', 'adhan_2.ogg', 'adhan_3.ogg'];

  static Future<void> play({int sound = 2}) async {
    try {
      _player ??= Player();
      await _player!.open(Media('asset:///assets/audio/${files[(sound - 1).clamp(0, files.length - 1)]}'));
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
