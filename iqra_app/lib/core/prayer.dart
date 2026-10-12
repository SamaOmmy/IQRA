import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import 'store.dart';

/// Prayer times and qibla, computed offline with the standard astronomical method (sun position, twilight angles, Asr shadow
/// length), the same approach as the PrayTimes / Adhan libraries. Times are estimates: confirm against your local mosque.
class PrayerMethod {
  const PrayerMethod(this.id, this.name, this.fajr, {this.isha = 0, this.ishaMinutes = 0});
  final String id, name;
  final double fajr, isha;
  final int ishaMinutes;
}

const kPrayerMethods = <PrayerMethod>[
  PrayerMethod('mwl', 'Muslim World League', 18, isha: 17),
  PrayerMethod('isna', 'ISNA (North America)', 15, isha: 15),
  PrayerMethod('egypt', 'Egyptian General Authority', 19.5, isha: 17.5),
  PrayerMethod('makkah', 'Umm al-Qura (Makkah)', 18.5, ishaMinutes: 90),
  PrayerMethod('karachi', 'University of Islamic Sciences, Karachi', 18, isha: 18),
];

const kPrayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
const kPrayerNames = {
  'fajr': 'Fajr',
  'sunrise': 'Sunrise',
  'dhuhr': 'Dhuhr',
  'asr': 'Asr',
  'maghrib': 'Maghrib',
  'isha': 'Isha',
};
const kPrayerArabic = {
  'fajr': 'الفجر',
  'sunrise': 'الشروق',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

const _kaabaLat = 21.4225, _kaabaLon = 39.8262;

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;
double _fixAngle(double a) => ((a % 360) + 360) % 360;
double _fixHour(double h) => ((h % 24) + 24) % 24;
double _sin(double d) => math.sin(_rad(d));
double _cos(double d) => math.cos(_rad(d));
double _tan(double d) => math.tan(_rad(d));

double _julian(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5;
}

({double declination, double equation}) _sun(double jd) {
  final d = jd - 2451545.0;
  final g = _fixAngle(357.529 + 0.98560028 * d);
  final q = _fixAngle(280.459 + 0.98564736 * d);
  final l = _fixAngle(q + 1.915 * _sin(g) + 0.02 * _sin(2 * g));
  final e = 23.439 - 0.00000036 * d;
  final ra = _fixHour(_deg(math.atan2(_cos(e) * _sin(l), _cos(l))) / 15);
  return (declination: _deg(math.asin(_sin(e) * _sin(l))), equation: q / 15 - ra);
}

int tzOffsetMinutes(String zone, DateTime instant) {
  try {
    return tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone)).timeZoneOffset.inMinutes;
  } catch (_) {
    return instant.timeZoneOffset.inMinutes;
  }
}

({int y, int m, int d}) localDate(String zone, DateTime instant) {
  try {
    final t = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
    return (y: t.year, m: t.month, d: t.day);
  } catch (_) {
    final t = instant.toLocal();
    return (y: t.year, m: t.month, d: t.day);
  }
}

/// Prayer instants for the civil date at a place. High-latitude cases fall back to a share of the night.
Map<String, DateTime> prayerTimes(({int y, int m, int d}) date, Place place, {String method = 'mwl', bool hanafi = false}) {
  final m = kPrayerMethods.firstWhere((x) => x.id == method, orElse: () => kPrayerMethods.first);
  final lat = place.lat, lon = place.lon;
  final midnight = DateTime.utc(date.y, date.m, date.d).millisecondsSinceEpoch;
  final probe = DateTime.fromMillisecondsSinceEpoch(midnight + 12 * 3600000 - (lon * 240000).round(), isUtc: true);
  final offsetMin = tzOffsetMinutes(place.tz, probe);
  final jd = _julian(date.y, date.m, date.d) - lon / (15 * 24);

  double midDay(double t) => _fixHour(12 - _sun(jd + t).equation);
  double angleTime(double angle, double t, {bool ccw = false}) {
    final decl = _sun(jd + t).declination;
    final noon = midDay(t);
    final x = (-_sin(angle) - _sin(decl) * _sin(lat)) / (_cos(decl) * _cos(lat));
    if (x > 1 || x < -1) return double.nan;
    return noon + (ccw ? -1 : 1) * (_deg(math.acos(x)) / 15);
  }

  double asrTime(double factor, double t) {
    final decl = _sun(jd + t).declination;
    final angle = -_deg(math.atan(1 / (factor + _tan((lat - decl).abs()))));
    return angleTime(angle, t);
  }

  var fajr = 5.0, sunrise = 6.0, dhuhr = 12.0, asr = 13.0, sunset = 18.0, maghrib = 18.0, isha = 18.0;
  for (var pass = 0; pass < 2; pass++) {
    double at(double h) => h / 24;
    fajr = angleTime(m.fajr, at(fajr.isNaN ? 5 : fajr), ccw: true);
    sunrise = angleTime(0.833, at(sunrise.isNaN ? 6 : sunrise), ccw: true);
    dhuhr = midDay(at(dhuhr));
    asr = asrTime(hanafi ? 2 : 1, at(asr.isNaN ? 13 : asr));
    sunset = angleTime(0.833, at(sunset.isNaN ? 18 : sunset));
    maghrib = sunset;
    isha = m.ishaMinutes > 0 ? maghrib + m.ishaMinutes / 60 : angleTime(m.isha, at(18));
  }

  var night = _fixHour(sunrise - sunset);
  if (night.isNaN || night == 0) night = 24;
  double portion(double angle) => math.min(0.5, angle / 60);
  if (fajr.isNaN || sunrise - fajr > night * portion(m.fajr) + 0.01) fajr = sunrise - night * portion(m.fajr);
  if (m.ishaMinutes == 0 && (isha.isNaN || isha - sunset > night * portion(m.isha) + 0.01)) isha = sunset + night * portion(m.isha);

  final shift = offsetMin / 60 - lon / 15;
  DateTime toInstant(double t) {
    final h = t + shift;
    final hours = _fixHour(h) + (h >= 24 ? 24 : 0);
    return DateTime.fromMillisecondsSinceEpoch(midnight - offsetMin * 60000 + (hours * 60).round() * 60000, isUtc: true);
  }

  return {
    'fajr': toInstant(fajr),
    'sunrise': toInstant(sunrise),
    'dhuhr': toInstant(dhuhr),
    'asr': toInstant(asr),
    'maghrib': toInstant(maghrib),
    'isha': toInstant(isha),
  };
}

double qiblaBearing(double lat, double lon) {
  final dl = _rad(_kaabaLon - lon);
  final p1 = _rad(lat), p2 = _rad(_kaabaLat);
  return _fixAngle(_deg(math.atan2(math.sin(dl), math.cos(p1) * math.tan(p2) - math.sin(p1) * math.cos(dl))));
}

double distanceToKaabaKm(double lat, double lon) {
  final dl = _rad(_kaabaLon - lon), p1 = _rad(lat), p2 = _rad(_kaabaLat);
  final c = math.acos(math.min(1.0, math.sin(p1) * math.sin(p2) + math.cos(p1) * math.cos(p2) * math.cos(dl)));
  return c * 6371;
}

const _compass = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
String compassName(double b) => _compass[(b / 22.5).round() % 16];

class NextPrayer {
  NextPrayer(this.key, this.at, this.today);
  final String key;
  final DateTime at;
  final Map<String, DateTime> today;
}

NextPrayer nextPrayer(Place place, {String method = 'mwl', bool hanafi = false, DateTime? now}) {
  final n = (now ?? DateTime.now()).toUtc();
  final today = prayerTimes(localDate(place.tz, n), place, method: method, hanafi: hanafi);
  for (final k in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
    if (today[k]!.isAfter(n)) return NextPrayer(k, today[k]!, today);
  }
  final tomorrow = prayerTimes(localDate(place.tz, n.add(const Duration(days: 1))), place, method: method, hanafi: hanafi);
  return NextPrayer('fajr', tomorrow['fajr']!, today);
}

/// "5:12 AM" or "05:12" in the place's own clock.
String clockText(DateTime instant, Place place, {bool h24 = false}) {
  final off = tzOffsetMinutes(place.tz, instant);
  final t = instant.toUtc().add(Duration(minutes: off));
  final mm = t.minute.toString().padLeft(2, '0');
  if (h24) return '${t.hour.toString().padLeft(2, '0')}:$mm';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:$mm ${t.hour < 12 ? 'AM' : 'PM'}';
}
