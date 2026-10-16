import 'package:flutter/foundation.dart';

import 'audio_cache.dart';
import 'quran.dart';

/// Downloads recitations and tafsir ahead of time so they work without a connection.
class DownloadManager extends ChangeNotifier {
  /// surah -> fraction done, only while it is being downloaded
  final Map<int, double> audioProgress = {};
  double? tafsirProgress;
  String? tafsirTitle;
  bool _cancel = false;
  bool get busy => audioProgress.isNotEmpty || tafsirProgress != null;
  String? error;

  void cancel() {
    _cancel = true;
  }

  Future<void> downloadSurahs(List<int> surahs, String reciter) async {
    _cancel = false;
    error = null;
    for (final s in surahs) {
      if (_cancel) break;
      final count = Quran.I.surah(s).ayahs.length;
      var done = 0;
      audioProgress[s] = 0;
      notifyListeners();
      try {
        for (var a = 1; a <= count && !_cancel; a += 4) {
          final batch = [for (var k = a; k < a + 4 && k <= count; k++) k];
          await Future.wait([
            for (final k in batch)
              AudioCache.ensure(reciter, s, k).then((_) {
                done++;
                audioProgress[s] = done / count;
                notifyListeners();
              }),
          ]);
        }
      } catch (e) {
        error = e.toString().replaceFirst('Exception: ', '');
        audioProgress.remove(s);
        notifyListeners();
        break;
      }
      audioProgress.remove(s);
      notifyListeners();
    }
    audioProgress.clear();
    notifyListeners();
  }

  Future<void> downloadTafsir(String id, String title) async {
    _cancel = false;
    error = null;
    tafsirTitle = title;
    tafsirProgress = 0;
    notifyListeners();
    try {
      for (var s = 1; s <= 114 && !_cancel; s++) {
        await Quran.I.tafsir(id, s);
        tafsirProgress = s / 114;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    tafsirProgress = null;
    tafsirTitle = null;
    notifyListeners();
  }
}
