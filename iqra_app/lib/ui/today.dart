import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';

import '../core/content.dart';
import '../core/hijri_events.dart';
import '../core/plan.dart';
import '../core/updates.dart';
import '../core/prayer.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'discover/discover_widgets.dart';
import 'discover/story_screen.dart';
import 'page_scaffold.dart';
import 'plan_screen.dart';
import 'reader.dart';
import 'review_screen.dart';
import 'downloads_screen.dart';
import 'tools/prayer_screen.dart';
import 'tools/qibla_screen.dart';
import 'tools/tools.dart';
import 'gradients.dart';
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
    final h = hijriOf(DateTime.now());
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
        const SliverToBoxAdapter(child: _UpdateBanner()),
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
        const SliverToBoxAdapter(child: Reveal(child: _FridayCard())),
        const SliverToBoxAdapter(child: Reveal(child: _ComingUp())),
        SliverToBoxAdapter(child: Reveal(child: _ReviewDue(store: store))),
        SliverToBoxAdapter(child: Reveal(child: Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: _PlanCard(store: store)))),
        SliverToBoxAdapter(child: Reveal(index: 1, child: Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: _ProgressRow(store: store)))),
        if (store.recentSurahs.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Continue listening')),
          SliverToBoxAdapter(
            child: Shelf(height: 208, gap: 14, children: [
              for (final n in store.recentSurahs.take(8))
                SizedBox(
                  width: 140,
                  child: ArtTile(
                    surah: n,
                    onOpen: () => openReader(context, surah: n, mushaf: false),
                    onPlay: () => context.read<AudioController>().playVerse(n, 1, scope: PlayScope.surah),
                  ),
                ),
            ]),
          ),
        ],
        SliverToBoxAdapter(child: const SectionHeader('Verse of the day')),
        SliverToBoxAdapter(child: Reveal(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _DailyVerse(ref: dv)))),
        const SliverToBoxAdapter(child: SectionHeader('Stories for today')),
        SliverToBoxAdapter(
          child: Shelf(height: 214, children: [
            for (final st in storyPick) StoryTile(story: st, width: 168),
          ]),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Quick tools')),
        SliverToBoxAdapter(child: Reveal(child: _QuickTools())),
        const SliverToBoxAdapter(child: SectionHeader('Dua of the day')),
        SliverToBoxAdapter(child: Reveal(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _DuaOfDay()))),
        SliverToBoxAdapter(child: const SectionHeader('Hadith of the day')),
        SliverToBoxAdapter(child: Reveal(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: HadithCard(h: hadith)))),
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
          boxShadow: [BoxShadow(color: c1.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GradientPainter.linear([c1, c2], radius: 24))),
          Padding(padding: const EdgeInsets.all(22), child: Stack(children: [
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
          ])),
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
        constraints: const BoxConstraints(minHeight: 190),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
        child: place == null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.access_time_filled_rounded, color: c.accent), const SizedBox(width: 8), const Text('Prayer times', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))]),
                const SizedBox(height: 22),
                Text('Choose your city to see today’s prayer times and the time left to the next one.', style: TextStyle(color: c.textSecondary, height: 1.4)),
                const SizedBox(height: 10),
                Text('Set up  ›', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
              ])
            : Builder(builder: (_) {
                final n = store.upcoming();
                final left = n.at.difference(DateTime.now().toUtc());
                final h = left.inHours, m = left.inMinutes % 60, s = left.inSeconds % 60;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.access_time_filled_rounded, color: c.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('NEXT PRAYER', maxLines: 1, style: TextStyle(color: c.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(place.name, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13))),
                  ]),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(kPrayerNames[n.key]!, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                    const SizedBox(width: 10),
                    Text(kPrayerArabic[n.key]!, style: TextStyle(fontFamily: kArabicFont, fontSize: 22, color: c.textSecondary)),
                  ]),
                  Text(clockText(n.at, place, h24: store.clock24), style: TextStyle(color: c.accent, fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 22),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: c.accent, size: 20),
              const SizedBox(width: 6),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)))),
            ]),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12.5))),
          ]),
        );
    Widget bar() => Container(width: 0.8, height: 34, color: c.separator);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        stat(Icons.local_fire_department_rounded, '${store.streak}', 'day streak'),
        bar(),
        stat(Icons.menu_book_rounded, '$today / $goal', 'pages today'),
        bar(),
        stat(Icons.flag_rounded, '${store.pagesRead.length}', 'of 604 pages'),
      ]),
    );
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
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    final items = <(String, IconData, VoidCallback)>[
      ('Prayer times', Icons.access_time_filled_rounded, () => push(const PrayerScreen())),
      ('Qibla', Icons.explore_rounded, () => push(const QiblaScreen())),
      ('Tasbih', Icons.touch_app_rounded, () => push(const TasbihScreen())),
      ('Khatam plan', Icons.flag_rounded, () => push(const PlanScreen())),
      ('Calendar', Icons.calendar_month_rounded, () => push(const CalendarScreen())),
      ('Quiz', Icons.quiz_rounded, () => push(const QuizScreen())),
      ('Downloads', Icons.cloud_download_rounded, () => push(const DownloadsScreen())),
    ];
    return Shelf(height: 104, gap: 12, children: [
      for (var i = 0; i < items.length; i++)
        Pressable(
          radius: 20,
          scale: 0.96,
          hover: false,
          onTap: items[i].$3,
          child: ColorTile(
            seed: i * 2 + 7,
            width: 128,
            height: 104,
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(items[i].$2, color: Colors.white, size: 28),
                const Spacer(),
                Text(items[i].$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context) {
    final u = context.watch<UpdateChecker>();
    final c = context.c;
    if (!u.available) return const SizedBox.shrink();
    final busy = u.downloading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
        decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.accent.withValues(alpha: 0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.system_update_alt_rounded, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('IQRA ${u.latest} is available', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                Text(u.installMessage ?? 'You have ${u.current}. Update now to get the newest features.', style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.35)),
              ]),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: busy ? null : () => u.install(),
              style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder()),
              child: Text(busy ? '${(u.progress * 100).round()}%' : (u.ready ? 'Install' : (u.canInstallHere ? 'Update' : 'Download'))),
            ),
          ]),
          if (busy) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: u.progress == 0 ? null : u.progress, minHeight: 5, color: c.accent, backgroundColor: c.accent.withValues(alpha: 0.2)))),
        ]),
      ),
    );
  }
}

/// Ramadan, or the next occasion in the Islamic calendar.
class _ComingUp extends StatelessWidget {
  const _ComingUp();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final rd = ramadanDay();
    String title, sub;
    IconData icon;
    int seed;
    String? story;
    if (rd != null) {
      icon = Icons.nights_stay_rounded;
      seed = 3;
      title = 'Ramadan · day $rd';
      final place = store.place;
      if (place != null) {
        final t = store.prayersOn();
        sub = 'Suhoor ends ${clockText(t['fajr']!, place, h24: store.clock24)} · Iftar ${clockText(t['maghrib']!, place, h24: store.clock24)}';
      } else {
        sub = 'Juz $rd of the Qur’an is today’s portion for a khatam this month.';
      }
    } else {
      final toRamadan = daysUntilRamadan();
      final events = upcomingEvents(horizon: 45);
      if (toRamadan <= 45 && (events.isEmpty || toRamadan <= events.first.daysAway)) {
        icon = Icons.nights_stay_rounded;
        seed = 3;
        title = toRamadan == 0 ? 'Ramadan begins today' : 'Ramadan in $toRamadan day${toRamadan == 1 ? '' : 's'}';
        sub = 'Start a khatam plan to finish the Qur’an this Ramadan.';
      } else if (events.isNotEmpty) {
        final e = events.first;
        icon = Icons.event_rounded;
        seed = 9;
        title = e.daysAway == 0 ? '${e.name} is today' : '${e.name} in ${e.daysAway} day${e.daysAway == 1 ? '' : 's'}';
        sub = e.note;
        story = e.story;
      } else {
        return const SizedBox.shrink();
      }
    }
    final storyId = story;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Pressable(
        onTap: storyId == null ? null : () => openStory(context, storyId),
        radius: 20,
        scale: 0.985,
        hover: false,
        child: ColorTile(
        seed: seed,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5, height: 1.35)),
                if (storyId != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Read the story  ›', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13, fontWeight: FontWeight.w700))),
              ]),
            ),
          ]),
        ),
      ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final plan = KhatamPlan.from(store);
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanScreen()));
    if (plan == null) {
      return Pressable(
        onTap: open,
        radius: 20,
        hover: false,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), shape: BoxShape.circle), child: Icon(Icons.flag_rounded, color: c.accent)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Finish the Qur’an', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
              Text('Choose a pace and get a daily reading', style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
            ])),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary),
          ]),
        ),
      );
    }
    final (from, to) = plan.todayRange();
    final read = store.planRead;
    final done = [for (var p = from; p <= to; p++) p].where(read.contains).length;
    final total = to - from + 1;
    return Pressable(
      onTap: open,
      radius: 20,
      hover: false,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: total == 0 ? 0 : done / total, strokeWidth: 5, strokeCap: StrokeCap.round, backgroundColor: c.bg, color: c.accent)),
              Text('${plan.dayIndex().clamp(0, plan.days - 1) + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today: ${from == to ? 'page $from' : 'pages $from–$to'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
            Text('$done of $total read · day ${plan.dayIndex().clamp(0, plan.days - 1) + 1} of ${plan.days}', style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
          ])),
          Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ]),
      ),
    );
  }
}


class _FridayCard extends StatelessWidget {
  const _FridayCard();

  @override
  Widget build(BuildContext context) {
    if (DateTime.now().weekday != DateTime.friday) return const SizedBox.shrink();
    final audio = context.read<AudioController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: ColorTile(
        seed: 1,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Jumu‘ah mubarak', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('Read Surah al-Kahf today, and send many blessings upon the Prophet ﷺ.', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13.5, height: 1.35)),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 8, children: [
                  FilledButton(
                    onPressed: () => openReader(context, surah: 18, mushaf: false),
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, shape: const StadiumBorder()),
                    child: const Text('Read'),
                  ),
                  OutlinedButton(
                    onPressed: () => audio.playVerse(18, 1, scope: PlayScope.surah),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), shape: const StadiumBorder()),
                    child: const Text('Listen'),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReviewDue extends StatelessWidget {
  const _ReviewDue({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final due = store.dueReviews().length;
    if (due == 0) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Pressable(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewScreen())),
        radius: 20,
        hover: false,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.accent.withValues(alpha: c.dark ? 0.2 : 0.12), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Icon(Icons.psychology_rounded, color: c.accent, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$due verse${due == 1 ? '' : 's'} to review', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
              Text('A few minutes keeps what you have memorised', style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
            ])),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary),
          ]),
        ),
      ),
    );
  }
}

class _DuaOfDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chapters = Content.I.dailyDuaChapters;
    final idx = chapters[dayIndex() % chapters.length];
    if (idx >= Content.I.hisn.length) return const SizedBox.shrink();
    final ch = Content.I.hisn[idx] as Map<String, dynamic>;
    final items = (ch['items'] as List).cast<Map<String, dynamic>>();
    final d = items[dayIndex() % items.length];
    return DuaBlock(
      ar: d['ar'] as String,
      en: d['en'] as String?,
      tl: d['tl'] as String?,
      count: (d['count'] as num?)?.toInt() ?? 1,
      note: ch['en'] as String?,
      favKey: 'hisn:$idx:${items.indexOf(d)}',
    );
  }
}
