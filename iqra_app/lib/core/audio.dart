import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'quran.dart';
import 'store.dart';

enum PlayScope { verse, surah, continuous, page }

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
  final _http = http.Client();

  VerseRef? current;
  bool playing = false;
  bool loading = false;
  String? error;
  Duration position = Duration.zero, duration = Duration.zero;
  PlayScope scope = PlayScope.continuous;
  int? pageScope;
  int repeatEach = 1; // memorisation: how many times each verse repeats
  int _repeatDone = 0;
  Timer? _sleep;
  DateTime? sleepAt;
  int _token = 0;

  bool get active => current != null;
  Ayah? get ayah => current == null ? null : Quran.I.ayah(current!.s, current!.a);
  double get progress => duration.inMilliseconds == 0 ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1).toDouble();

  static String _file(int s, int a) => '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  Future<File> _local(String reciter, int s, int a) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/audio/$reciter');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${_file(s, a)}');
  }

  Future<String> _ensure(String reciter, int s, int a) async {
    final f = await _local(reciter, s, a);
    if (await f.exists() && await f.length() > 1024) return f.path;
    final res = await _http.get(Uri.parse('https://everyayah.com/data/$reciter/${_file(s, a)}'));
    if (res.statusCode != 200) throw Exception('Audio unavailable (${res.statusCode}). Check your connection.');
    final tmp = File('${f.path}.part');
    await tmp.writeAsBytes(res.bodyBytes, flush: true);
    await tmp.rename(f.path);
    return f.path;
  }

  Future<void> playVerse(int s, int a, {PlayScope? scope, int? page}) async {
    if (scope != null) this.scope = scope;
    pageScope = page;
    final token = ++_token;
    current = VerseRef(s, a);
    error = null;
    loading = true;
    _repeatDone = 0;
    notifyListeners();
    store.setLast(s, a, Quran.I.ayah(s, a).page);
    try {
      final path = await _ensure(store.reciter, s, a);
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

  void _prefetch(int s, int a) {
    var n = VerseRef(s, a);
    for (var i = 0; i < 2; i++) {
      final nx = Quran.I.next(n.s, n.a);
      if (nx == null) return;
      n = nx;
      _ensure(store.reciter, n.s, n.a).catchError((_) => '');
    }
  }

  VerseRef? _after(VerseRef v) {
    final nx = Quran.I.next(v.s, v.a);
    if (nx == null) return null;
    switch (scope) {
      case PlayScope.verse:
        return null;
      case PlayScope.surah:
        return nx.s == v.s ? nx : null;
      case PlayScope.page:
        return pageScope != null && Quran.I.ayah(nx.s, nx.a).page == pageScope ? nx : null;
      case PlayScope.continuous:
        return nx;
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

  /// Stops playback after [minutes]; pass 0 to cancel. A negative value means "at the end of this verse".
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
    _http.close();
    super.dispose();
  }
}
