import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'page_scaffold.dart';
import 'reader.dart';
import 'widgets.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  late int _tab = context.read<AppStore>().uiInt('readTab', 0); // 0 surahs, 1 juz, 2 go to
  late int _filter = context.read<AppStore>().uiInt('readFilter', 0); // 0 all, 1 Meccan, 2 Medinan

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final surahs = [
      for (final s in Quran.I.surahs)
        if (_filter == 0 || (_filter == 1 && s.meccan) || (_filter == 2 && !s.meccan)) s,
    ];
    return LargePage(
      title: 'Read',
      subtitle: '114 surahs · 30 juz · 604 pages',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Segmented(items: const ['Surahs', 'Juz', 'Go to'], index: _tab, onChanged: (i) {
                setState(() => _tab = i);
                store.setUiInt('readTab', i);
              }),
              if (_tab == 0) ...[
                Pill('All', selected: _filter == 0, onTap: () {
                  setState(() => _filter = 0);
                  store.setUiInt('readFilter', 0);
                }),
                Pill('Meccan', selected: _filter == 1, onTap: () {
                  setState(() => _filter = 1);
                  store.setUiInt('readFilter', 1);
                }),
                Pill('Medinan', selected: _filter == 2, onTap: () {
                  setState(() => _filter = 2);
                  store.setUiInt('readFilter', 2);
                }),
              ],
            ]),
          ),
        ),
        if (_tab == 0)
          TileGrid(
            count: surahs.length,
            builder: (context, i) {
              final s = surahs[i];
              return Reveal(
                index: i % 12,
                child: ArtTile(
                  surah: s.n,
                  onOpen: () => openReader(context, surah: s.n, mushaf: false),
                  onPlay: () => context.read<AudioController>().playVerse(s.n, 1, scope: PlayScope.surah),
                  onMore: () => openReader(context, surah: s.n, mushaf: true),
                ),
              );
            },
          )
        else if (_tab == 1)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 96),
              itemCount: 30,
              itemBuilder: (context, i) {
                final juz = i + 1;
                final start = Quran.I.juzStart(juz);
                return Pressable(
                  onTap: () => openReader(context, surah: start.surah, ayah: start.n, page: start.page, mushaf: true),
                  radius: 18,
                  hover: false,
                  scale: 0.97,
                  child: ColorTile(
                    seed: juz * 3,
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Juz $juz', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${Quran.I.surah(start.surah).en} ${start.surah}:${start.n}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5)),
                      ]),
                    ),
                  ),
                );
              },
            ),
          )
        else
          SliverToBoxAdapter(child: _GoTo(store: store)),
      ],
    );
  }
}

class _GoTo extends StatefulWidget {
  const _GoTo({required this.store});
  final AppStore store;

  @override
  State<_GoTo> createState() => _GoToState();
}

class _GoToState extends State<_GoTo> {
  final _page = TextEditingController();
  final _verse = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    _verse.dispose();
    super.dispose();
  }

  void _openPage() {
    final p = int.tryParse(_page.text.trim());
    if (p == null || p < 1 || p > 604) {
      showToast(context, 'Enter a page from 1 to 604');
      return;
    }
    final w = Quran.I.pageWords(p).first;
    openReader(context, surah: w.surah, ayah: w.ayah, page: p, mushaf: true);
  }

  void _openVerse() {
    final m = RegExp(r'^\s*(\d{1,3})\s*[:.\s]\s*(\d{1,3})\s*$').firstMatch(_verse.text);
    if (m == null) {
      showToast(context, 'Type a verse like 2:255');
      return;
    }
    final s = int.parse(m[1]!), a = int.parse(m[2]!);
    if (s < 1 || s > 114 || a < 1 || a > Quran.I.surah(s).ayahs.length) {
      showToast(context, 'That verse does not exist');
      return;
    }
    openReader(context, surah: s, ayah: a, mushaf: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget field(String label, String hint, TextEditingController ctl, VoidCallback go, TextInputType kb) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: ctl,
                  keyboardType: kb,
                  onSubmitted: (_) => go(),
                  decoration: InputDecoration(hintText: hint, filled: true, fillColor: c.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: go, style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16)), child: const Text('Go')),
            ]),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(children: [
        field('Go to a page', 'Page 1–604', _page, _openPage, TextInputType.number),
        const SizedBox(height: 14),
        field('Go to a verse', 'Surah:verse, for example 2:255', _verse, _openVerse, TextInputType.text),
      ]),
    );
  }
}
