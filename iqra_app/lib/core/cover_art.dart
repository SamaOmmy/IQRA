import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../ui/widgets.dart' show ArtPatternPainter, artColors, kArabicFont;
import 'quran.dart';

/// The "album cover" of a surah as a picture file (same look as the covers in the app), for the notification and the lock screen.
Future<Uri?> coverArt(int surah) async {
  try {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}covers');
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}cover_$surah.png');
    if (await file.exists() && await file.length() > 1000) return file.uri;
    const size = 640;
    final s = size.toDouble();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final (a, b) = artColors(surah * 5 + 2);
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(s, s), [a, b]));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..shader = ui.Gradient.radial(Offset(s * 0.15, s * 0.05), s * 1.2, [const Color(0x38FFFFFF), const Color(0x00FFFFFF)]),
    );
    ArtPatternPainter(surah, const Color(0x33FFFFFF)).paint(canvas, Size(s, s));
    final sr = Quran.I.surah(surah);

    void text(String t, double fontSize, Offset at, {String? family, FontWeight? weight, double alpha = 1, TextAlign align = TextAlign.left, double maxWidth = 560, TextDirection dir = TextDirection.ltr, double spacing = 0}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(fontFamily: family, fontSize: fontSize, fontWeight: weight, color: Color.fromRGBO(255, 255, 255, alpha), height: 1.15, letterSpacing: spacing)),
        textDirection: dir,
        textAlign: align,
      )..layout(maxWidth: maxWidth);
      final dx = align == TextAlign.right ? at.dx - tp.width : at.dx;
      tp.paint(canvas, Offset(dx, at.dy));
      tp.dispose();
    }

    // a large faint copy of the name behind, the number, the calligraphy and the name in Latin letters
    text(sr.ar, s * 0.62, Offset(s + s * 0.04, s * 0.26), family: kArabicFont, alpha: 0.10, align: TextAlign.right, maxWidth: s * 1.4, dir: TextDirection.rtl);
    text('$surah', s * 0.12, Offset(s * 0.07, s * 0.06), weight: FontWeight.w800, alpha: 0.9);
    text(sr.ar, math.min(s * 0.3, s * 0.86 * 0.3), Offset(s - s * 0.07, s * 0.55), family: kArabicFont, align: TextAlign.right, maxWidth: s * 0.86, dir: TextDirection.rtl);
    text(sr.en.toUpperCase(), s * 0.062, Offset(s * 0.07, s - s * 0.13), weight: FontWeight.w800, alpha: 0.92, spacing: 3);
    final pic = rec.endRecording();
    final img = await pic.toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    pic.dispose();
    img.dispose();
    if (bytes == null) return null;
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.uri;
  } catch (_) {
    return null;
  }
}
