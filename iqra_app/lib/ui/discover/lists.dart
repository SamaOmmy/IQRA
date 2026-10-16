import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio.dart';
import '../../core/content.dart';
import '../../core/quran.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../reader.dart';
import '../widgets.dart';
import 'discover_widgets.dart';
import 'hadith_detail.dart';

const kHadithThemes = <(String, String)>[
  ('manners', 'Character and manners'),
  ('mercy', 'Mercy and family'),
  ('faith', 'Faith and trust in Allah'),
  ('worship', 'Worship and remembrance'),
  ('knowledge', 'Knowledge and ongoing good'),
  ('charity', 'Charity and generosity'),
  ('dua', 'Dua and dhikr'),
  ('family', 'Parents and family'),
  ('brotherhood', 'Brotherhood and community'),
  ('trade', 'Work and honest dealing'),
  ('hardship', 'Hardship and the Hereafter'),
  ('quran', 'The Qur’an'),
];

Widget _pad(Widget w) => Reveal(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: w));

class ShelfScreen extends StatelessWidget {
  const ShelfScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final shelf = Content.I.shelves.firstWhere((s) => s['id'] == id);
    final raw = Content.I.storiesOf(id);
    final position = {for (var i = 0; i < raw.length; i++) raw[i]: i};
    // by the timeline number where a shelf has one, otherwise in the order written (List.sort is not stable on its own)
    final list = [...raw]..sort((a, b) {
        final c = ((a['ord'] ?? a['n'] ?? 0) as num).compareTo((b['ord'] ?? b['n'] ?? 0) as num);
        return c != 0 ? c : position[a]!.compareTo(position[b]!);
      });
    return LargePage(
      title: shelf['title'] as String,
      subtitle: shelf['blurb'] as String?,
      maxWidth: 900,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Text(
              'Written for IQRA from the Qur’an, Sahih al-Bukhari, Sahih Muslim and the classical biographies. Where a detail comes from the biographies rather than the two Sahihs, the story says so.',
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.45),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => Reveal(index: i % 10, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: StoryRow(story: list[i], index: id == 'sira' ? i + 1 : null))),
        ),
      ],
    );
  }
}

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key, this.theme});
  final String? theme;

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String? _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
  }

  @override
  Widget build(BuildContext context) {
    final all = [for (final h in Content.I.hadith) h as Map<String, dynamic>];
    final list = _theme == null ? all : all.where((h) => h['theme'] == _theme).toList();
    final title = _theme == null ? 'Hadith' : kHadithThemes.firstWhere((t) => t.$1 == _theme).$2;
    return LargePage(
      title: title,
      subtitle: '${list.length} hadith · Arabic, translation and explanation',
      maxWidth: 860,
      slivers: [
        SliverToBoxAdapter(
          child: Shelf(height: 54, gap: 8, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), children: [
            Pill('All (${all.length})', selected: _theme == null, onTap: () => setState(() => _theme = null)),
            for (final t in kHadithThemes) Pill(t.$2, selected: _theme == t.$1, onTap: () => setState(() => _theme = t.$1)),
          ]),
        ),
        SliverList.builder(itemCount: list.length, itemBuilder: (_, i) => _pad(HadithCard(h: list[i]))),
      ],
    );
  }
}

class NawawiScreen extends StatelessWidget {
  const NawawiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ar = Content.I.nawawiArabic;
    final notes = Content.I.nawawiNotes;
    return LargePage(
      title: 'The Forty Hadith',
      subtitle: 'Imam an-Nawawi · ${ar.length} hadith',
      maxWidth: 860,
      slivers: [
        SliverList.builder(
          itemCount: ar.length,
          itemBuilder: (_, i) {
            final h = ar[i] as Map<String, dynamic>;
            final number = (h['n'] as num).toInt();
            final note = number < notes.length ? notes[number] : null;
            final hasX = h['x'] != null;
            void open() => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HadithDetailScreen(
                    title: note != null ? note['t'] as String : 'Hadith ${h['n']}',
                    arabic: h['ar'] as String,
                    summary: (h['en'] as String?) ?? (note != null ? note['s'] as String : ''),
                    source: 'The Forty Hadith of an-Nawawi, hadith ${h['n']}',
                    explain: (h['x'] as Map?)?.cast<String, dynamic>(),
                    favKey: 'nawawi:${h['n']}',
                    number: (h['n'] as num).toInt(),
                  ),
                ));
            return _pad(Pressable(
              onTap: open,
              radius: 20,
              scale: 0.99,
              hover: false,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Hadith ${h['n']}${note != null ? ' · ${note['t']}' : ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  Directionality(textDirection: TextDirection.rtl, child: Text(h['ar'] as String, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: kArabicFont, fontSize: 24, height: 1.9, color: c.text))),
                  if (h['en'] != null || note != null) ...[
                    const SizedBox(height: 10),
                    Text('TRANSLATION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.accent)),
                    const SizedBox(height: 3),
                    Text((h['en'] as String?) ?? note!['s'] as String, maxLines: 5, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 15, height: 1.5)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(hasX ? Icons.auto_stories_rounded : Icons.chevron_right_rounded, size: 18, color: c.accent),
                    const SizedBox(width: 6),
                    Text(hasX ? 'Read the explanation' : 'Open', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
            ));
          },
        ),
      ],
    );
  }
}

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cols = Content.I.collections;
    return LargePage(
      title: 'Collections',
      subtitle: '${cols.length} collections of verses and duas',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 128),
            itemCount: cols.length,
            itemBuilder: (context, i) {
              final col = cols[i];
              return Pressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CollectionScreen(id: col['id'] as String))),
                radius: 20,
                scale: 0.97,
                hover: false,
                child: ColorTile(
                  seed: (col['id'] as String).codeUnits.fold<int>(11, (a, b) => (a * 31 + b) & 0xFFFF),
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Align(alignment: Alignment.centerRight, child: Directionality(textDirection: TextDirection.rtl, child: Text(col['ar'] as String, style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 21)))),
                      const Spacer(),
                      Text(col['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.15)),
                      Text('${(col['items'] as List).length} items', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final col = Content.I.collection(id)!;
    final items = (col['items'] as List).cast<Map<String, dynamic>>();
    return LargePage(
      title: col['title'] as String,
      subtitle: col['blurb'] as String?,
      maxWidth: 860,
      slivers: [
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];
            if (it['v'] != null) {
              final v = (it['v'] as List).cast<int>();
              return _pad(VerseBlock(s: v[0], a: v[1], b: v.length > 2 ? v[2] : null));
            }
            if (it['hisn'] != null) {
              final ch = Content.I.hisn[it['hisn'] as int] as Map<String, dynamic>;
              return _pad(Pressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HisnChapterScreen(index: it['hisn'] as int))),
                radius: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.favorite_rounded, color: context.c.accent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(ch['en'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
                    Directionality(textDirection: TextDirection.rtl, child: Text(ch['ar'] as String, style: TextStyle(fontFamily: kArabicFont, color: context.c.textSecondary, fontSize: 16))),
                  ]),
                ),
              ));
            }
            if (it['surah'] != null) {
              final sn = it['surah'] as int;
              final s = Quran.I.surah(sn);
              return _pad(Pressable(
                onTap: () => openReader(context, surah: sn, mushaf: false),
                radius: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.c.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    SurahArt(surah: sn, size: 56, showName: false, radius: 12),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Surah ${s.en}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text('${s.meaning} · ${s.ayahs.length} verses', style: TextStyle(color: context.c.textSecondary, fontSize: 13))])),
                    IconButton(onPressed: () => context.read<AudioController>().playVerse(sn, 1, scope: PlayScope.surah), icon: Icon(Icons.play_circle_fill_rounded, color: context.c.accent, size: 32)),
                  ]),
                ),
              ));
            }
            if (it['dua'] != null) {
              final d = it['dua'] as Map<String, dynamic>;
              return _pad(DuaBlock(ar: d['ar'] as String, en: d['en'] as String?, tl: d['tl'] as String?, note: d['title'] as String?, source: d['src'] as String?));
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final guides = Content.I.guides;
    return LargePage(
      title: 'Guides',
      subtitle: 'Step by step, with the words to say',
      maxWidth: 860,
      slivers: [
        SliverList.builder(
          itemCount: guides.length,
          itemBuilder: (context, i) {
            final g = guides[i];
            return _pad(Pressable(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GuideScreen(id: g['id'] as String))),
              radius: 18,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                    child: Text('${i + 1}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                    const SizedBox(height: 2),
                    Text(g['blurb'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.35)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                ]),
              ),
            ));
          },
        ),
      ],
    );
  }
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final g = Content.I.guide(id)!;
    final steps = (g['steps'] as List).cast<Map<String, dynamic>>();
    final notes = ((g['notes'] as List?) ?? const []).cast<String>();
    return LargePage(
      title: g['title'] as String,
      subtitle: g['blurb'] as String?,
      maxWidth: 820,
      slivers: [
        SliverList.builder(
          itemCount: steps.length,
          itemBuilder: (context, i) {
            final s = steps[i];
            final v = (s['verses'] as List?)?.cast<int>();
            return Reveal(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: TextStyle(color: c.onAccent, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s['h'] as String, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, height: 1.25))),
                    ]),
                    const SizedBox(height: 10),
                    for (final p in (s['t'] as List)) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(p as String, style: const TextStyle(fontSize: 15.5, height: 1.55))),
                    if (s['ar'] != null) ...[
                      const SizedBox(height: 4),
                      Directionality(textDirection: TextDirection.rtl, child: Text(s['ar'] as String, style: TextStyle(fontFamily: kArabicFont, fontSize: 25, height: 1.9, color: c.text))),
                    ],
                    if (s['tl'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s['tl'] as String, style: TextStyle(color: c.accent, fontStyle: FontStyle.italic, height: 1.4))),
                    if (s['en'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s['en'] as String, style: TextStyle(color: c.textSecondary, height: 1.45))),
                    if (v != null) ...[
                      const SizedBox(height: 8),
                      VerseBlock(s: v[0], a: v[1], b: v.length > 2 ? v[2] : null),
                    ],
                  ]),
                ),
              ),
            );
          },
        ),
        if (notes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.accent.withValues(alpha: c.dark ? 0.16 : 0.09), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Good to know', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                  const SizedBox(height: 8),
                  for (final n in notes) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('•  $n', style: const TextStyle(height: 1.5, fontSize: 15))),
                ]),
              ),
            ),
          ),
        if (g['src'] != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), child: Text(g['src'] as String, style: TextStyle(color: c.textSecondary, fontSize: 12.5)))),
      ],
    );
  }
}

class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final names = Content.I.names;
    return LargePage(
      title: '99 Names',
      subtitle: 'Asma’ Allah al-Husna',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 148),
            itemCount: names.length,
            itemBuilder: (_, i) {
              final n = names[i];
              return Reveal(
                index: i % 9,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('${i + 1}', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      const Spacer(),
                      Directionality(textDirection: TextDirection.rtl, child: Text(n[0] as String, style: TextStyle(fontFamily: kArabicFont, fontSize: 27, color: c.text))),
                    ]),
                    const Spacer(),
                    Text(n[1] as String, style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 15.5)),
                    const SizedBox(height: 2),
                    Text(n[2] as String, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.3)),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SurahGuideScreen extends StatefulWidget {
  const SurahGuideScreen({super.key});

  @override
  State<SurahGuideScreen> createState() => _SurahGuideScreenState();
}

class _SurahGuideScreenState extends State<SurahGuideScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _q.trim().toLowerCase();
    final list = [
      for (final s in Quran.I.surahs)
        if (q.isEmpty || '${s.en} ${s.meaning} ${s.n} ${Content.I.surahIntro(s.n)}'.toLowerCase().contains(q)) s,
    ];
    return LargePage(
      title: 'About each surah',
      subtitle: 'A short introduction to all 114',
      maxWidth: 860,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Filter by name, meaning or topic…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final s = list[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Pressable(
                onTap: () => openReader(context, surah: s.n, mushaf: false),
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SurahArt(surah: s.n, size: 60, showName: false, radius: 12),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(s.en, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                          Text(s.ar, style: TextStyle(fontFamily: kArabicFont, color: c.textSecondary, fontSize: 17)),
                        ]),
                        Text('${s.meaning} · ${s.ayahs.length} verses · ${s.meccan ? 'Makkan' : 'Madinan'}', style: TextStyle(color: c.accent, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(Content.I.surahIntro(s.n), style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class FastingScreen extends StatelessWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final list = Content.I.fasting;
    return LargePage(
      title: 'Fasting',
      subtitle: 'Recommended days through the year',
      maxWidth: 820,
      slivers: [
        SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => _pad(Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(list[i]['t'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
              const SizedBox(height: 6),
              Text(list[i]['n'] as String, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 6),
              Text(list[i]['s'] as String, style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
            ]),
          )),
        ),
      ],
    );
  }
}

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final list = Content.I.moments;
    return LargePage(
      title: 'Duas for moments',
      subtitle: 'From Hisn al-Muslim',
      maxWidth: 860,
      slivers: [
        SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final m = list[i];
            final chapters = (m['hisn'] as List).cast<int>();
            return _pad(Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(m['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5))),
                  Text(m['ar'] as String, style: TextStyle(fontFamily: kArabicFont, color: c.textSecondary, fontSize: 17)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final ch in chapters)
                    if (ch < Content.I.hisn.length)
                      Pill((Content.I.hisn[ch] as Map)['en'] as String, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HisnChapterScreen(index: ch)))),
                ]),
              ]),
            ));
          },
        ),
      ],
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final favs = store.favs;
    final children = <Widget>[];
    for (final k in favs) {
      final kind = k.split(':').first;
      final rest = k.substring(kind.length + 1);
      if (kind == 'story') {
        final st = Content.I.story(rest);
        if (st != null) children.add(StoryRow(story: st));
      } else if (kind == 'hadith') {
        final h = Content.I.hadith.cast<Map<String, dynamic>>().where((e) => e['id'] == rest);
        if (h.isNotEmpty) children.add(_pad(HadithCard(h: h.first)));
      } else if (kind.isNotEmpty && int.tryParse(kind) != null) {
        final p = k.split(':');
        children.add(_pad(VerseBlock(s: int.parse(p[0]), a: int.parse(p[1]))));
      }
    }
    return LargePage(
      title: 'Saved',
      subtitle: '${favs.length} items',
      maxWidth: 860,
      slivers: [
        if (children.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: Empty(Icons.favorite_border_rounded, 'Nothing saved yet', 'Tap the heart on a story, hadith or verse to keep it here.'))
        else
          SliverList.builder(itemCount: children.length, itemBuilder: (_, i) => children[i]),
      ],
    );
  }
}

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key, required this.kind});
  final String kind; // morning | evening

  @override
  Widget build(BuildContext context) {
    final morning = kind == 'morning';
    final list = [for (final z in Content.I.azkar) z as Map<String, dynamic>].where((x) => x['type'] == 0 || x['type'] == (morning ? 1 : 2)).toList();
    return LargePage(
      title: morning ? 'Morning adhkar' : 'Evening adhkar',
      subtitle: 'Tap the counter each time you recite',
      maxWidth: 820,
      slivers: [
        SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final z = list[i];
            return _pad(DuaBlock(
              ar: z['ar'] as String,
              en: z['en'] as String?,
              tl: z['tl'] as String?,
              count: (z['count'] as num?)?.toInt() ?? 1,
              note: z['fadl'] as String?,
              source: z['source'] as String?,
              favKey: 'azkar:$kind:${z['order']}',
            ));
          },
        ),
      ],
    );
  }
}

class HisnScreen extends StatefulWidget {
  const HisnScreen({super.key});

  @override
  State<HisnScreen> createState() => _HisnScreenState();
}

class _HisnScreenState extends State<HisnScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final all = Content.I.hisn;
    final q = _q.trim().toLowerCase();
    final idx = [for (var i = 0; i < all.length; i++) if (q.isEmpty || (all[i] as Map)['en'].toString().toLowerCase().contains(q)) i];
    return LargePage(
      title: 'Hisn al-Muslim',
      subtitle: '${all.length} chapters of duas',
      maxWidth: 860,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search chapters, e.g. travel, sleep, rain…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: idx.length,
          itemBuilder: (context, k) {
            final i = idx[k];
            final ch = all[i] as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Pressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HisnChapterScreen(index: i))),
                radius: 14,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Row(children: [
                    SizedBox(width: 34, child: Text('${i + 1}', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700))),
                    Expanded(child: Text(ch['en'] as String, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))),
                    Directionality(textDirection: TextDirection.rtl, child: Text(ch['ar'] as String, style: TextStyle(fontFamily: kArabicFont, color: c.textSecondary, fontSize: 16))),
                    Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                  ]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class HisnChapterScreen extends StatelessWidget {
  const HisnChapterScreen({super.key, required this.index, this.heading});
  final int index;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final ch = Content.I.hisn[index] as Map<String, dynamic>;
    final items = (ch['items'] as List).cast<Map<String, dynamic>>();
    return LargePage(
      title: heading ?? ch['en'] as String,
      subtitle: ch['ar'] as String?,
      maxWidth: 820,
      slivers: [
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final d = items[i];
            return _pad(DuaBlock(ar: d['ar'] as String, en: d['en'] as String?, tl: d['tl'] as String?, count: (d['count'] as num?)?.toInt() ?? 1, favKey: 'hisn:$index:$i'));
          },
        ),
      ],
    );
  }
}

class HisnChapterByTitle extends StatelessWidget {
  const HisnChapterByTitle({super.key, required this.title, required this.heading});
  final String title, heading;

  @override
  Widget build(BuildContext context) {
    final i = Content.I.hisn.indexWhere((c) => (c as Map)['en'].toString().toLowerCase().contains(title));
    if (i < 0) return const LargePage(title: 'Not found', slivers: []);
    return HisnChapterScreen(index: i, heading: heading);
  }
}
