import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import 'audio.dart';

/// Plays nicely with the rest of the phone: the recitation pauses for a call or another app's audio and carries on afterwards,
/// pauses when headphones are unplugged (so it never suddenly comes out of the speaker), and asks for the audio focus when it starts.
class AudioFocus {
  static Future<void> start(AudioController audio) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      var pausedByUs = false;
      session.interruptionEventStream.listen((e) {
        if (e.begin) {
          switch (e.type) {
            case AudioInterruptionType.duck:
              audio.player.setVolume(35);
            case AudioInterruptionType.pause || AudioInterruptionType.unknown:
              if (audio.playing) {
                pausedByUs = true;
                audio.player.pause();
              }
          }
        } else {
          switch (e.type) {
            case AudioInterruptionType.duck:
              audio.player.setVolume(100);
            case AudioInterruptionType.pause:
              if (pausedByUs) audio.player.play();
              pausedByUs = false;
            case AudioInterruptionType.unknown:
              pausedByUs = false; // the other audio ended for good: stay paused
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        if (audio.playing) audio.player.pause();
      });
      var active = false;
      audio.addListener(() {
        if (audio.playing && !active) {
          active = true;
          session.setActive(true);
        } else if (!audio.playing && audio.current == null && active) {
          active = false;
          session.setActive(false);
        }
      });
    } catch (e) {
      debugPrint('audio focus not available: $e');
    }
  }
}
