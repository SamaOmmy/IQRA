import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/audio.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'share_card.dart';
import 'widgets.dart';

String verseShareText(Ayah a, String translation) {
  final s = Quran.I.surah(a.surah);
  return '${a.ar}\n\n${translation.isEmpty ? a.t : translation}\n\n— ${s.en} ${a.surah}:${a.n}';
}

/// The verse action sheet and the study panel (translations, words, tafsir, notes).
Future<void> showVerseSheet(BuildContext context, int s, int a, {int? page}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _SheetFrame(child: _VerseActions(s: s, a: a)),
  );
}

Future<void> showStudy(BuildContext context, int s, int a, {int tab = 0}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _SheetFrame(tall: true, child: StudyPanel(s: s, a: a, tab: tab)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child, this.tall = false});
  final Widget child;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final h = MediaQuery.of(context).size.height;
    final wide = MediaQuery.of(context).size.width > 700;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 640 : double.infinity, maxHeight: tall ? h * 0.9 : h * 0.8),
        child: Glass(
          blur: 40,
          opacity: 0.92,
          color: c.bg,
          radius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 38, height: 5, decoration: BoxDecoration(color: c.separator, borderRadius: BorderRadius.circular(3))),
            Flexible(child: child),
          ])),
        ),
      ),
    );
  }
}

class _VerseActions extends StatelessWidget {
  const _VerseActions({required this.s, required this.a});
  final int s, a;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final audio = context.read<AudioController>();
    final tr = context.read<TranslationModel>();
    final ay = Quran.I.ayah(s, a);
    final sr = Quran.I.surah(s);
    final key = '$s:$a';
    Widget action(IconData icon, String label, VoidCallback onTap, {bool on = false}) => Pressable(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          radius: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Icon(icon, size: 22, color: on ? c.accent : c.text),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500, color: on ? c.accent : c.text)),
            ]),
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
          child: Row(children: [
            SurahArt(surah: s, size: 54, showName: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${sr.en} · $s:$a', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text('Juz ${ay.juz} · Page ${ay.page}${ay.sajda ? ' · Sajdah verse' : ''}', style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
              ]),
            ),
          ]),
        ),
        const Divider1(),
        action(Icons.play_arrow_rounded, 'Play from here', () => audio.playVerse(s, a, scope: PlayScope.continuous)),
        action(Icons.repeat_one_rounded, 'Play this verse only', () => audio.playVerse(s, a, scope: PlayScope.verse)),
        action(Icons.loop_rounded, 'Loop a range of verses…', () => showLoopDialog(context, s, a)),
        action(store.isBookmarked(s, a) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, store.isBookmarked(s, a) ? 'Remove bookmark' : 'Bookmark', () => store.toggleBookmark(s, a), on: store.isBookmarked(s, a)),
        action(store.isFav(key) ? Icons.favorite_rounded : Icons.favorite_border_rounded, store.isFav(key) ? 'Remove from favourites' : 'Add to favourites', () => store.toggleFav(key), on: store.isFav(key)),
        action(Icons.menu_book_rounded, 'Translation, words and tafsir', () => showStudy(context, s, a)),
        action(Icons.edit_note_rounded, store.noteFor(s, a).isEmpty ? 'Add a note' : 'Edit note', () => showStudy(context, s, a, tab: 3)),
        action(store.memorised.contains(key) ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, store.memorised.contains(key) ? 'Memorised' : 'Mark as memorised', () => store.toggleMemorised(key), on: store.memorised.contains(key)),
        action(Icons.copy_rounded, 'Copy verse', () {
          Clipboard.setData(ClipboardData(text: verseShareText(ay, tr.text(ay))));
          showToast(context, 'Verse copied');
        }),
        action(Icons.image_rounded, 'Share as image', () => showShareCard(context, arabic: ay.ar, translation: tr.text(ay), reference: '${sr.en} $s:$a')),
        action(Icons.ios_share_rounded, 'Share text', () => SharePlus.instance.share(ShareParams(text: verseShareText(ay, tr.text(ay))))),
      ]),
    );
  }
}

class StudyPanel extends StatefulWidget {
  const StudyPanel({super.key, required this.s, required this.a, this.tab = 0});
  final int s, a, tab;

  @override
  State<StudyPanel> createState() => _StudyPanelState();
}

class _StudyPanelState extends State<StudyPanel> {
  late int tab = widget.tab;
  late int a = widget.a;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ay = Quran.I.ayah(widget.s, a);
    final sr = Quran.I.surah(widget.s);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        child: Row(children: [
          IconButton(
            onPressed: a > 1 ? () => setState(() => a--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(children: [
              Text('${sr.en} · ${widget.s}:$a', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text(sr.ar, style: TextStyle(fontFamily: kArabicFont, color: c.textSecondary, fontSize: 15)),
            ]),
          ),
          IconButton(
            onPressed: a < sr.ayahs.length ? () => setState(() => a++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
      ),
      Segmented(items: const ['Translation', 'Words', 'Tafsir', 'Notes'], index: tab, onChanged: (i) => setState(() => tab = i)),
      const SizedBox(height: 10),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(ay.ar, style: TextStyle(fontFamily: kArabicFont, fontSize: 30, height: 1.9, color: c.text)),
            ),
            const SizedBox(height: 14),
            switch (tab) {
              0 => _TranslationTab(ayah: ay),
              1 => _WordsTab(ayah: ay),
              2 => _TafsirTab(ayah: ay),
              _ => _NoteTab(ayah: ay),
            },
          ]),
        ),
      ),
    ]);
  }
}

class _TranslationTab extends StatelessWidget {
  const _TranslationTab({required this.ayah});
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final tr = context.watch<TranslationModel>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr.text(ayah), style: const TextStyle(fontSize: 17.5, height: 1.5)),
      const SizedBox(height: 6),
      Text(tr.info.name, style: TextStyle(color: c.textSecondary, fontSize: 13)),
      if (tr.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(tr.error!, style: const TextStyle(color: Colors.redAccent))),
      const SizedBox(height: 18),
      Text('Translation', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.6)),
      const SizedBox(height: 8),
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: store.translationId,
          dropdownColor: c.surface,
          items: [
            for (final t in Quran.I.translations) DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.lang})', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => v == null ? null : store.translationId = v,
        ),
      ),
      Text('Translations other than the default download once and are then kept for offline use.', style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.4)),
    ]);
  }
}

class _WordsTab extends StatelessWidget {
  const _WordsTab({required this.ayah});
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FutureBuilder<List<WbwWord>>(
      future: Quran.I.wordsOf(ayah.surah, ayah.n),
      builder: (context, snap) {
        if (!snap.hasData) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        final words = snap.data!;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final w in words)
                Container(
                  width: 112,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Text(w.ar, style: TextStyle(fontFamily: kArabicFont, fontSize: 24, color: c.text)),
                    const SizedBox(height: 6),
                    Directionality(textDirection: TextDirection.ltr, child: Text(w.translit, textAlign: TextAlign.center, style: TextStyle(color: c.accent, fontSize: 12.5, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 2),
                    Directionality(textDirection: TextDirection.ltr, child: Text(w.meaning, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.25))),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TafsirTab extends StatelessWidget {
  const _TafsirTab({required this.ayah});
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final info = Quran.I.tafsirs.firstWhere((t) => t.id == store.tafsirId, orElse: () => Quran.I.tafsirs.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: info.id,
          dropdownColor: c.surface,
          items: [for (final t in Quran.I.tafsirs) DropdownMenuItem(value: t.id, child: Text(t.name))],
          onChanged: (v) => v == null ? null : store.tafsirId = v,
        ),
      ),
      const SizedBox(height: 8),
      FutureBuilder<List<String>>(
        key: ValueKey('${info.id}-${ayah.surah}'),
        future: Quran.I.tafsir(info.id, ayah.surah),
        builder: (context, snap) {
          if (snap.hasError) return Text('Could not load the tafsir. Check your connection and try again.', style: TextStyle(color: c.textSecondary));
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          final text = ayah.n - 1 < snap.data!.length ? snap.data![ayah.n - 1] : '';
          return Directionality(
            textDirection: info.rtl ? TextDirection.rtl : TextDirection.ltr,
            child: SelectableText(text.isEmpty ? 'No commentary for this verse in this tafsir.' : text, style: const TextStyle(fontSize: 16.5, height: 1.65)),
          );
        },
      ),
    ]);
  }
}

class _NoteTab extends StatefulWidget {
  const _NoteTab({required this.ayah});
  final Ayah ayah;

  @override
  State<_NoteTab> createState() => _NoteTabState();
}

class _NoteTabState extends State<_NoteTab> {
  late final TextEditingController _c = TextEditingController(text: context.read<AppStore>().noteFor(widget.ayah.surah, widget.ayah.n));

  @override
  void didUpdateWidget(covariant _NoteTab old) {
    super.didUpdateWidget(old);
    if (old.ayah.global != widget.ayah.global) _c.text = context.read<AppStore>().noteFor(widget.ayah.surah, widget.ayah.n);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.read<AppStore>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _c,
        minLines: 5,
        maxLines: 10,
        onChanged: (v) => store.setNote(widget.ayah.surah, widget.ayah.n, v),
        decoration: InputDecoration(
          hintText: 'Write what this verse means to you…',
          filled: true,
          fillColor: c.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 8),
      Text('Saved on this device as you type.', style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
    ]);
  }
}


/// Lets the person choose how many verses to loop from [s]:[a] and how many times: for memorisation.
Future<void> showLoopDialog(BuildContext context, int s, int a) {
  final audio = context.read<AudioController>();
  final count = Quran.I.surah(s).ayahs.length;
  var to = a;
  var times = 5;
  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final c = ctx.c;
        return AlertDialog(
          backgroundColor: c.bg,
          title: Text('Loop ${Quran.I.surah(s).en} from verse $a'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Up to verse', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<int>(
              isExpanded: true,
              value: to,
              items: [for (var v = a; v <= math.min(count, a + 29); v++) DropdownMenuItem(value: v, child: Text('Verse $v'))],
              onChanged: (v) => setState(() => to = v ?? to),
            ),
            const SizedBox(height: 12),
            const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<int>(
              isExpanded: true,
              value: times,
              items: [for (final t in const [2, 3, 5, 7, 10, 20, 0]) DropdownMenuItem(value: t, child: Text(t == 0 ? 'Until I stop it' : '$t times'))],
              onChanged: (v) => setState(() => times = v ?? times),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                audio.playRange(s, a, to, repeats: times);
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    ),
  );
}
