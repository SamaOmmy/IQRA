import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../core/quran.dart';
import '../core/theme.dart';
import 'gradients.dart';
import 'widgets.dart';

/// Loads the authentic per-page mushaf fonts on demand (only present in builds that include them).
class MushafFonts {
  static final Map<int, Future<bool>> _loads = {};
  static final Set<int> loaded = {};

  static Future<bool> ensure(int page) {
    if (!Quran.I.hasQcf) return Future.value(false);
    return _loads.putIfAbsent(page, () async {
      try {
        final data = rootBundle.load('assets/fonts/mushaf/p$page.ttf');
        final loader = FontLoader('QCF_p$page')..addFont(data);
        await loader.load();
        loaded.add(page);
        return true;
      } catch (_) {
        return false;
      }
    });
  }
}

typedef VerseTap = void Function(int surah, int ayah, int page);

/// One printed page of the Madani mushaf: 15 lines (8 on the first two pages), laid out like the book.
class MushafPage extends StatefulWidget {
  const MushafPage({super.key, required this.page, this.onVerseTap, this.playing, this.selected, this.fontScale = 1});
  final int page;
  final VerseTap? onVerseTap;
  final VerseRef? playing, selected;
  final double fontScale;

  static final Map<String, double> _widest = {};

  /// Plain-font text size is the same on every page: the width of a line at size 100 that about 95% of all lines in the Qur'an fit
  /// (measured over all 604 pages). A longer line is shrunk to fit on its own, a shorter one is spread out, as in the printed page.
  static const double _plainReference = 1730;

  /// Gets a page ready before it is needed: loads its font and measures it, so that turning to it costs nothing.
  static Future<void> prepare(int page) async {
    final glyphs = Quran.I.pageGlyphs(page);
    final qcf = glyphs != null && await MushafFonts.ensure(page);
    if (!qcf) return; // the plain font needs no measuring
    final key = '$page|$qcf';
    if (_widest.containsKey(key)) return;
    final words = Quran.I.pageWords(page);
    final family = qcf ? 'QCF_p$page' : kArabicFont;
    final lines = <int, double>{};
    final gap = qcf ? 0.0 : 14.0;
    for (var i = 0; i < words.length; i++) {
      final tp = TextPainter(text: TextSpan(text: qcf ? glyphs[i] : words[i].text, style: TextStyle(fontFamily: family, fontSize: 100, height: 1.0)), textDirection: TextDirection.rtl)..layout();
      lines.update(words[i].line, (v) => v + tp.width + gap, ifAbsent: () => tp.width);
      tp.dispose();
    }
    var widest = 1.0;
    for (final v in lines.values) {
      if (v - gap > widest) widest = v - gap;
    }
    _widest[key] = widest;
  }

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late List<PageWord> _words;
  List<String>? _glyphs;
  bool _fontReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MushafPage old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) _load();
  }

  void _load() {
    _words = Quran.I.pageWords(widget.page);
    _glyphs = Quran.I.pageGlyphs(widget.page);
    _fontReady = MushafFonts.loaded.contains(widget.page);
    if (_glyphs != null && !_fontReady) {
      MushafFonts.ensure(widget.page).then((ok) {
        if (mounted) setState(() => _fontReady = ok);
      });
    }
  }

  bool get _qcf => _glyphs != null && _fontReady;

  // a printed page keeps its own proportions: system font scaling must not change the measured line widths
  @override
  Widget build(BuildContext context) =>
      MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling), child: Builder(builder: _pageBody));

  Widget _pageBody(BuildContext context) {
    final c = context.c;
    final rows = widget.page <= 2 ? 8 : 15;
    final first = _words.first;
    final juz = Quran.I.ayah(first.surah, first.ayah).juz;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      const padX = 14.0;
      final innerW = w - padX * 2;
      final headH = 28.0, footH = 26.0;
      final gridH = h - headH - footH - 10;
      final rowH = gridH / rows;

      // group words by printed line
      final lines = <int, List<int>>{};
      for (var i = 0; i < _words.length; i++) {
        lines.putIfAbsent(_words[i].line, () => []).add(i);
      }

      final family = _qcf ? 'QCF_p${widget.page}' : kArabicFont;
      String textOf(int i) => _qcf ? _glyphs![i] : (_words[i].isEnd ? '\u06DD${_words[i].text}' : _words[i].text);

      // one font size for the page: the widest line fills the width, never taller than its row
      double wordWidth(int i, double size) {
        final tp = TextPainter(
          text: TextSpan(text: textOf(i), style: TextStyle(fontFamily: family, fontSize: size, height: 1.0)),
          textDirection: TextDirection.rtl,
        )..layout();
        return tp.width;
      }

      double natural(List<int> idx, double size) {
        var total = 0.0;
        for (final i in idx) {
          total += wordWidth(i, size);
        }
        return total + (idx.length - 1) * (_qcf ? 0 : size * 0.14);
      }

      // the widest line at a fixed size: the same whatever the window, so it is measured once per page and kept
      final widestKey = '${widget.page}|$_qcf';
      double widest = _qcf ? (MushafPage._widest[widestKey] ?? 0) : MushafPage._plainReference;
      if (widest == 0) {
        widest = 1.0;
        for (final idx in lines.values) {
          final n = natural(idx, 100);
          if (n > widest) widest = n;
        }
        if (_qcf) MushafPage._widest[widestKey] = widest;
      }
      final base = (0.985 * 100 * innerW / widest).clamp(8.0, rowH * (_qcf ? 0.95 : 0.78));
      final size = base * widget.fontScale.clamp(0.6, 1.0);

      final sortedKeys = lines.keys.toList()..sort();
      final banners = <int, Widget>{};
      for (final ln in sortedKeys) {
        for (final i in lines[ln]!) {
          final wd = _words[i];
          if (wd.isFirst && wd.ayah == 1) {
            final bism = wd.surah != 1 && wd.surah != 9;
            banners[(ln - (bism ? 2 : 1)).clamp(1, rows)] = _Banner(Quran.I.surah(wd.surah).ar, height: rowH);
            if (bism) {
              banners[ln - 1] = Center(
                child: Text(Quran.I.bismillah, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: kArabicFont, fontSize: size * 0.82, color: c.ink)),
              );
            }
          }
        }
      }

      Widget lineWidget(int ln) {
        final idx = lines[ln]!;
        final last = _words[idx.last];
        final endsSurah = last.isEnd && last.ayah == Quran.I.surah(last.surah).ayahs.length;
        return _MushafLine(
          words: [
            for (final i in idx) _LineWord(textOf(i), _words[i].surah, _words[i].ayah, !_qcf && _words[i].isEnd),
          ],
          marks: [for (final i in idx) _mark(_words[i])],
          family: family,
          size: size,
          gap: _qcf ? 0 : size * 0.14,
          mode: widget.page <= 2 ? 1 : (endsSurah ? 2 : 0), // 0 justified, 1 centred, 2 centred when short
          ink: c.ink,
          accent: c.accent,
          playingColor: c.accent.withValues(alpha: 0.22),
          selectedColor: c.accent.withValues(alpha: 0.12),
          onTap: widget.onVerseTap == null ? null : (s, a) => widget.onVerseTap!(s, a, widget.page),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: c.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.separator),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: c.dark ? 0.4 : 0.07), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: padX, vertical: 4),
        child: Column(children: [
          SizedBox(
            height: headH,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('الجزء ${arabicDigits(juz)}', style: TextStyle(fontFamily: kArabicFont, fontSize: 15, color: c.textSecondary)),
              Text('سورة ${Quran.I.surah(first.surah).ar}', style: TextStyle(fontFamily: kArabicFont, fontSize: 15, color: c.textSecondary)),
            ]),
          ),
          Expanded(
            child: Column(children: [
              for (var r = 1; r <= rows; r++)
                SizedBox(
                  height: rowH,
                  child: lines.containsKey(r) ? lineWidget(r) : (banners[r] ?? const SizedBox.shrink()),
                ),
            ]),
          ),
          SizedBox(height: footH, child: Center(child: Text(arabicDigits(widget.page), style: TextStyle(fontFamily: kArabicFont, fontSize: 15, color: c.textSecondary)))),
        ]),
      );
    });
  }

  /// 0 plain, 1 the chosen verse, 2 the verse being recited
  int _mark(PageWord w) {
    final p = widget.playing, sel = widget.selected;
    if (p != null && p.s == w.surah && p.a == w.ayah) return 2;
    if (sel != null && sel.s == w.surah && sel.a == w.ayah) return 1;
    return 0;
  }
}

class _LineWord {
  const _LineWord(this.text, this.surah, this.ayah, this.marker);
  final String text;
  final int surah, ayah;
  final bool marker; // the verse number marker in the plain font
}

/// One printed line of the page, drawn directly: its words are laid out once, and who is highlighted only repaints. A page used to be a
/// few hundred small widgets (a tap target, an animated box and a text for every word), which took long enough to build to be seen as a
/// hitch whenever a page turned.
class _MushafLine extends LeafRenderObjectWidget {
  const _MushafLine({
    required this.words,
    required this.marks,
    required this.family,
    required this.size,
    required this.gap,
    required this.mode,
    required this.ink,
    required this.accent,
    required this.playingColor,
    required this.selectedColor,
    required this.onTap,
  });

  final List<_LineWord> words;
  final List<int> marks;
  final String family;
  final double size, gap;
  final int mode;
  final Color ink, accent, playingColor, selectedColor;
  final void Function(int surah, int ayah)? onTap;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMushafLine()..update(this, force: true);

  @override
  void updateRenderObject(BuildContext context, covariant _RenderMushafLine renderObject) => renderObject.update(this);
}

class _RenderMushafLine extends RenderBox {
  _RenderMushafLine() {
    _tap = TapGestureRecognizer()..onTapUp = _onTapUp;
  }

  late final TapGestureRecognizer _tap;
  List<_LineWord> _words = const [];
  List<int> _marks = const [];
  String _family = '';
  double _size = 0, _gap = 0;
  int _mode = 0;
  Color _ink = const Color(0xFF000000), _accent = const Color(0xFF000000), _playing = const Color(0x00000000), _selected = const Color(0x00000000);
  void Function(int, int)? _onTap;

  List<TextPainter> _tps = const [];
  List<Rect> _rects = const [];

  void update(_MushafLine w, {bool force = false}) {
    final relayout = force || w.family != _family || w.size != _size || w.gap != _gap || w.mode != _mode || w.ink != _ink || w.accent != _accent || !_sameWords(w.words);
    final repaint = relayout || !_sameMarks(w.marks) || w.playingColor != _playing || w.selectedColor != _selected;
    _words = w.words;
    _marks = w.marks;
    _family = w.family;
    _size = w.size;
    _gap = w.gap;
    _mode = w.mode;
    _ink = w.ink;
    _accent = w.accent;
    _playing = w.playingColor;
    _selected = w.selectedColor;
    _onTap = w.onTap;
    if (relayout) {
      markNeedsLayout();
    } else if (repaint) {
      markNeedsPaint();
    }
  }

  bool _sameWords(List<_LineWord> o) {
    if (o.length != _words.length) return false;
    for (var i = 0; i < o.length; i++) {
      if (o[i].text != _words[i].text || o[i].marker != _words[i].marker) return false;
    }
    return true;
  }

  bool _sameMarks(List<int> o) {
    if (o.length != _marks.length) return false;
    for (var i = 0; i < o.length; i++) {
      if (o[i] != _marks[i]) return false;
    }
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) _tap.addPointer(event);
  }

  void _onTapUp(TapUpDetails d) {
    final x = d.localPosition.dx;
    int? best;
    var bestDist = _size * 0.5; // a tap in the small gap between words still counts, for the nearer one
    for (var i = 0; i < _rects.length; i++) {
      final r = _rects[i];
      final dist = x < r.left ? r.left - x : (x > r.right ? x - r.right : 0.0);
      if (dist <= bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best != null) _onTap?.call(_words[best].surah, _words[best].ayah);
  }

  List<TextPainter> _layoutWords(double fontSize) => [
        for (final word in _words)
          TextPainter(
            text: TextSpan(text: word.text, style: TextStyle(fontFamily: _family, fontSize: fontSize, height: 1.0, color: word.marker ? _accent : _ink)),
            textDirection: TextDirection.rtl,
          )..layout(),
      ];

  @override
  void performLayout() {
    for (final t in _tps) {
      t.dispose();
    }
    final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
    var fontSize = _size, gap = _gap;
    var tps = _layoutWords(fontSize);
    double total = 0;
    for (final t in tps) {
      total += t.width;
    }
    final n = tps.length;
    var natural = total + (n > 1 ? (n - 1) * gap : 0);
    if (natural > w && w > 0) {
      // a line longer than the page is allowed to be: shrink just this line to fit (never below half size)
      final k = (w * 0.995 / natural).clamp(0.5, 1.0);
      for (final t in tps) {
        t.dispose();
      }
      fontSize *= k;
      gap *= k;
      tps = _layoutWords(fontSize);
      total = 0;
      for (final t in tps) {
        total += t.width;
      }
      natural = total + (n > 1 ? (n - 1) * gap : 0);
    }
    _tps = tps;
    var tallest = 0.0;
    for (final t in _tps) {
      if (t.height > tallest) tallest = t.height;
    }
    final h = constraints.hasBoundedHeight ? constraints.maxHeight : tallest;
    size = constraints.constrain(Size(w, h));

    final centre = _mode == 1 || (_mode == 2 && natural < size.width * 0.85);
    final between = centre ? gap : (n > 1 ? ((size.width - total) / (n - 1)).clamp(0.0, double.infinity) : 0.0);
    // pages run right to left: the first word sits at the right edge
    var x = centre ? (size.width + natural) / 2 : size.width;
    _rects = [];
    for (final t in _tps) {
      final left = x - t.width;
      _rects.add(Rect.fromLTWH(left, (size.height - t.height) / 2, t.width, t.height));
      x = left - between;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    for (var i = 0; i < _tps.length; i++) {
      final r = _rects[i].shift(offset);
      final m = i < _marks.length ? _marks[i] : 0;
      if (m != 0) canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = m == 2 ? _playing : _selected);
      _tps[i].paint(canvas, r.topLeft);
    }
  }

  @override
  void dispose() {
    _tap.dispose();
    for (final t in _tps) {
      t.dispose();
    }
    super.dispose();
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.name, {required this.height});
  final String name;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: EdgeInsets.symmetric(vertical: height * 0.08),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.accent.withValues(alpha: 0.55), width: 1.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
          child: CustomPaint(painter: GradientPainter.linear([c.accent.withValues(alpha: 0.05), c.accent.withValues(alpha: 0.2), c.accent.withValues(alpha: 0.05)], begin: Alignment.centerLeft, end: Alignment.centerRight, radius: 6)),
        ),
        Text('سورة $name', style: TextStyle(fontFamily: kArabicFont, fontSize: height * 0.52, color: c.text)),
      ]),
    );
  }
}
