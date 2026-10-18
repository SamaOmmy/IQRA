import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/achievements.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'discover/lists.dart';
import 'page_scaffold.dart';
import 'plan_screen.dart';
import 'reader.dart';
import 'review_screen.dart';
import 'study.dart';
import 'widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late int _tab = context.read<AppStore>().uiInt('libraryTab', 0);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppStore>();
    final bookmarks = s.bookmarks;
    final notes = s.notes.entries.toList();
    final memorised = s.memorised.toList()..sort((a, b) => VerseRef.parse(a).s != VerseRef.parse(b).s ? VerseRef.parse(a).s - VerseRef.parse(b).s : VerseRef.parse(a).a - VerseRef.parse(b).a);

    return LargePage(
      title: 'Library',
      subtitle: 'Your bookmarks, notes and progress',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Segmented(items: const ['Bookmarks', 'Notes', 'Memorised', 'Progress'], index: _tab, onChanged: (i) {
                setState(() => _tab = i);
                s.setUiInt('libraryTab', i);
              }),
            ),
          ),
        ),
        if (_tab == 0)
          bookmarks.isEmpty
              ? const SliverFillRemaining(hasScrollBody: false, child: Empty(Icons.bookmark_border_rounded, 'No bookmarks yet', 'Tap a verse and choose Bookmark to keep your place.'))
              : SliverList.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, i) => _verseRow(context, bookmarks[i], trailing: Icons.bookmark_rounded, onTrailing: () => s.toggleBookmark(bookmarks[i].s, bookmarks[i].a)),
                ),
        if (_tab == 1)
          notes.isEmpty
              ? const SliverFillRemaining(hasScrollBody: false, child: Empty(Icons.edit_note_rounded, 'No notes yet', 'Open a verse’s study panel and write what it means to you.'))
              : SliverList.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final r = VerseRef.parse(notes[i].key);
                    return _verseRow(context, r, note: notes[i].value, onTap: () => showStudy(context, r.s, r.a, tab: 3));
                  },
                ),
        if (_tab == 2) ...[
          if (memorised.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Pressable(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewScreen())),
                  radius: 18,
                  hover: false,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: c.accent.withValues(alpha: c.dark ? 0.2 : 0.12), borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Icon(Icons.psychology_rounded, color: c.accent, size: 30),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Review what you know', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('${s.dueReviews().length} due today · spaced over days and weeks', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                    ]),
                  ),
                ),
              ),
            ),
          memorised.isEmpty
              ? const SliverFillRemaining(hasScrollBody: false, child: Empty(Icons.check_circle_outline_rounded, 'Nothing marked yet', 'Mark verses you have memorised from the verse menu. They come back here for review at growing intervals.'))
              : SliverList.builder(itemCount: memorised.length, itemBuilder: (context, i) => _verseRow(context, VerseRef.parse(memorised[i]))),
        ],
        if (_tab == 3) SliverToBoxAdapter(child: _Progress(store: s)),
        if (_tab == 0 && s.favs.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Pressable(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedScreen())),
                radius: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.favorite_rounded, color: c.accent),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${s.favs.length} saved stories, hadith and verses', style: const TextStyle(fontWeight: FontWeight.w700))),
                    Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _verseRow(BuildContext context, VerseRef r, {String? note, IconData? trailing, VoidCallback? onTrailing, VoidCallback? onTap}) {
    final c = context.c;
    final a = Quran.I.ayah(r.s, r.a);
    final sr = Quran.I.surah(r.s);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Pressable(
        onTap: onTap ?? () => openReader(context, surah: r.s, ayah: r.a),
        radius: 16,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SurahArt(surah: r.s, size: 52, showName: false, radius: 11),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${sr.en} ${r.s}:${r.a}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 4),
                Directionality(textDirection: TextDirection.rtl, child: Text(a.ar, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: kArabicFont, fontSize: 19, color: c.textSecondary))),
                if (note != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(note, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4))),
              ]),
            ),
            if (trailing != null) IconButton(onPressed: onTrailing, icon: Icon(trailing, color: c.accent)),
          ]),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final read = store.pagesRead.length;
    final days = store.daysRead;
    final week = [for (var i = 6; i >= 0; i--) DateTime.now().subtract(Duration(days: i))];
    final maxDay = week.map((d) => days[todayKey(d)] ?? 0).fold<int>(1, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: read / 604, strokeWidth: 10, strokeCap: StrokeCap.round, backgroundColor: c.bg, color: c.accent)),
                Text('${(read / 604 * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current khatam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 4),
                Text('$read of 604 pages read', style: TextStyle(color: c.textSecondary)),
                Text('${store.khatams} completed', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('This week', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
              Icon(Icons.local_fire_department_rounded, color: c.accent),
              const SizedBox(width: 4),
              Text('${store.streak} day streak', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final d in week)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('${days[todayKey(d)] ?? 0}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        height: 6 + 62 * ((days[todayKey(d)] ?? 0) / maxDay),
                        decoration: BoxDecoration(color: (days[todayKey(d)] ?? 0) >= store.dailyGoalPages ? c.accent : c.accent.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 6),
                      Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1], style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            const Expanded(child: Text('Daily goal (pages)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            IconButton(onPressed: store.dailyGoalPages > 1 ? () => store.dailyGoalPages = store.dailyGoalPages - 1 : null, icon: const Icon(Icons.remove_circle_outline_rounded)),
            Text('${store.dailyGoalPages}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            IconButton(onPressed: () => store.dailyGoalPages = store.dailyGoalPages + 1, icon: const Icon(Icons.add_circle_outline_rounded)),
          ]),
        ),
        const SizedBox(height: 14),
        _JuzMap(read: store.pagesRead),
        const SizedBox(height: 14),
        Pressable(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanScreen())),
          radius: 20,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(Icons.flag_rounded, color: c.accent),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Khatam plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(store.plan == null ? 'Finish the Qur’an in a time you choose' : 'In progress · tap to see today’s pages', style: TextStyle(color: c.textSecondary, fontSize: 13)),
              ])),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Align(alignment: Alignment.centerLeft, child: Text('Milestones', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, box) {
          final badges = milestonesFor(store);
          final cols = box.maxWidth > 640 ? 4 : (box.maxWidth > 420 ? 3 : 2);
          final w = (box.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final b in badges)
              Container(
                width: w,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: b.unlocked ? c.accent.withValues(alpha: c.dark ? 0.22 : 0.12) : c.surface, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(b.icon, color: b.unlocked ? c.accent : c.textSecondary.withValues(alpha: 0.5), size: 28),
                  const SizedBox(height: 8),
                  Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: b.unlocked ? c.text : c.textSecondary)),
                  const SizedBox(height: 2),
                  Text(b.how, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.3)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: b.progress, minHeight: 5, backgroundColor: c.bg, color: c.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(b.unlocked ? 'Done' : '${b.value} / ${b.target}', style: TextStyle(color: b.unlocked ? c.accent : c.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                ]),
              ),
          ]);
        }),
      ]),
    );
  }
}


/// Thirty little bars: how much of each juz has been read.
class _JuzMap extends StatelessWidget {
  const _JuzMap({required this.read});
  final Set<int> read;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final starts = [for (var j = 1; j <= 30; j++) Quran.I.juzStart(j).page, 605];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('The 30 juz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 4),
        Text('Each bar fills as you read its pages.', style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, box) {
          const cols = 10;
          final w = (box.maxWidth - 8 * (cols - 1)) / cols;
          return Wrap(spacing: 8, runSpacing: 10, children: [
            for (var j = 0; j < 30; j++)
              Builder(builder: (_) {
                final from = starts[j], to = starts[j + 1] - 1;
                final total = to - from + 1;
                var got = 0;
                for (var p = from; p <= to; p++) {
                  if (read.contains(p)) got++;
                }
                final f = total == 0 ? 0.0 : got / total;
                return SizedBox(
                  width: w,
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: f, minHeight: 9, backgroundColor: c.bg, color: c.accent),
                    ),
                    const SizedBox(height: 4),
                    Text('${j + 1}', style: TextStyle(fontSize: 10.5, color: f >= 1 ? c.accent : c.textSecondary, fontWeight: f >= 1 ? FontWeight.w800 : FontWeight.w500)),
                  ]),
                );
              }),
          ]);
        }),
      ]),
    );
  }
}
