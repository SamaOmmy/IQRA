import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

/// A verse in Arabic that fills with colour word by word as it is recited, like karaoke or synced lyrics: each word is
/// painted from its right edge to its left as the reciter says it.
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

class _LiveVerseState extends State<LiveVerse> with SingleTickerProviderStateMixin {
  List<WbwWord>? _words;
  List<double> _weights = const [];
  late final Ticker _ticker = createTicker((_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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
    // 0 not this verse, 1 this verse paused part-way, 2 this verse being recited. The frame clock runs only in the last case.
    final state = context.select<AudioController, int>((au) {
      final cur = au.current;
      if (cur == null || cur.s != a.surah || cur.a != a.n) return 0;
      if (au.playing) return 2;
      return au.progress > 0 ? 1 : 0;
    });
    final live = state > 0;
    if (state == 2 && !_ticker.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_ticker.isActive) _ticker.start();
      });
    } else if (state != 2 && _ticker.isActive) {
      _ticker.stop();
    }
    if (!live || _words == null || _words!.isEmpty) {
      return Directionality(textDirection: TextDirection.rtl, child: Text(a.ar, textAlign: widget.align == WrapAlignment.center ? TextAlign.center : TextAlign.start, style: style));
    }
    final cursor = context.read<AudioController>().wordCursor(a.surah, a.n, _weights) ?? 0;
    final dim = base.withValues(alpha: widget.dimmed ? 0.45 : 1);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: widget.align,
        spacing: widget.fontSize * 0.22,
        children: [
          for (var i = 0; i < _words!.length; i++) _fill(_words![i].ar, (cursor - i).clamp(0.0, 1.0), style, dim, active),
        ],
      ),
    );
  }

  Widget _fill(String text, double f, TextStyle style, Color dim, Color done) {
    if (f <= 0) return Text(text, style: style.copyWith(color: dim));
    if (f >= 1) return Text(text, style: style.copyWith(color: done));
    // right to left, with a soft edge
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [done, done, dim, dim], stops: [0, math.max(0, f - 0.12), math.min(1, f + 0.12), 1]).createShader(r),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
