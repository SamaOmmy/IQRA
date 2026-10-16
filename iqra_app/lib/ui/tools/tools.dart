import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../../core/content.dart';
import '../../core/hijri_events.dart';
import '../../core/prayer.dart';
import '../../core/quran.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../discover/story_screen.dart';
import '../widgets.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';

void _open(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, Widget Function())>[
      ('Prayer times', 'Times and qibla for your city', Icons.access_time_filled_rounded, () => const PrayerScreen()),
      ('Qibla', 'A live compass to the Ka‘bah', Icons.explore_rounded, () => const QiblaScreen()),
      ('Tasbih', 'A counter with haptics', Icons.touch_app_rounded, () => const TasbihScreen()),
      ('Hijri calendar', 'Occasions and a date converter', Icons.calendar_month_rounded, () => const CalendarScreen()),
      ('Salah tracker', 'Mark your prayers, keep a streak', Icons.check_circle_rounded, () => const SalahScreen()),
      ('Quiz', 'Names, surahs, stories and basics', Icons.quiz_rounded, () => const QuizScreen()),
      ('Zakat calculator', 'Work out zakat on your wealth', Icons.volunteer_activism_rounded, () => const ZakatScreen()),
    ];
    return LargePage(
      title: 'Tools',
      subtitle: 'Everyday helpers, all on your device',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 330, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 156),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return Reveal(
                index: i,
                child: Pressable(
                  onTap: () => _open(context, it.$4()),
                  radius: 22,
                  scale: 0.97,
                  hover: false,
                  child: ColorTile(
                    seed: i * 2 + 1,
                    radius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(it.$3, color: Colors.white, size: 32),
                        const Spacer(),
                        Text(it.$1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(it.$2, style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13)),
                      ]),
                    ),
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

// ---------------------------------------------------------------- Tasbih
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  int _phrase = 0;
  static const _phrases = [
    ('سُبْحَانَ اللَّهِ', 'SubhanAllah'),
    ('الْحَمْدُ لِلَّهِ', 'Alhamdulillah'),
    ('اللَّهُ أَكْبَرُ', 'Allahu Akbar'),
    ('لَا إِلَٰهَ إِلَّا اللَّهُ', 'La ilaha illa Allah'),
    ('أَسْتَغْفِرُ اللَّهَ', 'Astaghfirullah'),
  ];

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _tap(AppStore s) {
    HapticFeedback.lightImpact();
    s.tasbihTap();
    _pulse.forward(from: 0);
    if (s.tasbihTarget > 0 && s.tasbihCount == s.tasbihTarget) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppStore>();
    final target = s.tasbihTarget;
    final progress = target == 0 ? 0.0 : (s.tasbihCount % target) / target;
    final laps = target == 0 ? 0 : s.tasbihCount ~/ target;
    return LargePage(
      title: 'Tasbih',
      subtitle: '${s.tasbihTotal} total',
      maxWidth: 640,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(children: [
              SizedBox(
                height: 54,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (var i = 0; i < _phrases.length; i++) Padding(padding: const EdgeInsets.only(right: 8), child: Pill(_phrases[i].$2, selected: _phrase == i, onTap: () => setState(() => _phrase = i))),
                ]),
              ),
              const SizedBox(height: 8),
              Directionality(textDirection: TextDirection.rtl, child: Text(_phrases[_phrase].$1, style: TextStyle(fontFamily: kArabicFont, fontSize: 38, color: c.text))),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () => _tap(s),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: 1 - 0.04 * math.sin(_pulse.value * math.pi),
                    child: SizedBox(
                      width: 270,
                      height: 270,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox.expand(child: CircularProgressIndicator(value: target == 0 ? 0 : (progress == 0 && s.tasbihCount > 0 ? 1 : progress), strokeWidth: 14, strokeCap: StrokeCap.round, backgroundColor: c.surface, color: c.accent)),
                        Container(
                          width: 222,
                          height: 222,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface, boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))]),
                          alignment: Alignment.center,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${target == 0 ? s.tasbihCount : s.tasbihCount % (target == 0 ? 1 : target)}', style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w800, letterSpacing: -2)),
                            Text(target == 0 ? 'tap' : 'of $target${laps > 0 ? ' · round ${laps + 1}' : ''}', style: TextStyle(color: c.textSecondary, fontSize: 15)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(spacing: 8, children: [
                for (final t in const [33, 99, 100, 0]) Pill(t == 0 ? 'No limit' : '$t', selected: s.tasbihTarget == t, onTap: () => s.tasbihTarget = t),
              ]),
              const SizedBox(height: 18),
              TextButton.icon(onPressed: () => s.tasbihCount = 0, icon: const Icon(Icons.restart_alt_rounded), label: const Text('Reset')),
            ]),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Calendar
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _convert = DateTime.now();

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _hijriShort = ['Muharram', 'Safar', 'Rabi‘ I', 'Rabi‘ II', 'Jumada I', 'Jumada II', 'Rajab', 'Sha‘ban', 'Ramadan', 'Shawwal', 'Dhul-Qa‘dah', 'Dhul-Hijjah'];

  HijriCalendar _h(DateTime d) => hijriOf(d);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    HijriCalendar.setLocal('en');
    final first = DateTime(_month.year, _month.month);
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final lead = first.weekday - 1;
    final occasions = Content.I.occasions;
    final today = DateTime.now();
    String? occ(DateTime d) {
      final h = _h(d);
      for (final o in occasions) {
        if (o['m'] == h.hMonth && o['d'] == h.hDay) return o['name'] as String;
      }
      return null;
    }

    final hStart = _h(first), hEnd = _h(DateTime(_month.year, _month.month, days));
    final hjr = hStart.hMonth == hEnd.hMonth ? '${hStart.longMonthName} ${hStart.hYear}' : '${hStart.longMonthName} – ${hEnd.longMonthName} ${hEnd.hYear}';
    final conv = _h(_convert);

    return LargePage(
      title: 'Hijri calendar',
      subtitle: hjr,
      maxWidth: 760,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
              child: Column(children: [
                Row(children: [
                  IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(child: Text('${_months[_month.month - 1]} ${_month.year}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
                ]),
                Row(children: [for (final d in _dow) Expanded(child: Center(child: Text(d, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))))]),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: MediaQuery.of(context).size.width < 560 ? 0.8 : 1.15,
                  children: [
                    for (var i = 0; i < lead; i++) const SizedBox(),
                    for (var d = 1; d <= days; d++)
                      Builder(builder: (_) {
                        final date = DateTime(_month.year, _month.month, d);
                        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                        final o = occ(date);
                        final hd = _h(date);
                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: isToday ? c.accent : (o != null ? c.accent.withValues(alpha: 0.14) : Colors.transparent), borderRadius: BorderRadius.circular(12)),
                          child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('$d', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: isToday ? c.onAccent : c.text)),
                            Text('${hd.hDay}', style: TextStyle(fontSize: 10.5, color: isToday ? c.onAccent.withValues(alpha: 0.85) : c.textSecondary)),
                          ])),
                        );
                      }),
                  ],
                ),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Date converter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                    const SizedBox(height: 6),
                    Text('${_convert.day} ${_months[_convert.month - 1]} ${_convert.year}', style: TextStyle(color: c.textSecondary)),
                    Text('${conv.hDay} ${conv.longMonthName} ${conv.hYear} AH', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 18)),
                  ]),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _convert, firstDate: DateTime(1900), lastDate: DateTime(2100));
                    if (d != null) setState(() => _convert = d);
                  },
                  child: const Text('Pick date'),
                ),
              ]),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Occasions')),
        SliverList.builder(
          itemCount: occasions.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Pressable(
              onTap: occasions[i]['story'] == null ? null : () => openStory(context, occasions[i]['story'] as String),
              radius: 16,
              scale: 0.99,
              hover: false,
              child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                  child: Column(children: [Text('${occasions[i]['d']}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 17)), FittedBox(fit: BoxFit.scaleDown, child: Text(_hijriShort[(occasions[i]['m'] as int) - 1], style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w700)))]),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(occasions[i]['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)), const SizedBox(height: 2), Text(occasions[i]['note'] as String, style: TextStyle(color: c.textSecondary, height: 1.4, fontSize: 14)), if (occasions[i]['story'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Read the story  ›', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13)))])),
              ]),
            ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Salah tracker
class SalahScreen extends StatelessWidget {
  const SalahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppStore>();
    const five = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final log = s.salah;
    final today = todayKey();
    final doneToday = log[today] ?? const [];
    final week = [for (var i = 6; i >= 0; i--) DateTime.now().subtract(Duration(days: i))];
    var streak = 0;
    var d = DateTime.now();
    if ((log[todayKey(d)]?.length ?? 0) < 5) d = d.subtract(const Duration(days: 1));
    while ((log[todayKey(d)]?.length ?? 0) >= 5) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return LargePage(
      title: 'Salah tracker',
      subtitle: '${doneToday.length} of 5 today · $streak day streak',
      maxWidth: 640,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(children: [
              for (final p in five)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      s.toggleSalah(today, p);
                    },
                    radius: 18,
                    scale: 0.98,
                    hover: false,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(color: doneToday.contains(p) ? c.accent.withValues(alpha: 0.16) : c.surface, borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: Icon(doneToday.contains(p) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, key: ValueKey(doneToday.contains(p)), color: doneToday.contains(p) ? c.accent : c.textSecondary, size: 28)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(kPrayerNames[p]!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                        Directionality(textDirection: TextDirection.rtl, child: Text(kPrayerArabic[p]!, style: TextStyle(fontFamily: kArabicFont, fontSize: 20, color: c.textSecondary))),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('This week', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (final day in week)
                      Column(children: [
                        Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1], style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        for (var k = 0; k < 5; k++)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: (log[todayKey(day)] ?? const []).contains(five[k]) ? c.accent : c.separator),
                          ),
                      ]),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Quiz
class _Q {
  _Q(this.q, this.opts, this.answer, this.why, {this.ar, this.clue});
  final String q, why;
  final List<String> opts;
  final int answer;
  final String? ar, clue;
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _rng = math.Random();
  List<_Q> _qs = [];
  int _i = 0, _score = 0;
  int? _picked;
  String _mode = 'mixed';
  List<dynamic> _basics = [];

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/data/quiz.json').then((s) => _basics = (jsonDecode(s) as Map)['basics'] as List);
  }

  List<String> _shuffle(List<String> l) => List<String>.of(l)..shuffle(_rng);

  ({List<String> opts, int a}) _options(String correct, Iterable<String> pool) {
    final others = _shuffle(pool.where((x) => x != correct).toSet().toList()).take(3).toList();
    final opts = _shuffle([correct, ...others]);
    return (opts: opts, a: opts.indexOf(correct));
  }

  _Q _names() {
    final n = Content.I.names[_rng.nextInt(Content.I.names.length)];
    final o = _options(n[2] as String, Content.I.names.map((x) => x[2] as String));
    return _Q('What does this Name of Allah mean?', o.opts, o.a, '${n[1]} means “${n[2]}”.', ar: n[0] as String);
  }

  _Q _surahs() {
    final ss = Quran.I.surahs;
    final s = ss[_rng.nextInt(114)];
    switch (_rng.nextInt(4)) {
      case 0:
        final o = _options(s.en, ss.map((x) => x.en));
        return _Q('Which surah is number ${s.n} in the Qur’an?', o.opts, o.a, 'Surah ${s.n} is ${s.en} (${s.meaning}).');
      case 1:
        final n = s.ayahs.length;
        final set = <String>{'$n'};
        while (set.length < 4) {
          set.add('${math.max(3, n + _rng.nextInt(21) - 10)}');
        }
        final o = _options('$n', set);
        return _Q('How many verses does Surah ${s.en} have?', o.opts, o.a, '${s.en} has $n verses.');
      case 2:
        final o = _options(s.meccan ? 'Makkah' : 'Madinah', const ['Makkah', 'Madinah']);
        return _Q('Was Surah ${s.en} revealed mainly in Makkah or in Madinah?', o.opts, o.a, '${s.en} is classed as ${s.meccan ? 'Makkan' : 'Madinan'}.');
      default:
        final o = _options(s.meaning, ss.map((x) => x.meaning));
        return _Q('What does the name of Surah ${s.en} mean?', o.opts, o.a, '${s.en}: “${s.meaning}”.', ar: s.ar);
    }
  }

  _Q _basicsQ() {
    final b = _basics[_rng.nextInt(_basics.length)] as Map;
    final o = (b['o'] as List).cast<String>();
    final opts = _shuffle(o);
    return _Q(b['q'] as String, opts, opts.indexOf(o.first), b['why'] as String);
  }

  String _mask(String sentence, String title) {
    const stop = {'the', 'and', 'prophet', 'story', 'of', 'in', 'with', 'his', 'her', 'a', 'to', 'from'};
    var out = sentence;
    for (final w in title.split(RegExp(r'[^A-Za-z‘’\x27-]+')).where((w) => w.length > 3 && !stop.contains(w.toLowerCase()))) {
      out = out.replaceAll(RegExp(RegExp.escape(w), caseSensitive: false), '…');
    }
    return out;
  }

  _Q _stories() {
    final all = Content.I.stories;
    final st = all[_rng.nextInt(all.length)];
    final sentences = ((st['p'] as List).first as String).split(RegExp(r'(?<=[.!?])\s+'));
    var clue = sentences.first;
    if (clue.length < 70 && sentences.length > 1) clue += ' ${sentences[1]}';
    final same = all.where((x) => x['shelf'] == st['shelf']).map((x) => x['title'] as String).toList();
    final o = _options(st['title'] as String, same.length >= 4 ? same : all.map((x) => x['title'] as String));
    return _Q('Which story begins like this?', o.opts, o.a, 'This is “${st['title']}”, in the Stories section.', clue: _mask(clue, st['title'] as String));
  }

  void _start(String mode) {
    final kinds = mode == 'mixed' ? ['names', 'surahs', 'basics', 'stories', 'basics', 'surahs', 'names', 'basics', 'stories', 'surahs'] : List.filled(10, mode);
    final seen = <String>{};
    final qs = <_Q>[];
    for (final k in kinds) {
      for (var t = 0; t < 12; t++) {
        final q = switch (k) { 'names' => _names(), 'surahs' => _surahs(), 'basics' => _basicsQ(), _ => _stories() };
        if (seen.add('${q.q}${q.ar}${q.clue}')) {
          qs.add(q);
          break;
        }
      }
    }
    setState(() {
      _mode = mode;
      _qs = qs;
      _i = 0;
      _score = 0;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final done = _qs.isNotEmpty && _i >= _qs.length;
    return LargePage(
      title: 'Quiz',
      subtitle: 'Ten questions at a time',
      maxWidth: 680,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in const [('mixed', 'Mixed'), ('names', 'Names of Allah'), ('surahs', 'Surahs'), ('basics', 'Basics and the Sira'), ('stories', 'Stories')])
                Pill(m.$2, selected: _qs.isNotEmpty && _mode == m.$1, onTap: () => _start(m.$1)),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _qs.isEmpty
                  ? _card(c, key: 'intro', children: [
                      const Text('Ready?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('Pick a topic above to begin. The questions come from the Names of Allah, the surahs, the stories and the basics of the faith.', style: TextStyle(color: c.textSecondary, height: 1.45)),
                      if (store.quizBest > 0) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Best score: ${store.quizBest}/10', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700))),
                    ])
                  : done
                      ? _card(c, key: 'done', children: [
                          Text('$_score / ${_qs.length}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: c.accent)),
                          const SizedBox(height: 6),
                          Text(_score >= 9 ? 'Excellent, mashaAllah.' : _score >= 6 ? 'Good work. Keep learning.' : 'Every question teaches something. Try again.', style: const TextStyle(fontSize: 17)),
                          const SizedBox(height: 14),
                          FilledButton(onPressed: () => _start(_mode), style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent), child: const Text('Play again')),
                        ])
                      : _question(c),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(IqraColors c, {required String key, required List<Widget> children}) => Container(
        key: ValueKey(key),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _question(IqraColors c) {
    final q = _qs[_i];
    return _card(c, key: 'q$_i', children: [
      Text('Question ${_i + 1} of ${_qs.length}', style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(q.q, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
      if (q.ar != null) Padding(padding: const EdgeInsets.only(top: 10), child: Directionality(textDirection: TextDirection.rtl, child: Text(q.ar!, style: TextStyle(fontFamily: kArabicFont, fontSize: 34, color: c.text)))),
      if (q.clue != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('“${q.clue}”', style: TextStyle(color: c.textSecondary, fontSize: 16, height: 1.5, fontStyle: FontStyle.italic))),
      const SizedBox(height: 14),
      for (var k = 0; k < q.opts.length; k++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Pressable(
            onTap: _picked != null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _picked = k;
                      if (k == q.answer) _score++;
                    });
                  },
            radius: 14,
            scale: 0.98,
            hover: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _picked == null ? c.bg : (k == q.answer ? Colors.green.withValues(alpha: 0.2) : (k == _picked ? Colors.red.withValues(alpha: 0.2) : c.bg)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _picked != null && k == q.answer ? Colors.green : c.separator),
              ),
              child: Row(children: [
                Expanded(child: Text(q.opts[k], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                if (_picked != null && k == q.answer) const Icon(Icons.check_circle_rounded, color: Colors.green),
                if (_picked == k && k != q.answer) const Icon(Icons.cancel_rounded, color: Colors.redAccent),
              ]),
            ),
          ),
        ),
      if (_picked != null) ...[
        const SizedBox(height: 10),
        Text(q.why, style: TextStyle(color: c.textSecondary, height: 1.45)),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            final store = context.read<AppStore>();
            setState(() {
              _i++;
              _picked = null;
            });
            if (_i >= _qs.length && _score > store.quizBest) store.quizBest = _score;
          },
          style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent),
          child: Text(_i + 1 >= _qs.length ? 'See score' : 'Next'),
        ),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- Zakat
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _f = {for (final k in ['cash', 'gold', 'silver', 'invest', 'business', 'debts', 'goldPrice']) k: TextEditingController()};

  @override
  void dispose() {
    for (final c in _f.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(String k) => double.tryParse(_f[k]!.text.replaceAll(',', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final goldValue = _v('gold') * _v('goldPrice');
    final total = _v('cash') + goldValue + _v('silver') + _v('invest') + _v('business') - _v('debts');
    final nisab = 85 * _v('goldPrice'); // the gold nisab: 85 g
    final due = _v('goldPrice') > 0 && total >= nisab ? total * 0.025 : 0.0;

    Widget field(String key, String label, {String? hint}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: _f[key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
          ),
        );

    return LargePage(
      title: 'Zakat',
      subtitle: '2.5% of wealth held for a year, above the nisab',
      maxWidth: 640,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(children: [
              field('goldPrice', 'Gold price per gram', hint: 'Needed for the nisab (85 g of gold)'),
              field('cash', 'Cash and savings'),
              field('gold', 'Gold you own (grams)'),
              field('silver', 'Silver (value)'),
              field('invest', 'Investments and shares'),
              field('business', 'Business goods and money owed'),
              field('debts', 'Debts you owe now'),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(22)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Net wealth: ${total.toStringAsFixed(2)}', style: TextStyle(color: c.textSecondary, fontSize: 14.5)),
                  Text('Nisab (85 g gold): ${nisab.toStringAsFixed(2)}', style: TextStyle(color: c.textSecondary, fontSize: 14.5)),
                  const SizedBox(height: 10),
                  Text('Zakat due', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800)),
                  Text(due.toStringAsFixed(2), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(_v('goldPrice') == 0 ? 'Enter the gold price to compare with the nisab.' : (due == 0 ? 'Your wealth is below the nisab, so zakat is not due.' : 'Pay this to those who deserve it (9:60).'), style: TextStyle(color: c.textSecondary, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 10),
              Text('A simple estimate only. For gold, silver and special cases, ask a scholar.', style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
            ]),
          ),
        ),
      ],
    );
  }
}
