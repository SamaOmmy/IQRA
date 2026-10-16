import 'dart:math' as math;

import 'store.dart';

/// A plan to finish the Qur'an in a number of days, 604 pages split evenly.
class KhatamPlan {
  KhatamPlan(this.start, this.days);
  final DateTime start;
  final int days;

  static KhatamPlan? from(AppStore s) {
    final p = s.plan;
    if (p == null) return null;
    final parts = (p['start'] as String).split('-');
    return KhatamPlan(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])), (p['days'] as num).toInt());
  }

  int get perDay => (604 / days).ceil();

  /// 0 on the first day.
  int dayIndex([DateTime? now]) {
    final n = now ?? DateTime.now();
    final a = DateTime.utc(start.year, start.month, start.day);
    final b = DateTime.utc(n.year, n.month, n.day);
    return b.difference(a).inDays;
  }

  bool get finishedWindow => dayIndex() >= days;

  int cumulative(int dayIdx) => math.min(604, ((dayIdx + 1) * 604 / days).ceil());

  /// The pages for today, as [from, to] (1-based, inclusive).
  (int, int) todayRange() {
    final i = dayIndex().clamp(0, days - 1);
    final to = cumulative(i);
    final from = i == 0 ? 1 : cumulative(i - 1) + 1;
    return (from, to);
  }

  int get endsInDays => math.max(0, days - dayIndex());

  DateTime get endDate => start.add(Duration(days: days - 1));

  /// Pages that should have been read by the end of today.
  int expectedByToday() => cumulative(dayIndex().clamp(0, days - 1));
}
