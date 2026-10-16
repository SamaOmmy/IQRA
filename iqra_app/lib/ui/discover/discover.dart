import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/content.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../shell.dart';
import '../widgets.dart';
import 'discover_widgets.dart';
import 'lists.dart';

int _seed(String s) => s.codeUnits.fold<int>(11, (a, b) => (a * 31 + b) & 0xFFFF);

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final content = Content.I;
    final store = context.watch<AppStore>();
    final shelves = content.shelves;
    final saved = store.favs;
    return LargePage(
      title: 'Discover',
      subtitle: '${content.stories.length} stories · ${content.hadith.length} hadith · guides, duas and more',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Pressable(
              onTap: () => AppShell.of(context)?.go(Section.search),
              radius: 14,
              hover: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: c.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Stories, hadith, duas, names…', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 15))),
                ]),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Daily remembrance')),
        SliverToBoxAdapter(
          child: Shelf(height: 112, gap: 12, children: [
            _Tile('Morning adhkar', 'أذكار الصباح', Icons.wb_twilight_rounded, 1, () => _push(context, const AdhkarScreen(kind: 'morning'))),
            _Tile('Evening adhkar', 'أذكار المساء', Icons.nights_stay_rounded, 3, () => _push(context, const AdhkarScreen(kind: 'evening'))),
            _Tile('After the prayer', 'بعد الصلاة', Icons.mosque_rounded, 5, () => _push(context, const HisnChapterByTitle(title: 'after completing the prayer', heading: 'After the prayer'))),
            _Tile('Before sleep', 'أذكار النوم', Icons.bedtime_rounded, 7, () => _push(context, const HisnChapterByTitle(title: 'before sleeping', heading: 'Before you sleep'))),
            _Tile('All duas', 'حصن المسلم', Icons.favorite_rounded, 9, () => _push(context, const HisnScreen())),
          ]),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Stories and history')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth > 760 ? 3 : (box.maxWidth > 480 ? 2 : 1);
              final w = (box.maxWidth - 14 * (cols - 1)) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                for (var i = 0; i < shelves.length; i++)
                  SizedBox(
                    width: w,
                    child: Reveal(
                      index: i,
                      child: Pressable(
                        onTap: () => _push(context, ShelfScreen(id: shelves[i]['id'] as String)),
                        radius: 20,
                        scale: 0.97,
                        hover: false,
                        child: ColorTile(
                          seed: _seed(shelves[i]['id'] as String),
                          height: 118,
                          radius: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                                  Text('${content.storiesOf(shelves[i]['id'] as String).length} stories', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(shelves[i]['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.15)),
                                ]),
                              ),
                              Directionality(textDirection: TextDirection.rtl, child: Text(shelves[i]['ar'] as String, style: TextStyle(fontFamily: kArabicFont, color: Colors.white.withValues(alpha: 0.9), fontSize: 19))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('The life of the Prophet ﷺ')),
        SliverToBoxAdapter(
          child: Shelf(height: 214, children: [
            for (final st in content.storiesOf('sira').take(12)) StoryTile(story: st, width: 168),
          ]),
        ),
        SliverToBoxAdapter(child: SectionHeader('Hadith', onMore: () => _push(context, const HadithScreen()))),
        SliverToBoxAdapter(
          child: Shelf(height: 46, gap: 8, children: [
            for (final t in kHadithThemes) Pill(t.$2, onTap: () => _push(context, HadithScreen(theme: t.$1))),
            Pill('The Forty Hadith', onTap: () => _push(context, const NawawiScreen()), icon: Icons.menu_book_rounded),
          ]),
        ),
        SliverToBoxAdapter(child: SectionHeader('Collections', onMore: () => _push(context, const CollectionsScreen()))),
        SliverToBoxAdapter(
          child: Shelf(height: 138, gap: 12, children: [
            for (final col in content.collections.take(12))
              Pressable(
                onTap: () => _push(context, CollectionScreen(id: col['id'] as String)),
                radius: 20,
                scale: 0.97,
                hover: false,
                child: ColorTile(
                  seed: _seed(col['id'] as String),
                  width: 190,
                  height: 138,
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Directionality(textDirection: TextDirection.rtl, child: Align(alignment: Alignment.centerRight, child: Text(col['ar'] as String, style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 20)))),
                      const Spacer(),
                      Text(col['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.2)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Learn')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              _Row(Icons.checklist_rounded, 'Step-by-step guides', 'Wudu, the prayer, Friday, fasting, Eid, Umrah, Hajj', () => _push(context, const GuidesScreen())),
              _Row(Icons.auto_awesome_rounded, 'The 99 Names of Allah', 'With meanings', () => _push(context, const NamesScreen())),
              _Row(Icons.menu_book_rounded, 'The Forty Hadith of an-Nawawi', 'Arabic with a short summary', () => _push(context, const NawawiScreen())),
              _Row(Icons.format_list_numbered_rounded, 'About each surah', 'A short introduction to all 114', () => _push(context, const SurahGuideScreen())),
              _Row(Icons.event_rounded, 'Fasting through the year', 'Recommended days and their basis', () => _push(context, const FastingScreen())),
              _Row(Icons.sentiment_satisfied_alt_rounded, 'Duas for moments', 'Waking, travelling, hardship, joy', () => _push(context, const MomentsScreen())),
            ]),
          ),
        ),
        if (saved.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeader('Saved', onMore: () => _push(context, const SavedScreen()))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('${saved.length} saved item${saved.length == 1 ? '' : 's'} · tap to open', style: TextStyle(color: c.textSecondary)),
            ),
          ),
        ],
      ],
    );
  }

  static void _push(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
}

class _Tile extends StatelessWidget {
  const _Tile(this.title, this.ar, this.icon, this.seed, this.onTap);
  final String title, ar;
  final IconData icon;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      radius: 20,
      scale: 0.96,
      hover: false,
      child: ColorTile(
        seed: seed,
        width: 172,
        height: 112,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: Colors.white, size: 26),
              const Spacer(),
              Text(ar, style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 16)),
            ]),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.title, this.sub, this.onTap);
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ]),
      ),
    );
  }
}
