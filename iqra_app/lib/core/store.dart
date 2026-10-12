import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran.dart';

class Place {
  const Place(this.name, this.country, this.lat, this.lon, this.tz);
  final String name, country, tz;
  final double lat, lon;
  Map<String, dynamic> toJson() => {'name': name, 'country': country, 'lat': lat, 'lon': lon, 'tz': tz};
  static Place fromJson(Map<String, dynamic> j) =>
      Place(j['name'], j['country'] ?? '', (j['lat'] as num).toDouble(), (j['lon'] as num).toDouble(), j['tz'] ?? 'UTC');
}

class Bookmark {
  Bookmark(this.s, this.a, this.at);
  final int s, a;
  final int at;
}

/// Everything the person changes: settings, bookmarks, notes, progress. Saved as one JSON document.
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs, Map<String, dynamic> j) : _j = j;

  static const _key = 'iqra-flutter-state';
  final SharedPreferences _prefs;
  final Map<String, dynamic> _j;
  Timer? _saveTimer;

  static Future<AppStore> open() async {
    final p = await SharedPreferences.getInstance();
    Map<String, dynamic> j = {};
    try {
      j = (jsonDecode(p.getString(_key) ?? '{}') as Map).cast<String, dynamic>();
    } catch (_) {}
    return AppStore._(p, j);
  }

  T _get<T>(String k, T def) => _j.containsKey(k) && _j[k] is T ? _j[k] as T : def;
  void _set(String k, Object? v) {
    _j[k] = v;
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () => _prefs.setString(_key, jsonEncode(_j)));
  }

  // ---- appearance ----
  String get theme => _get('theme', 'auto');
  set theme(String v) => _set('theme', v);
  int get accent => _get('accent', 0); // 0 = the theme's own colour, else ARGB
  set accent(int v) => _set('accent', v);
  bool get motion => _get('motion', true);
  set motion(bool v) => _set('motion', v);
  double get arabicSize => _get<num>('arSize', 30).toDouble();
  set arabicSize(double v) => _set('arSize', v);
  double get translationSize => _get<num>('trSize', 16).toDouble();
  set translationSize(double v) => _set('trSize', v);
  bool get showTranslation => _get('showTr', true);
  set showTranslation(bool v) => _set('showTr', v);
  bool get wordByWord => _get('wbw', false);
  set wordByWord(bool v) => _set('wbw', v);
  bool get mushafView => _get('mushafView', true);
  set mushafView(bool v) => _set('mushafView', v);

  // ---- reading ----
  String get translationId => _get('tr1', 'en.sahih');
  set translationId(String v) => _set('tr1', v);
  String get tafsirId => _get('tafsir', 'en-al-jalalayn');
  set tafsirId(String v) => _set('tafsir', v);
  int get lastSurah => _get('surah', 1);
  int get lastAyah => _get('ayah', 1);
  int get lastPage => _get('page', 1);
  void setLast(int s, int a, int page) {
    _j['surah'] = s;
    _j['ayah'] = a;
    _j['page'] = page;
    _set('lastAt', DateTime.now().millisecondsSinceEpoch);
  }

  bool get hasStartedReading => _j.containsKey('surah');

  // ---- audio ----
  String get reciter => _get('reciter', kReciters.first.$1);
  set reciter(String v) => _set('reciter', v);
  double get speed => _get<num>('speed', 1).toDouble();
  set speed(double v) => _set('speed', v);
  bool get continuous => _get('continuous', true);
  set continuous(bool v) => _set('continuous', v);

  // ---- bookmarks, favourites, notes ----
  List<VerseRef> get bookmarks => [for (final k in _get<List>('bookmarks', const [])) VerseRef.parse(k as String)];
  bool isBookmarked(int s, int a) => _get<List>('bookmarks', const []).contains('$s:$a');
  void toggleBookmark(int s, int a) {
    final list = List<String>.from(_get<List>('bookmarks', const []));
    final k = '$s:$a';
    list.contains(k) ? list.remove(k) : list.insert(0, k);
    _set('bookmarks', list);
  }

  List<String> get favs => List<String>.from(_get<List>('favs', const []));
  bool isFav(String key) => favs.contains(key);
  void toggleFav(String key) {
    final l = favs;
    l.contains(key) ? l.remove(key) : l.insert(0, key);
    _set('favs', l);
  }

  Map<String, String> get notes => Map<String, String>.from(_get<Map>('notes', const {}));
  String noteFor(int s, int a) => notes['$s:$a'] ?? '';
  void setNote(int s, int a, String text) {
    final n = notes;
    text.trim().isEmpty ? n.remove('$s:$a') : n['$s:$a'] = text.trim();
    _set('notes', n);
  }

  // ---- progress ----
  /// ayahs read at least once: "s:a" -> true, stored as a list of keys
  Set<String> get readSet => Set<String>.from(_get<List>('read', const []));
  Map<String, int> get daysRead => Map<String, int>.from(_get<Map>('days', const {}));
  int get dailyGoalPages => _get('goal', 2);
  set dailyGoalPages(int v) => _set('goal', v);
  int get khatams => _get('khatams', 0);

  void markPageRead(int page) {
    final set = Set<int>.from(_get<List>('pagesRead', const []).cast<int>());
    final added = set.add(page);
    final days = daysRead;
    final today = todayKey();
    if (added) days[today] = (days[today] ?? 0) + 1;
    _j['pagesRead'] = set.toList();
    _j['days'] = days;
    if (set.length >= 604) {
      _j['khatams'] = khatams + 1;
      _j['pagesRead'] = <int>[];
    }
    _set('pagesReadAt', DateTime.now().millisecondsSinceEpoch);
  }

  Set<int> get pagesRead => Set<int>.from(_get<List>('pagesRead', const []).cast<int>());

  int get streak {
    final days = daysRead;
    var d = DateTime.now();
    var n = 0;
    if (!days.containsKey(todayKey(d))) d = d.subtract(const Duration(days: 1));
    while (days.containsKey(todayKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---- prayer ----
  Place? get place {
    final p = _get<Map?>('place', null);
    return p == null ? null : Place.fromJson(p.cast<String, dynamic>());
  }

  set place(Place? v) => _set('place', v?.toJson());
  String get prayerMethod => _get('pmethod', 'mwl');
  set prayerMethod(String v) => _set('pmethod', v);
  bool get hanafi => _get('hanafi', false);
  set hanafi(bool v) => _set('hanafi', v);
  bool get clock24 => _get('clock24', false);
  set clock24(bool v) => _set('clock24', v);
  bool get notifyPrayers => _get('notify', false);
  set notifyPrayers(bool v) => _set('notify', v);

  // Salah tracker: date key -> list of prayer keys marked as prayed.
  Map<String, List<String>> get salah => {
        for (final e in _get<Map>('salah', const {}).entries) e.key as String: List<String>.from(e.value as List),
      };
  void toggleSalah(String day, String prayer) {
    final all = salah;
    final l = all.putIfAbsent(day, () => []);
    l.contains(prayer) ? l.remove(prayer) : l.add(prayer);
    if (l.isEmpty) all.remove(day);
    _set('salah', all);
  }

  // ---- tasbih ----
  int get tasbihCount => _get('tasbih', 0);
  set tasbihCount(int v) => _set('tasbih', v);
  int get tasbihTarget => _get('tasbihTarget', 33);
  set tasbihTarget(int v) => _set('tasbihTarget', v);
  int get tasbihTotal => _get('tasbihTotal', 0);
  void tasbihTap() {
    _j['tasbihTotal'] = tasbihTotal + 1;
    tasbihCount = tasbihCount + 1;
  }

  // ---- hifz ----
  bool get hifzMode => _get('hifz', false);
  set hifzMode(bool v) => _set('hifz', v);
  Set<String> get memorised => Set<String>.from(_get<List>('memorised', const []));
  void toggleMemorised(String key) {
    final s = memorised;
    s.contains(key) ? s.remove(key) : s.add(key);
    _set('memorised', s.toList());
  }

  // ---- misc ----
  int get quizBest => _get('quizBest', 0);
  set quizBest(int v) => _set('quizBest', v);
  bool get seenWelcome => _get('welcome', false);
  set seenWelcome(bool v) => _set('welcome', v);
  List<String> get recentSearches => List<String>.from(_get<List>('recent', const []));
  void addSearch(String q) {
    final l = recentSearches..remove(q);
    l.insert(0, q);
    _set('recent', l.take(8).toList());
  }
}

String todayKey([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
