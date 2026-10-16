import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/plan.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'page_scaffold.dart';
import 'reader.dart';
import 'widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final plan = KhatamPlan.from(store);
    return LargePage(
      title: 'Khatam plan',
      subtitle: plan == null ? 'Finish the Qur’an in a time you choose' : 'Day ${plan.dayIndex().clamp(0, plan.days - 1) + 1} of ${plan.days}',
      maxWidth: 760,
      slivers: [
        if (plan == null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Pick how long you want to take. IQRA splits the 604 pages evenly, shows what to read each day and keeps you on track as you read.',
                style: TextStyle(color: c.textSecondary, height: 1.5, fontSize: 15),
              ),
            ),
          ),
          for (final o in const [(7, 'One week', '≈ 87 pages a day'), (15, 'Two weeks', '≈ 41 pages a day'), (30, 'One month (Ramadan pace)', '≈ 21 pages a day, a juz a day'), (60, 'Two months', '≈ 11 pages a day'), (90, 'Three months', '≈ 7 pages a day'), (180, 'Six months', '≈ 4 pages a day'), (365, 'One year', '≈ 2 pages a day')])
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Pressable(
                  onTap: () {
                    store.setPlan(DateTime.now(), o.$1);
                    showToast(context, 'Plan started: ${o.$2}');
                  },
                  radius: 18,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                        child: Text('${o.$1}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 19)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)), Text(o.$3, style: TextStyle(color: c.textSecondary, fontSize: 13.5))])),
                      Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                    ]),
                  ),
                ),
              ),
            ),
        ] else
          SliverToBoxAdapter(child: _Active(plan: plan, store: store)),
      ],
    );
  }
}

class _Active extends StatelessWidget {
  const _Active({required this.plan, required this.store});
  final KhatamPlan plan;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final read = store.planRead;
    final (from, to) = plan.todayRange();
    final todayDone = [for (var p = from; p <= to; p++) p].where(read.contains).length;
    final todayTotal = to - from + 1;
    final expected = plan.expectedByToday();
    final behind = (expected - read.length).clamp(0, 604);
    final ahead = (read.length - expected).clamp(0, 604);
    final first = Quran.I.pageWords(from).first;
    final complete = read.length >= 604;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(children: [
        ColorTile(
          seed: 2,
          height: 210,
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(complete ? 'KHATAM COMPLETE' : 'TODAY', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
              const SizedBox(height: 6),
              Text(complete ? 'MashaAllah' : (from == to ? 'Page $from' : 'Pages $from – $to'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
              Text(complete ? 'You finished the Qur’an on this plan.' : '${Quran.I.surah(first.surah).en} · $todayDone of $todayTotal pages read today', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.5)),
              const Spacer(),
              if (!complete)
                FilledButton.icon(
                  onPressed: () => openReader(context, surah: first.surah, ayah: first.ayah, page: _nextUnread(read, from, to), mushaf: true),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Read now'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13)),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${read.length} of 604 pages', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
              Text('${(read.length / 604 * 100).round()}%', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 17)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                Container(height: 12, color: c.bg),
                FractionallySizedBox(widthFactor: (read.length / 604).clamp(0, 1), child: Container(height: 12, color: c.accent)),
                FractionallySizedBox(widthFactor: (expected / 604).clamp(0, 1), alignment: Alignment.centerLeft, child: Align(alignment: Alignment.centerRight, child: Container(width: 3, height: 12, color: c.text.withValues(alpha: 0.5)))),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              behind > 0 ? 'You are $behind page${behind == 1 ? '' : 's'} behind. Read a little extra each day to catch up.' : (ahead > 0 ? 'You are $ahead page${ahead == 1 ? '' : 's'} ahead of the plan.' : 'You are right on track.'),
              style: TextStyle(color: behind > 0 ? Colors.orange : c.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text('Ends ${plan.endDate.day}/${plan.endDate.month}/${plan.endDate.year} · ${plan.endsInDays} day${plan.endsInDays == 1 ? '' : 's'} left · ${plan.perDay} pages a day',
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Stop this plan?'),
                  content: const Text('Your reading history stays; only the plan and its progress bar are removed.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep it')),
                    TextButton(
                      onPressed: () {
                        store.clearPlan();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Stop plan'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop plan'),
            ),
          ),
        ]),
      ]),
    );
  }

  int _nextUnread(Set<int> read, int from, int to) {
    for (var p = from; p <= to; p++) {
      if (!read.contains(p)) return p;
    }
    return from;
  }
}
