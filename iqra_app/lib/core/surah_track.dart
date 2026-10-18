import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Reciters (our ids, from everyayah.com) that also have a recording of the whole surah with verse timings on quran.com.
/// Playing that single recording keeps the recitation connected the way the reciter delivered it, with no gap between verses.
const kSurahRecitations = <String, int>{
  'Alafasy_128kbps': 7,
  'Abdul_Basit_Murattal_192kbps': 2,
  'Abdul_Basit_Mujawwad_128kbps': 1,
  'Husary_128kbps': 6,
  'Husary_Muallim_128kbps': 12,
  'Minshawy_Murattal_128kbps': 9,
  'Minshawy_Mujawwad_192kbps': 8,
  'Abdurrahmaan_As-Sudais_192kbps': 3,
  'Saood_ash-Shuraym_128kbps': 10,
  'Ghamadi_40kbps': 13,
  'Abu_Bakr_Ash-Shaatree_128kbps': 4,
  'Hani_Rifai_192kbps': 5,
  'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net': 19,
  'Nasser_Alqatami_128kbps': 104,
  'Salah_Al_Budair_128kbps': 43,
};

/// One whole-surah recording: where each verse starts and ends (milliseconds), and, when known, each word.
class SurahTrack {
  SurahTrack(this.surah, this.url, this.from, this.to, this.words, {this.includesBasmala = false});
  final int surah;

  /// True when the recording itself opens with the Bismillah (a few reciters do). The others start straight at verse 1, so the
  /// Bismillah is played first, from the same reciter's own recording of it.
  final bool includesBasmala;
  final String url;
  final List<int> from, to; // by verse (index = verse - 1)
  final List<List<List<int>>> words; // by verse: [word number, start, end] in the whole recording

  int get verses => from.length;

  /// The verse (1-based) being recited at [ms]. Before the first verse (the opening phrases) counts as verse 1.
  int verseAt(int ms) {
    var lo = 0, hi = from.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (from[mid] <= ms) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  /// Zero-based index of the word being recited in verse [a] at [ms], or -1 when the recitation has no word timing.
  int wordAt(int a, int ms) {
    final w = words[a - 1];
    if (w.isEmpty) return -1;
    var idx = 0;
    for (final s in w) {
      if (ms >= s[1]) idx = s[0] - 1;
    }
    return idx;
  }

  static final Map<String, Future<SurahTrack?>> _loads = {};
  static final http.Client _http = http.Client();

  /// Loads the timings for a surah (from the device if seen before). Null when this reciter has no whole-surah recording.
  static Future<SurahTrack?> load(String reciter, int surah) {
    final rid = kSurahRecitations[reciter];
    if (rid == null) return Future.value(null);
    final key = '$rid/$surah';
    final f = _loads[key] ??= _fetch(rid, surah);
    return f.then((t) {
      if (t == null) _loads.remove(key); // a failed attempt may succeed later
      return t;
    });
  }

  static Future<SurahTrack?> _fetch(int rid, int surah) async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}${Platform.pathSeparator}timings');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}${Platform.pathSeparator}$rid-$surah.json');
      String body;
      if (file.existsSync() && file.lengthSync() > 50) {
        body = file.readAsStringSync();
      } else {
        final res = await _http.get(Uri.parse('https://api.quran.com/api/v4/chapter_recitations/$rid/$surah?segments=true')).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) return null;
        body = res.body;
        file.writeAsStringSync(body);
      }
      final af = (jsonDecode(body) as Map<String, dynamic>)['audio_file'] as Map<String, dynamic>;
      final ts = (af['timestamps'] as List?) ?? const [];
      if (ts.isEmpty) return null;
      final from = <int>[], to = <int>[];
      final words = <List<List<int>>>[];
      var expected = 1;
      for (final t in ts) {
        final m = t as Map<String, dynamic>;
        final key = (m['verse_key'] as String).split(':');
        if (int.parse(key[0]) != surah || int.parse(key[1]) != expected) return null; // not a clean, ordered list of verses
        expected++;
        from.add((m['timestamp_from'] as num).round());
        to.add((m['timestamp_to'] as num).round());
        words.add([
          for (final s in (m['segments'] as List? ?? const []))
            if (s is List && s.length >= 3) [(s[0] as num).round(), (s[1] as num).round(), (s[2] as num).round()],
        ]);
      }
      // the timings of a few recordings are unusable (verse 1 starting minutes in, or verses out of order): play those verse by verse
      if (from.first > 60000) return null;
      for (var i = 0; i < from.length; i++) {
        if (to[i] <= from[i] || (i > 0 && from[i] < from[i - 1])) return null;
      }
      // the reciters whose recording opens with the isti'adha and Bismillah (verse 1 starts a few seconds in, or is longer than the verse itself)
      final withBasmala = const {13, 19, 104, 43}.contains(rid) || from.first >= 1500;
      return SurahTrack(surah, af['audio_url'] as String, from, to, words, includesBasmala: withBasmala);
    } catch (_) {
      return null;
    }
  }
}
