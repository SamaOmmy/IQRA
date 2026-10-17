import 'dart:io';

import 'package:audio_service/audio_service.dart';

import 'audio.dart';
import 'notify.dart';
import 'quran.dart';

/// Shows what is playing in the phone's notification and on the lock screen, with play / pause, previous and next,
/// and keeps the recitation going when the app is left. Android only.
class IqraMediaSession extends BaseAudioHandler with SeekHandler {
  IqraMediaSession(this._audio) {
    _audio.addListener(_sync);
  }
  final AudioController _audio;

  int? _s, _a;
  bool? _playing, _loading;
  Duration _length = Duration.zero;
  int _lastPush = 0;
  bool _askedPermission = false;

  static Future<void> start(AudioController audio) async {
    if (!Platform.isAndroid) return;
    try {
      await AudioService.init(
        builder: () => IqraMediaSession(audio),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.samaommy.iqra.recitation',
          androidNotificationChannelName: 'Recitation',
          androidNotificationIcon: 'drawable/ic_stat_iqra',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
        ),
      );
    } catch (_) {}
  }

  void _sync() {
    final c = _audio.current;
    if (c == null) {
      if (_s != null) {
        _s = _a = null;
        mediaItem.add(null);
        playbackState.add(PlaybackState(processingState: AudioProcessingState.idle, playing: false));
      }
      return;
    }
    if (_audio.playing && !_askedPermission) {
      // Android 13+ shows the notification and lock-screen controls only once notifications are allowed
      _askedPermission = true;
      PrayerNotifier.requestPermission();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final verseChanged = c.s != _s || c.a != _a;
    final stateChanged = _playing != _audio.playing || _loading != _audio.loading;
    final durationChanged = (_audio.duration - _length).inMilliseconds.abs() > 400;
    if (verseChanged || durationChanged) {
      _s = c.s;
      _a = c.a;
      _length = _audio.duration;
      final sr = Quran.I.surah(c.s);
      mediaItem.add(MediaItem(id: '${c.s}:${c.a}', title: '${sr.en} · verse ${c.a}', album: '${sr.meaning} · ${sr.ayahs.length} verses', artist: reciterName(_audio.store.reciter), duration: _audio.duration));
    }
    // the position moves by itself between updates, so the notification is refreshed only when something changes (or now and then)
    if (verseChanged || stateChanged || now - _lastPush > 4000) {
      _playing = _audio.playing;
      _loading = _audio.loading;
      _lastPush = now;
      playbackState.add(PlaybackState(
        controls: [MediaControl.skipToPrevious, _audio.playing ? MediaControl.pause : MediaControl.play, MediaControl.skipToNext, MediaControl.stop],
        systemActions: const {MediaAction.seek, MediaAction.skipToNext, MediaAction.skipToPrevious, MediaAction.play, MediaAction.pause},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _audio.loading ? AudioProcessingState.loading : AudioProcessingState.ready,
        playing: _audio.playing,
        updatePosition: _audio.position,
        speed: _audio.store.speed,
      ));
    }
  }

  @override
  Future<void> play() async {
    if (!_audio.playing) await _audio.toggle();
  }

  @override
  Future<void> pause() async {
    if (_audio.playing) await _audio.toggle();
  }

  @override
  Future<void> skipToNext() => _audio.next();

  @override
  Future<void> skipToPrevious() => _audio.previous();

  @override
  Future<void> stop() async {
    await _audio.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_audio.duration.inMilliseconds > 0) await _audio.seekFraction(position.inMilliseconds / _audio.duration.inMilliseconds);
  }
}
