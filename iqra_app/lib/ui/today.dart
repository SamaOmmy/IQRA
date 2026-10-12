import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';
import '../core/content.dart';
import '../core/prayer.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'discover/discover_widgets.dart';
import 'page_scaffold.dart';
import 'reader.dart';
import 'shell.dart';
import 'tools/prayer_screen.dart';
import 'widgets.dart';

int dayIndex([DateTime? d]) {
  final t = d ?? DateTime.now();
  return DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000;
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Peaceful night';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  if (h < 20) return 'Good evening';
  return 'Peaceful evening';
}

String hijriToday() {
  try {
    HijriCalendar.setLocal('en');
    final h = HijriCalendar.now();
    return '${h.hDay} ${h.longMonthName} ${h.hYear} AH';
  } catch (_) {
    return '';
  }
}

String gregorianToday() {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final n = DateTime.now();
  return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]}';
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final content = Content.I;
    final wide = MediaQuery.of(context).size.width > 760;
    final dv = content.dailyVerses[dayIndex() % content.dailyVerses.length];
    final stories = content.stories;
    final storyPick = [for (var i = 0; i < 8; i++) stories[(dayIndex() * 3 + i * 13) % stories.length]];
    final hadith = content.hadith[dayIndex() % content.hadith.length] as Map<String, dynamic>;
    final name = content.names[dayIndex() % content.names.length];

    return LargePage(
      title: greeting(),
      subtitle: '${gregorianToday()} · ${hijriToday()}',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 6, child: _ContinueCard(store: store)),
                    const SizedBox(width: 16),
                    const Expanded(flex: 5, child: _PrayerCard()),
                  ])
                : Column(children: [_ContinueCard(store: store), const SizedBox(height: 14), const _PrayerCard()]),
          ),
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: _ProgressRow(store: store))),
        SliverToBoxAdapter(child: const SectionHeader('Verse of the day')),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _DailyVerse(ref: dv))),
        const SliverToBoxAdapter(child: SectionHeader('Stories for today')),
        SliverToBoxAdapter(
          child: Shelf(height: 214, children: [
            for (final st in storyPick) StoryTile(story: st, width: 168),
          ]),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Quick tools')),
        SliverToBoxAdapter(child: _QuickTools()),
        SliverToBoxAdapter(child: const SectionHeader('Hadith of the day')),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: HadithCard(h: hadith))),
        SliverToBoxAdapter(child: const SectionHeader('Name of Allah')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ColorTile(
              seed: dayIndex() + 4,
              height: 150,
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(children: [
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name[1] as String, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(name[2] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14.5, height: 1.4)),
                    ]),
                  ),
                  Directionality(textDirection: TextDirection.rtl, child: Text(name[0] as String, style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 44))),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final started = store.hasStartedReading;
    final s = started ? store.lastSurah : 1;
    final a = started ? store.lastAyah : 1;
    final sr = Quran.I.surah(s);
    final audio = context.read<AudioController>();
    final (c1, c2) = artColors(s * 5 + 2);
    return Pressable(
      onTap: () => openReader(context, surah: s, ayah: a),
      radius: 24,
      scale: 0.985,
      hover: false,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
          boxShadow: [BoxShadow(color: c1.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        padding: const EdgeInsets.all(22),
        child: Stack(children: [
          Positioned(
            right: 0,
            top: 0,
            child: Directionality(textDirection: TextDirection.rtl, child: Text(sr.ar, style: TextStyle(fontFamily: kArabicFont, color: Colors.white.withValues(alpha: 0.95), fontSize: 46))),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(started ? 'CONTINUE READING' : 'START READING', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text(sr.en, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            Text(started ? 'Verse $a of ${sr.ayahs.length} · page ${Quran.I.ayah(s, a).page}' : sr.meaning, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
            const Spacer(),
            Row(children: [
              FilledButton.icon(
                onPressed: () => audio.playVerse(s, a, scope: PlayScope.continuous),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Listen'),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
              const SizedBox(width: 10),
              Text('or tap to read', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13.5)),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _PrayerCard extends StatefulWidget {
  const _PrayerCard();

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final place = store.place;
    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerScreen())),
      radius: 24,
      scale: 0.985,
      hover: false,
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
        child: place == null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.access_time_filled_rounded, color: c.accent), const SizedBox(width: 8), const Text('Prayer times', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))]),
                const Spacer(),
                Text('Choose your city to see today’s prayer times and the time left to the next one.', style: TextStyle(color: c.textSecondary, height: 1.4)),
                const SizedBox(height: 10),
                Text('Set up  ›', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
              ])
            : Builder(builder: (_) {
                final n = nextPrayer(place, method: store.prayerMethod, hanafi: store.hanafi);
                final left = n.at.difference(DateTime.now().toUtc());
                final h = left.inHours, m = left.inMinutes % 60, s = left.inSeconds % 60;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.access_time_filled_rounded, color: c.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('NEXT PRAYER', style: TextStyle(color: c.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
                    const Spacer(),
                    Text(place.name, style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(kPrayerNames[n.key]!, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                    const SizedBox(width: 10),
                    Text(kPrayerArabic[n.key]!, style: TextStyle(fontFamily: kArabicFont, fontSize: 22, color: c.textSecondary)),
                  ]),
                  Text(clockText(n.at, place, h24: store.clock24), style: TextStyle(color: c.accent, fontSize: 19, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    '${h > 0 ? '${h}h ' : ''}${m.toString().padLeft(h > 0 ? 2 : 1, '0')}m ${s.toString().padLeft(2, '0')}s left',
                    style: TextStyle(color: c.textSecondary, fontSize: 14.5, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ]);
              }),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final today = store.daysRead[todayKey()] ?? 0;
    final goal = store.dailyGoalPages;
    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Icon(icon, color: c.accent, size: 24),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
              ]),
            ]),
          ),
        );
    return Row(children: [
      stat(Icons.local_fire_department_rounded, '${store.streak}', 'day streak'),
      const SizedBox(width: 12),
      stat(Icons.menu_book_rounded, '$today / $goal', 'pages today'),
      const SizedBox(width: 12),
      stat(Icons.flag_rounded, '${store.pagesRead.length}', 'of 604 pages'),
    ]);
  }
}

class _DailyVerse extends StatelessWidget {
  const _DailyVerse({required this.ref});
  final List<dynamic> ref; // [surah, first, last?]

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tr = context.watch<TranslationModel>();
    final s = ref[0] as int, a = ref[1] as int, b = ref.length > 2 ? ref[2] as int : a;
    final ayahs = [for (var i = a; i <= b; i++) Quran.I.ayah(s, i)];
    final arabic = ayahs.map((x) => x.ar).join(' ');
    final text = ayahs.map(tr.text).join(' ');
    final audio = context.read<AudioController>();
    return Pressable(
      onTap: () => openReader(context, surah: s, ayah: a),
      radius: 22,
      scale: 0.99,
      hover: false,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Directionality(textDirection: TextDirection.rtl, child: Text(arabic, textAlign: TextAlign.center, style: TextStyle(fontFamily: kArabicFont, fontSize: 30, height: 1.9, color: c.text))),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 16, height: 1.5)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${Quran.I.surah(s).en} ${b == a ? '$s:$a' : '$s:$a–$b'}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => audio.playVerse(s, a, scope: PlayScope.page, page: Quran.I.ayah(s, a).page),
              icon: Icon(Icons.play_circle_fill_rounded, color: c.accent, size: 30),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _QuickTools extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, Section, int)>[
      ('Prayer times', Icons.access_time_filled_rounded, Section.tools, 1),
      ('Tasbih', Icons.touch_app_rounded, Section.tools, 2),
      ('Qibla', Icons.explore_rounded, Section.tools, 3),
      ('Calendar', Icons.calendar_month_rounded, Section.tools, 4),
      ('Quiz', Icons.quiz_rounded, Section.tools, 5),
      ('Zakat', Icons.volunteer_activism_rounded, Section.tools, 6),
    ];
    return Shelf(height: 104, gap: 12, children: [
      for (final it in items)
        Pressable(
          radius: 20,
          scale: 0.96,
          hover: false,
          onTap: () => AppShell.of(context)?.go(it.$3),
          child: ColorTile(
            seed: it.$4 + 7,
            width: 128,
            height: 104,
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(it.$2, color: Colors.white, size: 28),
                const Spacer(),
                Text(it.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
              ]),
            ),
          ),
        ),
    ]);
  }
}
