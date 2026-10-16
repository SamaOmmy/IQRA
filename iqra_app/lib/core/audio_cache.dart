import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'quran.dart';

/// Recitation files kept on the device: one mp3 per verse, downloaded from everyayah.com the first time and then reused offline.
class AudioCache {
  static final http.Client _http = http.Client();
  static final Map<String, Future<String>> _inflight = {};
  static Directory? _root;

  static String fileName(int s, int a) => '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  static Future<Directory> root() async {
    if (_root != null) return _root!;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}${Platform.pathSeparator}audio');
    if (!await d.exists()) await d.create(recursive: true);
    return _root = d;
  }

  static Future<File> file(String reciter, int s, int a) async {
    final r = await root();
    final dir = Directory('${r.path}${Platform.pathSeparator}$reciter');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}${fileName(s, a)}');
  }

  static Future<bool> has(String reciter, int s, int a) async {
    final f = await file(reciter, s, a);
    return f.existsSync() && f.lengthSync() > 1024;
  }

  /// Local path of the verse's audio, downloading it first when needed. Concurrent calls share one download.
  static Future<String> ensure(String reciter, int s, int a) {
    final key = '$reciter/$s:$a';
    return _inflight.putIfAbsent(key, () async {
      try {
        final f = await file(reciter, s, a);
        if (f.existsSync() && f.lengthSync() > 1024) return f.path;
        final res = await _http.get(Uri.parse('https://everyayah.com/data/$reciter/${fileName(s, a)}')).timeout(const Duration(seconds: 40));
        if (res.statusCode != 200) throw Exception('Audio unavailable (${res.statusCode}). Check your connection.');
        final tmp = File('${f.path}.part');
        await tmp.writeAsBytes(res.bodyBytes, flush: true);
        await tmp.rename(f.path);
        return f.path;
      } finally {
        _inflight.remove(key);
      }
    });
  }

  /// How many of a surah's verses are already on the device.
  static int cachedCount(String reciter, int surah) {
    final r = _root;
    if (r == null) return 0;
    final dir = Directory('${r.path}${Platform.pathSeparator}$reciter');
    if (!dir.existsSync()) return 0;
    var n = 0;
    final count = Quran.I.surah(surah).ayahs.length;
    for (var a = 1; a <= count; a++) {
      final f = File('${dir.path}${Platform.pathSeparator}${fileName(surah, a)}');
      if (f.existsSync()) n++;
    }
    return n;
  }

  static Future<int> totalBytes() async {
    final r = await root();
    var total = 0;
    await for (final e in r.list(recursive: true, followLinks: false)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  static Future<void> clear() async {
    final r = await root();
    if (await r.exists()) await r.delete(recursive: true);
    _root = null;
    await root();
  }
}
