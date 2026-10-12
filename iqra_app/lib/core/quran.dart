import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class Ayah {
  Ayah(this.surah, this.n, this.global, this.ar, this.t, this.juz, this.page, this.sajda);
  final int surah, n, global, juz, page;
  final String ar, t;
  final bool sajda;
}

class Surah {
  Surah(this.n, this.ar, this.en, this.meaning, this.type, this.ayahs);
  final int n;
  final String ar, en, meaning, type;
  final List<Ayah> ayahs;
  bool get meccan => type.toLowerCase().startsWith('mecc');
  int get firstPage => ayahs.first.page;
}

/// One word of a mushaf page: [surah, ayah, text, line, flags] (flags: 1 = verse-end marker, 2 = first word of verse).
class PageWord {
  PageWord(this.surah, this.ayah, this.text, this.line, this.flags);
  final int surah, ayah, line, flags;
  final String text;
  bool get isEnd => flags & 1 != 0;
  bool get isFirst => flags & 2 != 0;
}

class WbwWord {
  WbwWord(this.ar, this.meaning, this.translit);
  final String ar, meaning, translit;
}

class PackInfo {
  PackInfo(this.id, this.name, this.lang);
  final String id, name, lang;
  bool get rtl => const {'ar', 'fa', 'ur', 'ps', 'sd', 'ug', 'dv', 'ku'}.contains(lang);
}

class VerseRef {
  const VerseRef(this.s, this.a);
  final int s, a;
  @override
  bool operator ==(Object o) => o is VerseRef && o.s == s && o.a == a;
  @override
  int get hashCode => s * 1000 + a;
  String get key => '$s:$a';
  static VerseRef parse(String k) {
    final p = k.split(':');
    return VerseRef(int.parse(p[0]), int.parse(p[1]));
  }
}

const kReciters = <(String, String)>[
  ('Alafasy_128kbps', 'Mishary Alafasy'),
  ('Abdul_Basit_Murattal_192kbps', 'Abdul Basit (Murattal)'),
  ('Abdul_Basit_Mujawwad_128kbps', 'Abdul Basit (Mujawwad)'),
  ('Husary_128kbps', 'Mahmoud Khalil Al-Husary'),
  ('Husary_Muallim_128kbps', 'Al-Husary (teaching, with repeats)'),
  ('Minshawy_Murattal_128kbps', 'Mohamed Al-Minshawi (Murattal)'),
  ('Minshawy_Mujawwad_192kbps', 'Mohamed Al-Minshawi (Mujawwad)'),
  ('Abdurrahmaan_As-Sudais_192kbps', 'Abdurrahman As-Sudais'),
  ('Saood_ash-Shuraym_128kbps', 'Saud Ash-Shuraim'),
  ('Maher_AlMuaiqly_64kbps', 'Maher Al-Muaiqly'),
  ('Abdullah_Basfar_192kbps', 'Abdullah Basfar'),
  ('Hudhaify_128kbps', 'Ali Al-Hudhaify'),
  ('Muhammad_Ayyoub_128kbps', 'Muhammad Ayyub'),
  ('Muhammad_Jibreel_128kbps', 'Muhammad Jibreel'),
  ('Ghamadi_40kbps', 'Saad Al-Ghamdi'),
  ('Abu_Bakr_Ash-Shaatree_128kbps', 'Abu Bakr Ash-Shatri'),
  ('Hani_Rifai_192kbps', 'Hani Ar-Rifai'),
  ('Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', 'Ahmed Al-Ajmi'),
  ('Yasser_Ad-Dussary_128kbps', 'Yasser Ad-Dosari'),
  ('Nasser_Alqatami_128kbps', 'Nasser Al-Qatami'),
  ('Salah_Al_Budair_128kbps', 'Salah Al-Budair'),
];

String reciterName(String id) => kReciters.firstWhere((r) => r.$1 == id, orElse: () => (id, id)).$2;

const _repoRaw = 'https://raw.githubusercontent.com/SamaOmmy/IQRA/main/data';

/// The Qur'an text, the printed-page layout and the word-by-word data, loaded once from the app bundle.
class Quran {
  Quran._();
  static final Quran I = Quran._();

  late final List<Surah> surahs;
  late final String bismillah;
  late final List<PackInfo> translations, tafsirs;
  late final List<List<dynamic>> _pages;
  List<dynamic>? _words;
  List<dynamic>? _qcf;
  bool get hasQcf => _qcf != null;
  final Map<String, List<String>> _packCache = {};
  late final Map<int, int> _juzStart; // juz -> global ayah number

  static Future<dynamic> _json(String asset) async => jsonDecode(await rootBundle.loadString(asset));

  Future<void> load() async {
    final q = await _json('assets/data/quran.json') as Map<String, dynamic>;
    bismillah = q['bismillah'] as String;
    translations = [for (final t in q['translations']) PackInfo(t['id'], t['name'], t['lang'])];
    tafsirs = [for (final t in q['tafsirs']) PackInfo(t['id'], t['name'], t['lang'])];
    var g = 0;
    surahs = [
      for (final s in q['surahs'])
        Surah(s['n'], s['ar'], s['en'], s['meaning'], s['type'], [
          for (final a in s['ayahs'])
            Ayah(s['n'], a['n'], ++g, a['a'], a['t'] ?? '', a['juz'], a['page'], a['sajda'] == true),
        ]),
    ];
    _juzStart = {};
    for (final s in surahs) {
      for (final a in s.ayahs) {
        _juzStart.putIfAbsent(a.juz, () => a.global);
      }
    }
    _pages = (await _json('assets/data/pages.json') as List).cast<List<dynamic>>();
    try {
      _qcf = await _json('assets/qcf/qcf.json') as List;
    } catch (_) {
      _qcf = null; // public build: the licensed glyph data is not shipped
    }
  }

  Surah surah(int n) => surahs[n - 1];
  Ayah ayah(int s, int a) => surahs[s - 1].ayahs[a - 1];
  Ayah byGlobal(int g) {
    for (final s in surahs) {
      if (g <= s.ayahs.last.global) return s.ayahs[g - s.ayahs.first.global];
    }
    return surahs.last.ayahs.last;
  }

  List<Ayah> get allAyahs => [for (final s in surahs) ...s.ayahs];

  VerseRef? next(int s, int a) {
    if (a < surah(s).ayahs.length) return VerseRef(s, a + 1);
    return s < 114 ? VerseRef(s + 1, 1) : null;
  }

  VerseRef? previous(int s, int a) {
    if (a > 1) return VerseRef(s, a - 1);
    return s > 1 ? VerseRef(s - 1, surah(s - 1).ayahs.length) : null;
  }

  int juzFirstSurah(int juz) => byGlobal(_juzStart[juz]!).surah;
  Ayah juzStart(int juz) => byGlobal(_juzStart[juz]!);

  List<PageWord> pageWords(int p) => [
        for (final w in _pages[p - 1]) PageWord(w[0], w[1], w[2], w[3], w[4]),
      ];

  /// The authentic glyph string of every word on the page (same order as [pageWords]), or null.
  List<String>? pageGlyphs(int p) => _qcf == null ? null : (_qcf![p - 1] as List).cast<String>();

  Future<List<WbwWord>> wordsOf(int s, int a) async {
    _words ??= await _json('assets/data/words.json') as List;
    final list = (_words![s - 1] as List)[a - 1] as List;
    return [for (final w in list) WbwWord(w[0], w[1], w[2])];
  }

  /// A translation as a list of 6,236 strings (verse order). The default one is inside quran.json; the rest are fetched once
  /// from the repository and kept in the app's cache folder for offline use.
  Future<List<String>> translation(String id) async {
    if (id == 'en.sahih') {
      return _packCache.putIfAbsent(id, () => allAyahs.map((a) => a.t).toList());
    }
    final hit = _packCache[id];
    if (hit != null) return hit;
    final file = await _cacheFile('translations', '$id.json');
    String raw;
    if (await file.exists()) {
      raw = await file.readAsString();
    } else {
      final res = await http.get(Uri.parse('$_repoRaw/translations/$id.json'));
      if (res.statusCode != 200) throw Exception('Could not download this translation (${res.statusCode}).');
      raw = utf8.decode(res.bodyBytes);
      await file.writeAsString(raw);
    }
    final list = (jsonDecode(raw) as List).cast<String>();
    _packCache[id] = list;
    return list;
  }

  /// Tafsir of one surah: a list with one string per verse.
  Future<List<String>> tafsir(String id, int surahNo) async {
    final key = '$id/$surahNo';
    final hit = _packCache[key];
    if (hit != null) return hit;
    final file = await _cacheFile('tafsir/$id', '$surahNo.json');
    String raw;
    if (await file.exists()) {
      raw = await file.readAsString();
    } else {
      final res = await http.get(Uri.parse('$_repoRaw/tafsir/$id/$surahNo.json'));
      if (res.statusCode != 200) throw Exception('Could not download this tafsir (${res.statusCode}).');
      raw = utf8.decode(res.bodyBytes);
      await file.writeAsString(raw);
    }
    final list = (jsonDecode(raw) as List).map((e) => e == null ? '' : e.toString()).toList();
    _packCache[key] = list;
    return list;
  }

  Future<File> _cacheFile(String dir, String name) async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/packs/$dir');
    if (!await d.exists()) await d.create(recursive: true);
    return File('${d.path}/$name');
  }
}

String arabicDigits(Object n) => n.toString().replaceAllMapped(RegExp(r'\d'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);
