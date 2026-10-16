import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';
import '../core/quran.dart';
import '../core/theme.dart';
import 'widgets.dart';

final _marks = RegExp('[ً-ٰٟۖ-ۭـ]');

/// Estimated share of the verse's duration that each word takes: longer words take longer.
List<double> wordWeights(List<WbwWord> words) => [
      for (final w in words) math.max(1, w.ar.replaceAll(_marks, '').length).toDouble() + 0.8,
    ];

/// Which word is being recited, given how far through the verse's audio we are (an estimate: the recitations carry no word timing).
int currentWordIndex(List<double> weights, double progress) {
  if (weights.isEmpty) return 0;
  final total = weights.fold<double>(0, (a, b) => a + b);
  // the recording has a little silence before and after the words
  final p = ((progress - 0.035) / 0.93).clamp(0.0, 0.9999);
  var acc = 0.0;
  for (var i = 0; i < weights.length; i++) {
    acc += weights[i] / total;
    if (p < acc) return i;
  }
  return weights.length - 1;
}

/// A verse in Arabic that lights up word by word while it is being recited, like synced lyrics.
class LiveVerse extends StatefulWidget {
  const LiveVerse({super.key, required this.ayah, required this.fontSize, this.color, this.activeColor, this.height = 1.9, this.align = WrapAlignment.center, this.dimmed = true});
  final Ayah ayah;
  final double fontSize, height;
  final Color? color, activeColor;
  final WrapAlignment align;
  final bool dimmed;

  @override
  State<LiveVerse> createState() => _LiveVerseState();
}

class _LiveVerseState extends State<LiveVerse> {
  List<WbwWord>? _words;
  List<double> _weights = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LiveVerse old) {
    super.didUpdateWidget(old);
    if (old.ayah.global != widget.ayah.global) _load();
  }

  Future<void> _load() async {
    final a = widget.ayah;
    final w = await Quran.I.wordsOf(a.surah, a.n);
    if (!mounted || a.global != widget.ayah.global) return;
    setState(() {
      _words = w;
      _weights = wordWeights(w);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = widget.ayah;
    final base = widget.color ?? c.text;
    final active = widget.activeColor ?? c.accent;
    final style = TextStyle(fontFamily: kArabicFont, fontSize: widget.fontSize, height: widget.height, color: base);
    // rebuilds only when the highlighted word changes, not on every audio tick
    final idx = context.select<AudioController, int>((au) {
      final cur = au.current;
      final isCurrent = cur != null && cur.s == a.surah && cur.a == a.n && (au.playing || au.progress > 0);
      if (!isCurrent || _words == null || _words!.isEmpty) return -1;
      final exact = au.exactWord(a.surah, a.n); // the reciter's own word timing, when the recording has it
      return exact >= 0 ? math.min(exact, _words!.length - 1) : currentWordIndex(_weights, au.progress);
    });
    if (idx < 0) {
      return Directionality(textDirection: TextDirection.rtl, child: Text(a.ar, textAlign: widget.align == WrapAlignment.center ? TextAlign.center : TextAlign.start, style: style));
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: widget.align,
        spacing: widget.fontSize * 0.22,
        children: [
          for (var i = 0; i < _words!.length; i++)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: style.copyWith(
                color: i == idx ? active : (i < idx ? base : base.withValues(alpha: widget.dimmed ? 0.5 : 1)),
                fontWeight: i == idx ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(_words![i].ar),
            ),
        ],
      ),
    );
  }
}
