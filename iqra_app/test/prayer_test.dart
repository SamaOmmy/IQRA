import 'package:flutter_test/flutter_test.dart';
import 'package:iqra/core/cities.dart';
import 'package:iqra/core/prayer.dart';
import 'package:iqra/core/store.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('every city has a known time zone', () {
    final missing = [for (final c in kCities) if (!_known(c.tz)) '${c.name} (${c.tz})'];
    expect(missing, isEmpty);
  });

  test('every city gives a sane order of prayers on three dates', () {
    final bad = <String>[];
    for (final p in kCities) {
      for (final d in [(y: 2026, m: 1, d: 15), (y: 2026, m: 6, d: 21), (y: 2026, m: 12, d: 21)]) {
        final t = prayerTimes(d, p, method: methodForCountry(p.country));
        final order = [for (final k in kPrayerKeys) t[k]!.millisecondsSinceEpoch];
        for (var i = 1; i < order.length; i++) {
          if (order[i] <= order[i - 1]) bad.add('${p.name} ${d.m}/${d.d} ${kPrayerKeys[i]}');
        }
        // Dhuhr is near local solar noon: the equation of time moves it by at most about 16 minutes
        final off = tzOffsetMinutes(p.tz, t['dhuhr']!);
        final localNoon = 720 - (p.lon / 15 * 60 - off).round();
        final l = t['dhuhr']!.add(Duration(minutes: off));
        var minutes = l.hour * 60 + l.minute;
        if ((minutes - localNoon).abs() > 720) minutes += minutes < localNoon ? 1440 : -1440;
        if ((minutes - localNoon).abs() > 40) bad.add('${p.name} ${d.m}/${d.d} dhuhr off by ${minutes - localNoon} min');
      }
    }
    expect(bad, isEmpty);
  });

  test('Dar es Salaam on 16 October 2026 (Muslim World League)', () {
    final p = kCities.firstWhere((c) => c.name == 'Dar es Salaam');
    final t = prayerTimes((y: 2026, m: 10, d: 16), p);
    String at(String k) => clockText(t[k]!, p, h24: true);
    expect(at('fajr'), '04:51');
    expect(at('dhuhr'), '12:09');
    expect(at('maghrib'), '18:16');
    expect(at('isha'), '19:23');
  });

  test('minute adjustments move a prayer and nothing else', () {
    final p = kCities.firstWhere((c) => c.name == 'Makkah');
    final base = prayerTimes((y: 2026, m: 3, d: 1), p);
    final moved = prayerTimes((y: 2026, m: 3, d: 1), p, adjust: {'dhuhr': 3});
    expect(moved['dhuhr']!.difference(base['dhuhr']!).inMinutes, 3);
    expect(moved['asr'], base['asr']);
  });

  test('hand-entered zones such as UTC+3 are understood', () {
    const p = Place('Test', '', -6.79, 39.21, 'UTC+3');
    final t = prayerTimes((y: 2026, m: 10, d: 16), p);
    expect(clockText(t['dhuhr']!, p, h24: true), '12:09');
  });

  test('qibla from Dar es Salaam is almost due north', () {
    final b = qiblaBearing(-6.79, 39.21);
    expect(b, inInclusiveRange(0, 3));
  });
}

bool _known(String zone) {
  try {
    tz.getLocation(zone);
    return true;
  } catch (_) {
    return false;
  }
}
