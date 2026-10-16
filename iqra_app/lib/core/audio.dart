import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import 'audio_cache.dart';
import 'quran.dart';
import 'store.dart';

enum PlayScope { verse, surah, continuous, page, queue, range }

/// Verse-by-verse recitation. Each verse is downloaded once from everyayah.com into the app's folder, then played from disk.
class AudioController extends ChangeNotifier {
  AudioController(this.store) {
    player = Player();
    player.setRate(store.speed);
    _subs.add(player.stream.position.listen((p) {
      position = p;
      notifyListeners();
    }));
    _subs.add(player.stream.duration.listen((d) {
      duration = d;
      notifyListeners();
    }));
    _subs.add(player.stream.playing.listen((v) {
      playing = v;
      notifyListeners();
    }));
    _subs.add(player.stream.completed.listen((done) {
      if (done) _onCompleted();
    }));
  }

  final AppStore store;
  late final Player player;
  final _subs = <StreamSubscription>[];

  VerseRef? current;
  bool playing = false;
  bool loading = false;
  String? error;
  Duration position = Duration.zero, duration = Duration.zero;
  PlayScope scope = PlayScope.continuous;
  int? pageScope;

  /// memorisation: how many times each verse repeats before moving on
  int repeatEach = 1;
  int _repeatDone = 0;

  /// a playlist of whole surahs
  List<int> queue = const [];
  int queueIndex = 0;
  String? queueTitle;

  /// a looped range of verses within one surah (repeatCount 0 = until stopped)
  int rangeFrom = 1, rangeTo = 1, rangeRepeats = 1, _rangeDone = 0;

  Timer? _sleep;
  DateTime? sleepAt;
  int _token = 0;

  bool get active => current != null;
  Ayah? get ayah => current == null ? null : Quran.I.ayah(current!.s, current!.a);
  double get progress => duration.inMilliseconds == 0 ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1).toDouble();

  Future<void> playVerse(int s, int a, {PlayScope? scope, int? page}) async {
    if (scope != null) this.scope = scope;
    if (scope != PlayScope.queue) {
      queue = const [];
      queueTitle = null;
    }
    pageScope = page;
    final token = ++_token;
    final previous = current;
    current = VerseRef(s, a);
    error = null;
    loading = true;
    _repeatDone = 0;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
    store.setLast(s, a, Quran.I.ayah(s, a).page);
    if (previous == null || previous.s != s) store.pushRecentSurah(s);
    try {
      final path = await AudioCache.ensure(store.reciter, s, a);
      if (token != _token) return;
      await player.open(Media(Uri.file(path).toString()), play: true);
      await player.setRate(store.speed);
      loading = false;
      notifyListeners();
      _prefetch(s, a);
    } catch (e) {
      if (token != _token) return;
      loading = false;
      playing = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Plays whole surahs one after another.
  Future<void> playQueue(List<int> surahs, {String? title, int from = 0}) async {
    if (surahs.isEmpty) return;
    queue = List<int>.of(surahs);
    queueIndex = from.clamp(0, surahs.length - 1);
    queueTitle = title;
    await playVerse(queue[queueIndex], 1, scope: PlayScope.queue);
  }

  /// Loops verses [from]..[to] of a surah, [repeats] times (0 = until stopped).
  Future<void> playRange(int surah, int from, int to, {int repeats = 0}) async {
    rangeFrom = from;
    rangeTo = to;
    rangeRepeats = repeats;
    _rangeDone = 0;
    await playVerse(surah, from, scope: PlayScope.range);
  }

  void _prefetch(int s, int a) {
    var n = VerseRef(s, a);
    for (var i = 0; i < 2; i++) {
      final nx = Quran.I.next(n.s, n.a);
      if (nx == null) return;
      n = nx;
      AudioCache.ensure(store.reciter, n.s, n.a).catchError((_) => '');
    }
  }

  VerseRef? _after(VerseRef v) {
    switch (scope) {
      case PlayScope.verse:
        return null;
      case PlayScope.surah:
        final nx = Quran.I.next(v.s, v.a);
        return nx != null && nx.s == v.s ? nx : null;
      case PlayScope.page:
        final nx = Quran.I.next(v.s, v.a);
        return nx != null && pageScope != null && Quran.I.ayah(nx.s, nx.a).page == pageScope ? nx : null;
      case PlayScope.continuous:
        return Quran.I.next(v.s, v.a);
      case PlayScope.queue:
        final nx = Quran.I.next(v.s, v.a);
        if (nx != null && nx.s == v.s) return nx;
        if (queueIndex + 1 < queue.length) {
          queueIndex++;
          return VerseRef(queue[queueIndex], 1);
        }
        return null;
      case PlayScope.range:
        if (v.a < rangeTo) return VerseRef(v.s, v.a + 1);
        _rangeDone++;
        if (rangeRepeats == 0 || _rangeDone < rangeRepeats) return VerseRef(v.s, rangeFrom);
        return null;
    }
  }

  Future<void> _onCompleted() async {
    final c = current;
    if (c == null) return;
    if (_repeatDone + 1 < repeatEach) {
      _repeatDone++;
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    final nx = _after(c);
    if (nx != null) {
      await playVerse(nx.s, nx.a);
    } else {
      playing = false;
      notifyListeners();
    }
  }

  Future<void> next() async {
    final c = current;
    if (c == null) return;
    if (scope == PlayScope.queue) {
      final nx = Quran.I.next(c.s, c.a);
      if (nx != null && nx.s == c.s) {
        await playVerse(nx.s, nx.a);
      } else if (queueIndex + 1 < queue.length) {
        queueIndex++;
        await playVerse(queue[queueIndex], 1);
      }
      return;
    }
    final nx = Quran.I.next(c.s, c.a);
    if (nx != null) await playVerse(nx.s, nx.a);
  }

  Future<void> previous() async {
    final c = current;
    if (c == null) return;
    if (position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }
    final pv = Quran.I.previous(c.s, c.a);
    if (pv != null) await playVerse(pv.s, pv.a);
  }

  /// Jumps to the first verse of the next / previous surah (skip in a playlist).
  Future<void> nextSurah() async {
    final c = current;
    if (c == null) return;
    if (scope == PlayScope.queue && queueIndex + 1 < queue.length) {
      queueIndex++;
      await playVerse(queue[queueIndex], 1);
    } else if (c.s < 114) {
      await playVerse(c.s + 1, 1);
    }
  }

  Future<void> previousSurah() async {
    final c = current;
    if (c == null) return;
    if (scope == PlayScope.queue && queueIndex > 0) {
      queueIndex--;
      await playVerse(queue[queueIndex], 1);
    } else if (c.s > 1) {
      await playVerse(c.s - 1, 1);
    }
  }

  Future<void> toggle() async {
    if (current == null) return;
    if (error != null || (!playing && position == Duration.zero && duration == Duration.zero)) {
      await playVerse(current!.s, current!.a);
    } else {
      await player.playOrPause();
    }
  }

  Future<void> seekFraction(double f) => player.seek(Duration(milliseconds: (duration.inMilliseconds * f).round()));

  Future<void> setSpeed(double v) async {
    store.speed = v;
    await player.setRate(v);
    notifyListeners();
  }

  void setRepeat(int n) {
    repeatEach = n;
    notifyListeners();
  }

  Future<void> stop() async {
    _token++;
    await player.stop();
    current = null;
    playing = false;
    notifyListeners();
  }

  /// Stops playback after [minutes]; pass 0 to cancel.
  void sleepIn(int minutes) {
    _sleep?.cancel();
    sleepAt = null;
    if (minutes > 0) {
      sleepAt = DateTime.now().add(Duration(minutes: minutes));
      _sleep = Timer(Duration(minutes: minutes), () async {
        await player.pause();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _sleep?.cancel();
    player.dispose();
    super.dispose();
  }
}
