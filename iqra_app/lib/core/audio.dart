import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import 'audio_cache.dart';
import 'quran.dart';
import 'store.dart';
import 'surah_track.dart';

enum PlayScope { verse, surah, continuous, page, queue, range }

/// Recitation. Where the reciter has a whole-surah recording the surah plays as one connected piece, as the reciter delivered it,
/// with the current verse found from its timings. Otherwise each verse is downloaded once from everyayah.com and played from disk.
class AudioController extends ChangeNotifier {
  AudioController(this.store) {
    player = Player();
    player.setRate(store.speed);
    _subs.add(player.stream.position.listen((p) {
      final t = _track, c = current;
      if (t != null && c != null) {
        _rawMs = p.inMilliseconds;
        final v = t.verseAt(_rawMs);
        if (v != c.a) {
          current = VerseRef(c.s, v);
          store.setLast(c.s, v, Quran.I.ayah(c.s, v).page);
        }
        position = Duration(milliseconds: math.max(0, _rawMs - t.from[v - 1]));
        duration = Duration(milliseconds: t.to[v - 1] - t.from[v - 1]);
      } else {
        position = p;
      }
      _clock
        ..reset()
        ..start();
      notifyListeners();
    }));
    _subs.add(player.stream.duration.listen((d) {
      if (_track != null) return; // the verse's own length is shown instead
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

  /// the whole-surah recording being played (null when verses are played one by one)
  SurahTrack? _track;
  String? _trackReciter;
  int _rawMs = 0;
  bool get connected => _track != null;

  final Stopwatch _clock = Stopwatch();

  /// Where playback is inside the current verse right now: the last reported position plus the time since it was reported,
  /// so words can be lit smoothly between the player's position updates.
  Duration get livePosition {
    if (!playing || !_clock.isRunning) return position;
    final p = position + Duration(milliseconds: (_clock.elapsedMilliseconds * store.speed).round());
    return duration > Duration.zero && p > duration ? duration : p;
  }

  /// How far the recitation has got through the words of this verse, in words (3.4 = forty per cent through the fourth word).
  /// Uses the reciter's own word timing when the recording has it, otherwise an estimate from word lengths. Null if not playing this verse.
  double? wordCursor(int surah, int ayah, List<double> weights) {
    final c = current;
    if (c == null || c.s != surah || c.a != ayah || weights.isEmpty) return null;
    final live = livePosition;
    final t = _track;
    if (t != null) {
      final segs = t.words[ayah - 1];
      if (segs.isNotEmpty) {
        final ms = t.from[ayah - 1] + live.inMilliseconds;
        var cursor = 0.0;
        for (final s in segs) {
          final i = s[0] - 1;
          if (ms >= s[2]) {
            cursor = math.max(cursor, i + 1.0);
          } else if (ms >= s[1]) {
            cursor = math.max(cursor, i + (ms - s[1]) / math.max(1, s[2] - s[1]));
          }
        }
        return cursor.clamp(0, weights.length.toDouble()).toDouble();
      }
    }
    if (duration.inMilliseconds <= 0) return 0;
    final total = weights.fold<double>(0, (a, b) => a + b);
    // the recording has a little silence before and after the words
    final p = ((live.inMilliseconds / duration.inMilliseconds - 0.035) / 0.93).clamp(0.0, 1.0);
    var acc = 0.0;
    for (var i = 0; i < weights.length; i++) {
      final w = weights[i] / total;
      if (p < acc + w) return i + (p - acc) / w;
      acc += w;
    }
    return weights.length.toDouble();
  }

  /// Index of the word being recited in this verse, from the reciter's own timing, or -1 when only an estimate is possible.
  int exactWord(int surah, int ayah) {
    final t = _track, c = current;
    if (t == null || c == null || c.s != surah || c.a != ayah) return -1;
    return t.wordAt(ayah, _rawMs);
  }

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
    final lt = _track;
    if (lt != null && (lt.surah != s || _trackReciter != store.reciter)) _track = null; // old positions must not be read against a new surah
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
    final wantTrack = store.wholeSurah && repeatEach <= 1 && (this.scope == PlayScope.continuous || this.scope == PlayScope.surah || this.scope == PlayScope.queue);
    if (wantTrack) {
      if (await _playTrack(s, a, token)) return;
      if (token != _token) return;
    }
    _track = null;
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

  /// Plays from verse [a] inside the whole-surah recording. Returns false when that is not possible (then verses are played one by one).
  Future<bool> _playTrack(int s, int a, int token) async {
    try {
      var t = _track;
      final same = t != null && t.surah == s && _trackReciter == store.reciter;
      if (!same) {
        t = await SurahTrack.load(store.reciter, s);
        if (token != _token) return true;
        if (t == null || t.verses != Quran.I.surah(s).ayahs.length) return false;
        _track = null; // positions of the previous recording must not be read as this one's
        await player.open(Media(t.url), play: false);
        if (token != _token) return true;
        await player.stream.duration.firstWhere((d) => d > Duration.zero).timeout(const Duration(seconds: 15));
        if (token != _token) return true;
        _track = t;
        _trackReciter = store.reciter;
      }
      await player.seek(Duration(milliseconds: a <= 1 ? 0 : t.from[a - 1]));
      await player.setRate(store.speed);
      await player.play();
      loading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _track = null;
      return false;
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
    if (_track != null) {
      // the recording ended: carry on with the next surah if the mode says so
      final last = VerseRef(c.s, _track!.verses);
      final nx = _after(last);
      _track = null;
      if (nx != null) {
        await playVerse(nx.s, nx.a);
      } else {
        playing = false;
        notifyListeners();
      }
      return;
    }
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
    final t = _track;
    if (t != null && c.a < t.verses) {
      await player.seek(Duration(milliseconds: t.from[c.a]));
      return;
    }
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
    final t = _track;
    if (t != null) {
      if (position > const Duration(seconds: 3) || c.a <= 1) {
        await player.seek(Duration(milliseconds: c.a <= 1 ? 0 : t.from[c.a - 1]));
        return;
      }
      await player.seek(Duration(milliseconds: t.from[c.a - 2]));
      return;
    }
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

  Future<void> seekFraction(double f) {
    final t = _track, c = current;
    if (t != null && c != null) return player.seek(Duration(milliseconds: t.from[c.a - 1] + ((t.to[c.a - 1] - t.from[c.a - 1]) * f).round()));
    return player.seek(Duration(milliseconds: (duration.inMilliseconds * f).round()));
  }

  Future<void> setSpeed(double v) async {
    store.speed = v;
    await player.setRate(v);
    notifyListeners();
  }

  void setRepeat(int n) {
    repeatEach = n;
    notifyListeners();
    // repeating one verse needs the verse recordings
    final c = current;
    if (n > 1 && _track != null && c != null) playVerse(c.s, c.a);
  }

  Future<void> stop() async {
    _token++;
    _track = null;
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
