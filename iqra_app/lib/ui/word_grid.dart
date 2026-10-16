import 'package:flutter/material.dart';

import '../core/quran.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// A verse word by word: the Arabic with its transliteration and meaning beneath each word.
class WordGrid extends StatelessWidget {
  const WordGrid({super.key, required this.ayah, required this.fontSize});
  final Ayah ayah;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FutureBuilder<List<WbwWord>>(
      future: Quran.I.wordsOf(ayah.surah, ayah.n),
      builder: (context, snap) {
        if (!snap.hasData) return SizedBox(height: fontSize * 2.4);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (final w in snap.data!)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, maxWidth: 120),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(w.ar, textAlign: TextAlign.center, style: TextStyle(fontFamily: kArabicFont, fontSize: fontSize * 0.9, height: 1.6, color: c.text)),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(w.translit, textAlign: TextAlign.center, style: TextStyle(color: c.accent, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        Text(w.meaning, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 11.5, height: 1.25)),
                      ]),
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The verse's transliteration as one line of text.
class Transliteration extends StatelessWidget {
  const Transliteration({super.key, required this.ayah, this.size = 14.5});
  final Ayah ayah;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FutureBuilder<List<WbwWord>>(
      future: Quran.I.wordsOf(ayah.surah, ayah.n),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(snap.data!.map((w) => w.translit).join(' '), style: TextStyle(color: c.accent, fontStyle: FontStyle.italic, fontSize: size, height: 1.5)),
        );
      },
    );
  }
}
