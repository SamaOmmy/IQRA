import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import 'audio.dart';
import 'cover_art.dart';
import 'notify.dart';
import 'quran.dart';

/// Shows what is playing in the phone's notification and on the lock screen: the surah's cover, its name in Arabic and Latin
/// letters, the verse and the reciter, with previous / play-pause / next, a seek bar and three extra buttons (repeat the verse,
/// speed, bookmark). It also keeps the recitation going when the app is left. Android only.
class IqraMediaSession extends BaseAudioHandler with SeekHandler {
  IqraMediaSession(this._audio) {
    _audio.addListener(_sync);
    _audio.tick.addListener(_onTick);
  }
  final AudioController _audio;

  /// What happened when the media session was started, shown in Settings so a problem can be seen and fixed on the phone.
  static final ValueNotifier<String> status = ValueNotifier('Not started');

  int? _s, _a;
  bool? _playing, _loading;
  Duration _length = Duration.zero;
  int _lastPush = 0, _lastTick = 0;
  bool _askedPermission = false;
  final Map<int, Uri?> _art = {};

  static Future<void> start(AudioController audio) async {
    if (!Platform.isAndroid) return;
    try {
      await AudioService.init(
        builder: () => IqraMediaSession(audio),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.samaommy.iqra.recitation',
          androidNotificationChannelName: 'Recitation',
          androidNotificationChannelDescription: 'The recitation that is playing, with its controls',
          androidNotificationIcon: 'drawable/ic_stat_iqra',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
          androidShowNotificationBadge: false,
        ),
      );
      status.value = 'Ready';
    } catch (e) {
      status.value = 'Could not start: $e';
      debugPrint('media session failed: $e');
    }
  }

  List<MediaControl> _controls() => [
        MediaControl.skipToPrevious,
        _audio.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.custom(androidIcon: 'drawable/ic_np_repeat', label: 'Repeat verse', name: 'repeat'),
        MediaControl.custom(androidIcon: 'drawable/ic_np_speed', label: 'Speed', name: 'speed'),
        MediaControl.custom(androidIcon: 'drawable/ic_np_bookmark', label: 'Bookmark', name: 'bookmark'),
      ];

  void _publishItem(int s, int a) {
    final sr = Quran.I.surah(s);
    final cover = _art[s];
    mediaItem.add(MediaItem(
      id: '$s:$a',
      title: '${sr.en} · ${sr.ar}',
      artist: 'Verse $a of ${sr.ayahs.length} · ${reciterName(_audio.store.reciter)}',
      album: '${sr.meaning} · IQRA',
      genre: "Qur'an",
      duration: _audio.duration,
      artUri: cover,
    ));
    if (!_art.containsKey(s)) {
      _art[s] = null;
      coverArt(s).then((uri) {
        _art[s] = uri;
        final c = _audio.current;
        if (uri != null && c != null && c.s == s) _publishItem(c.s, c.a);
      });
    }
  }

  void _pushState() {
    _playing = _audio.playing;
    _loading = _audio.loading;
    _lastPush = DateTime.now().millisecondsSinceEpoch;
    playbackState.add(PlaybackState(
      controls: _controls(),
      systemActions: const {MediaAction.seek, MediaAction.skipToNext, MediaAction.skipToPrevious, MediaAction.play, MediaAction.pause},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _audio.loading ? AudioProcessingState.loading : AudioProcessingState.ready,
      playing: _audio.playing,
      updatePosition: _audio.position,
      speed: _audio.store.speed,
    ));
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
    final verseChanged = c.s != _s || c.a != _a;
    final stateChanged = _playing != _audio.playing || _loading != _audio.loading;
    if (verseChanged) {
      _s = c.s;
      _a = c.a;
      _length = _audio.duration;
      _publishItem(c.s, c.a);
    }
    if (verseChanged || stateChanged) _pushState();
  }

  /// The player reports its position about ten times a second: look at it once a second, to learn the verse's length once it is
  /// known and to keep the notification's clock honest now and then.
  void _onTick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTick < 1000) return;
    _lastTick = now;
    final c = _audio.current;
    if (c == null) return;
    if ((_audio.duration - _length).inMilliseconds.abs() > 400) {
      _length = _audio.duration;
      _publishItem(c.s, c.a);
      _pushState();
    } else if (now - _lastPush > 5000) {
      _pushState();
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

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    final c = _audio.current;
    switch (name) {
      case 'repeat':
        _audio.setRepeat(_audio.repeatEach > 1 ? 1 : 3);
      case 'speed':
        const steps = [0.75, 1.0, 1.25, 1.5];
        final i = steps.indexWhere((x) => (x - _audio.store.speed).abs() < 0.01);
        await _audio.setSpeed(steps[(i + 1) % steps.length]);
      case 'bookmark':
        if (c != null) _audio.store.toggleBookmark(c.s, c.a);
    }
    _pushState();
  }
}
