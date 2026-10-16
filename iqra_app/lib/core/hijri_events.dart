import 'package:hijri/hijri_calendar.dart';

import 'content.dart';

/// Days added to the calculated (Umm al-Qura) Hijri date, so that it can match the local moon sighting (-2 to +2).
int hijriShiftDays = 0;

HijriCalendar hijriOf(DateTime d) {
  HijriCalendar.setLocal('en');
  return HijriCalendar.fromDate(hijriShiftDays == 0 ? d : d.add(Duration(days: hijriShiftDays)));
}

class UpcomingEvent {
  UpcomingEvent(this.name, this.note, this.daysAway, this.date, [this.story]);
  final String name, note;
  final String? story;
  final int daysAway;
  final DateTime date;
}

/// Occasions of the Islamic calendar in the next [horizon] days, soonest first (today counts as 0).
List<UpcomingEvent> upcomingEvents({int horizon = 60, DateTime? from}) {
  final start = from ?? DateTime.now();
  final today = DateTime(start.year, start.month, start.day);
  final occ = Content.I.occasions;
  final out = <UpcomingEvent>[];
  for (var i = 0; i <= horizon; i++) {
    final d = today.add(Duration(days: i));
    final h = hijriOf(d);
    for (final o in occ) {
      if (o['m'] == h.hMonth && o['d'] == h.hDay) {
        out.add(UpcomingEvent(o['name'] as String, o['note'] as String, i, d, o['story'] as String?));
      }
    }
  }
  return out;
}

/// Days until the first of Ramadan (0 on the day), or null if it is more than a year away (never).
int daysUntilRamadan([DateTime? from]) {
  final start = from ?? DateTime.now();
  final today = DateTime(start.year, start.month, start.day);
  for (var i = 0; i < 400; i++) {
    final h = hijriOf(today.add(Duration(days: i)));
    if (h.hMonth == 9 && h.hDay == 1) return i;
  }
  return 999;
}

/// 1-based day of Ramadan if today is inside it, else null.
int? ramadanDay([DateTime? now]) {
  final h = hijriOf(now ?? DateTime.now());
  return h.hMonth == 9 ? h.hDay : null;
}
