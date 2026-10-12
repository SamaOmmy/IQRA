import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/quran.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// Loads the authentic per-page mushaf fonts on demand (only present in builds that include them).
class MushafFonts {
  static final Map<int, Future<bool>> _loads = {};

  static Future<bool> ensure(int page) {
    if (!Quran.I.hasQcf) return Future.value(false);
    return _loads.putIfAbsent(page, () async {
      try {
        final data = rootBundle.load('assets/fonts/mushaf/p$page.ttf');
        final loader = FontLoader('QCF_p$page')..addFont(data);
        await loader.load();
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

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late List<PageWord> _words;
  List<String>? _glyphs;
  bool _fontReady = false;
  final Map<String, double> _sizeMemo = {};

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
    _fontReady = false;
    _sizeMemo.clear();
    if (_glyphs != null) {
      MushafFonts.ensure(widget.page).then((ok) {
        if (mounted) setState(() {
          _fontReady = ok;
          _sizeMemo.clear();
        });
      });
    }
  }

  bool get _qcf => _glyphs != null && _fontReady;

  @override
  Widget build(BuildContext context) {
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
      String textOf(int i) => _qcf ? _glyphs![i] : _words[i].text;

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

      final memoKey = '${_qcf}_${innerW.round()}_${rowH.round()}';
      var base = _sizeMemo[memoKey];
      if (base == null) {
        var widest = 1.0;
        for (final idx in lines.values) {
          final n = natural(idx, 100);
          if (n > widest) widest = n;
        }
        base = (0.985 * 100 * innerW / widest).clamp(8.0, rowH * (_qcf ? 0.95 : 0.78));
        _sizeMemo[memoKey] = base;
      }
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
        final centered = widget.page <= 2 || (endsSurah && natural(idx, size) < innerW * 0.85);
        final children = <Widget>[
          for (final i in idx) _word(context, i, family, size),
        ];
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: centered
                ? [for (var k = 0; k < children.length; k++) ...[if (k > 0) SizedBox(width: _qcf ? 0 : size * 0.14), children[k]]]
                : children,
          ),
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

  Widget _word(BuildContext context, int i, String family, double size) {
    final c = context.c;
    final w = _words[i];
    final isPlaying = widget.playing != null && widget.playing!.s == w.surah && widget.playing!.a == w.ayah;
    final isSel = widget.selected != null && widget.selected!.s == w.surah && widget.selected!.a == w.ayah;
    final hl = isPlaying ? c.accent.withValues(alpha: 0.22) : (isSel ? c.accent.withValues(alpha: 0.12) : Colors.transparent);
    var text = _qcf ? _glyphs![i] : w.text;
    final style = TextStyle(
      fontFamily: family,
      fontSize: size,
      height: 1.0,
      color: (!_qcf && w.isEnd) ? c.accent : c.ink,
    );
    if (!_qcf && w.isEnd) text = w.text; // the verse number marker
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onVerseTap == null ? null : () => widget.onVerseTap!(w.surah, w.ayah, widget.page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(color: hl, borderRadius: BorderRadius.circular(5)),
        child: Text(text, textDirection: TextDirection.rtl, style: style),
      ),
    );
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
        gradient: LinearGradient(colors: [c.accent.withValues(alpha: 0.05), c.accent.withValues(alpha: 0.2), c.accent.withValues(alpha: 0.05)]),
        border: Border.symmetric(horizontal: BorderSide(color: c.accent.withValues(alpha: 0.55), width: 1.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text('سورة $name', style: TextStyle(fontFamily: kArabicFont, fontSize: height * 0.52, color: c.text)),
    );
  }
}
