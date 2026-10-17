import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hijri_events.dart';
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
  AppStore._(this._prefs, Map<String, dynamic> j) : _j = j {
    hijriShiftDays = (j['hadj'] as num?)?.toInt() ?? 0;
  }

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
  /// Visual effects: 0 automatic (lightened by itself on a device that drops frames), 1 always full, 2 light.
  int get effects => _get<num>('effects', 0).toInt();
  set effects(int v) => _set('effects', v);
  void notifyEffects() => notifyListeners();
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
  /// How big the mushaf pages are drawn: 1 fits the window, larger values use the room to the sides and scroll up and down.
  double get mushafZoom => _get<num>('mushafZoom', 1.0).toDouble();
  set mushafZoom(double v) => _set('mushafZoom', v);
  /// Reading without the header, so the page gets the whole height (on by default on the computer).
  bool get readerFocus => _get('readerFocus', defaultTargetPlatform != TargetPlatform.android);
  set readerFocus(bool v) => _set('readerFocus', v);

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
    if (_get<Map?>('plan', null) != null) {
      final pr = Set<int>.from(_get<List>('planRead', const []).cast<int>())..add(page);
      _j['planRead'] = pr.toList();
    }
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
  /// Minutes added to (or taken from) each calculated prayer time, for matching a local timetable.
  Map<String, int> get prayerAdjust => {for (final e in _get<Map>('padj', const {}).entries) e.key as String: (e.value as num).toInt()};
  void setPrayerAdjust(String key, int minutes) {
    final m = prayerAdjust..[key] = minutes.clamp(-30, 30);
    _set('padj', m);
  }

  /// Prayers that sound a reminder or the adhan (all five unless switched off).
  Set<String> get alertPrayers => Set<String>.from(_get<List>('alertp', const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']));
  void setAlert(String key, bool on) {
    final s = alertPrayers;
    on ? s.add(key) : s.remove(key);
    _set('alertp', s.toList());
  }

  /// Hijri date correction in days (the calculated date can differ from your local moon sighting by a day).
  int get hijriAdjust => _get<num>('hadj', 0).toInt();
  set hijriAdjust(int v) {
    hijriShiftDays = v.clamp(-2, 2);
    _set('hadj', hijriShiftDays);
  }

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
    final added = !s.contains(key);
    added ? s.add(key) : s.remove(key);
    if (added) {
      final r = Map<String, dynamic>.from(_get<Map>('review', const {}));
      final t = DateTime.now();
      r[key] = {'last': DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000, 'lvl': 0};
      _j['review'] = r;
    }
    _set('memorised', s.toList());
  }

  // ---- listening ----
  List<int> get recentSurahs => List<int>.from(_get<List>('recentSurahs', const []).cast<int>());
  void pushRecentSurah(int s) {
    final l = recentSurahs..remove(s);
    l.insert(0, s);
    _set('recentSurahs', l.take(12).toList());
  }

  // ---- khatam plan ----
  Map<String, dynamic>? get plan {
    final p = _get<Map?>('plan', null);
    return p?.cast<String, dynamic>();
  }

  void setPlan(DateTime start, int days) {
    _j['planRead'] = <int>[];
    _set('plan', {'start': todayKey(start), 'days': days});
  }

  void clearPlan() {
    _j['planRead'] = <int>[];
    _set('plan', null);
  }

  Set<int> get planRead => Set<int>.from(_get<List>('planRead', const []).cast<int>());

  // ---- stories ----
  Set<String> get storiesRead => Set<String>.from(_get<List>('storiesRead', const []).cast<String>());
  void markStoryRead(String id) {
    final s = storiesRead;
    if (s.add(id)) _set('storiesRead', s.toList());
  }

  // ---- window (desktop) ----
  List<double>? get windowRect {
    final l = _get<List?>('win', null);
    return l?.map((e) => (e as num).toDouble()).toList();
  }

  void saveWindowRect(List<double> r) {
    _j['win'] = r;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () => _prefs.setString(_key, jsonEncode(_j)));
  }

  // ---- backup ----
  static const _backupKeys = [
    'bookmarks', 'favs', 'notes', 'memorised', 'pagesRead', 'days', 'khatams', 'salah', 'storiesRead', 'plan', 'goal',
    'tasbihTotal', 'tasbihTarget', 'quizBest', 'recentSurahs', 'theme', 'accent', 'tr1', 'tafsir', 'reciter', 'place', 'pmethod',
    'hanafi', 'clock24', 'arSize', 'trSize', 'showTr', 'motion', 'review', 'dailyVerseAt', 'translit', 'planRead', 'adhan', 'padj', 'alertp', 'hadj', 'whole',
  ];

  String exportBackup() => jsonEncode({'app': 'IQRA', 'version': 1, 'data': {for (final k in _backupKeys) if (_j.containsKey(k)) k: _j[k]}});

  /// Restores a backup made by [exportBackup]. Returns the number of settings restored.
  int importBackup(String text) {
    final m = jsonDecode(text);
    if (m is! Map || m['app'] != 'IQRA' || m['data'] is! Map) throw const FormatException('This is not an IQRA backup.');
    final data = (m['data'] as Map).cast<String, dynamic>();
    var n = 0;
    for (final k in _backupKeys) {
      if (data.containsKey(k)) {
        _j[k] = data[k];
        n++;
      }
    }
    _set('restoredAt', DateTime.now().millisecondsSinceEpoch);
    return n;
  }

  // ---- spaced review of memorised verses ----
  static const _reviewGaps = [1, 3, 7, 14, 30, 60, 120];

  Map<String, dynamic> get _review => Map<String, dynamic>.from(_get<Map>('review', const {}));

  int _epochDay([DateTime? d]) {
    final t = d ?? DateTime.now();
    return DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000;
  }

  /// Memorised verses whose next review day has come, most overdue first.
  List<String> dueReviews() {
    final r = _review;
    final today = _epochDay();
    final due = <(String, int)>[];
    for (final k in memorised) {
      final e = r[k] as Map?;
      final last = (e?['last'] as num?)?.toInt() ?? today - 1;
      final lvl = ((e?['lvl'] as num?)?.toInt() ?? 0).clamp(0, _reviewGaps.length - 1);
      final over = today - (last + _reviewGaps[lvl]);
      if (over >= 0) due.add((k, over));
    }
    due.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final d in due) d.$1];
  }

  void markReviewed(String key, bool remembered) {
    final r = _review;
    final lvl = ((r[key] as Map?)?['lvl'] as num?)?.toInt() ?? 0;
    r[key] = {'last': _epochDay(), 'lvl': remembered ? (lvl + 1).clamp(0, _reviewGaps.length - 1) : 0};
    _set('review', r);
  }

  // ---- adhan ----
  /// Play a surah as one connected recording where the reciter has one (otherwise verse by verse).
  bool get wholeSurah => _get('whole', true);
  set wholeSurah(bool v) => _set('whole', v);
  bool get adhan => _get('adhan', true);
  set adhan(bool v) => _set('adhan', v);

  // ---- daily verse reminder ----
  /// minutes after midnight, or -1 for off
  int get dailyVerseAt => _get('dailyVerseAt', -1);
  set dailyVerseAt(int v) => _set('dailyVerseAt', v);

  // ---- layout ----
  bool get sidebarCollapsed => _get('sidebarCollapsed', false);
  set sidebarCollapsed(bool v) => _set('sidebarCollapsed', v);

  // ---- reading display ----
  bool get transliteration => _get('translit', false);
  set transliteration(bool v) => _set('translit', v);

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
