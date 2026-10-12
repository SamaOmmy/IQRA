import 'dart:convert';

import 'package:flutter/services.dart';

typedef J = Map<String, dynamic>;

/// The authored content (stories, hadith, guides, adhkar...) bundled with the app as JSON.
class Content {
  Content._();
  static final Content I = Content._();

  late final J _c;
  late final List<dynamic> hisn, azkar, nawawiArabic, hadith;

  Future<void> load() async {
    Future<dynamic> j(String a) async => jsonDecode(await rootBundle.loadString(a));
    _c = (await j('assets/data/content.json')) as J;
    hisn = await j('assets/data/discover/hisn.json');
    azkar = await j('assets/data/discover/azkar.json');
    nawawiArabic = await j('assets/data/discover/nawawi.json');
    hadith = await j('assets/data/discover/hadith.json');
  }

  J get _d => _c['discover'] as J;

  List<J> _list(String k) => [for (final e in _d[k] as List) (e as J)];

  List<J> get stories => _list('stories');
  List<J> get shelves => _list('shelves');
  List<J> get collections => _list('collections');
  List<J> get moments => _list('moments');
  List<J> get occasions => _list('occasions');
  List<J> get fasting => _list('fasting');
  List<J> get nawawiNotes => _list('nawawi');
  List<List<dynamic>> get dailyVerses => [for (final e in _d['dailyVerses'] as List) (e as List)];
  List<int> get dailyDuaChapters => (_d['dailyDuaChapters'] as List).cast<int>();
  List<List<dynamic>> get names => [for (final e in _d['names'] as List) (e as List)];
  J? deep(String id) => (_d['deep'] as J)[id] as J?;
  List<J> get guides => [for (final e in _c['guides'] as List) (e as J)];
  String surahIntro(int n) => ((_c['surahIntros'] as J)['$n'] ?? '') as String;

  J? story(String id) {
    for (final s in stories) {
      if (s['id'] == id) return s;
    }
    return null;
  }

  List<J> storiesOf(String shelf) => [for (final s in stories) if (s['shelf'] == shelf) s];
  J? collection(String id) {
    for (final c in collections) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  J? guide(String id) {
    for (final g in guides) {
      if (g['id'] == id) return g;
    }
    return null;
  }

  /// Rough reading time of a story, counting its in-depth text too.
  int readingMinutes(J story) {
    var words = 0;
    int count(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    for (final p in (story['p'] as List? ?? const [])) {
      words += count(p as String);
    }
    final d = deep(story['id'] as String);
    if (d != null) {
      for (final s in (d['s'] as List? ?? const [])) {
        for (final t in ((s as J)['t'] as List? ?? const [])) {
          words += count(t as String);
        }
      }
    }
    return (words / 200).ceil().clamp(1, 60);
  }
}
