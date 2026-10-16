import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'widgets.dart';

/// Spaced review of memorised verses: recite from the translation, check, and say whether you remembered.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<String> _queue;
  int _done = 0, _correct = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _queue = context.read<AppStore>().dueReviews();
  }

  void _answer(bool ok) {
    final store = context.read<AppStore>();
    store.markReviewed(_queue[_done], ok);
    HapticFeedback.selectionClick();
    setState(() {
      _done++;
      if (ok) _correct++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final finished = _done >= _queue.length;
    final tr = context.watch<TranslationModel>();
    Widget body;
    if (_queue.isEmpty) {
      final all = context.read<AppStore>().memorised.toList();
      body = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Empty(Icons.verified_rounded, 'Nothing due', 'Everything you have memorised is up to date. Verses come back here for review after a day, then a few days, then weeks.'),
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: OutlinedButton(
              onPressed: () => setState(() {
                _queue = all..shuffle();
                _done = 0;
                _correct = 0;
              }),
              child: Text('Review all ${all.length} anyway'),
            ),
          ),
      ]);
    } else if (finished) {
      body = Padding(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.celebration_rounded, size: 60, color: c.accent),
          const SizedBox(height: 14),
          const Text('Review complete', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('$_correct of ${_queue.length} remembered', style: TextStyle(color: c.textSecondary, fontSize: 16)),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent), child: const Text('Done')),
        ]),
      );
    } else {
      final ref = VerseRef.parse(_queue[_done]);
      final a = Quran.I.ayah(ref.s, ref.a);
      final audio = context.read<AudioController>();
      body = Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _done / _queue.length, minHeight: 6, color: c.accent, backgroundColor: c.surface)),
          const SizedBox(height: 6),
          Text('${_done + 1} of ${_queue.length}', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('${Quran.I.surah(ref.s).en} · ${ref.s}:${ref.a}', textAlign: TextAlign.center, style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 16),
                  Text(tr.text(a), textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, height: 1.5)),
                  const SizedBox(height: 22),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _revealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Center(child: Text('Recite it, then reveal to check.', style: TextStyle(color: c.textSecondary))),
                    secondChild: Directionality(textDirection: TextDirection.rtl, child: Text(a.ar, textAlign: TextAlign.center, style: TextStyle(fontFamily: kArabicFont, fontSize: 32, height: 1.9, color: c.text))),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_revealed)
            Row(children: [
              IconButton.filledTonal(onPressed: () => audio.playVerse(ref.s, ref.a, scope: PlayScope.verse), icon: const Icon(Icons.volume_up_rounded)),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _revealed = true),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Reveal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ])
          else
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _answer(false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Forgot'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _answer(true),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Remembered', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: Icon(Icons.close_rounded, color: c.text)),
              const Expanded(child: Text('Review', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: body))),
        ]),
      ),
    );
  }
}
