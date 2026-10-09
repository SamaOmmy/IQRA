'use strict';
// Prayer times and qibla, computed offline with the standard astronomical method (sun position, twilight angles, Asr shadow
// length), the same approach as the PrayTimes / Adhan libraries. Times are estimates: confirm against your local mosque.

const KAABA = { lat: 21.4225, lon: 39.8262 };

const PRAYER_METHODS = {
  mwl: { name: 'Muslim World League', fajr: 18, isha: 17 },
  isna: { name: 'ISNA (North America)', fajr: 15, isha: 15 },
  egypt: { name: 'Egyptian General Authority', fajr: 19.5, isha: 17.5 },
  makkah: { name: 'Umm al-Qura (Makkah)', fajr: 18.5, ishaMinutes: 90 },
  karachi: { name: 'University of Islamic Sciences, Karachi', fajr: 18, isha: 18 },
};

// [name, country, latitude, longitude, IANA time zone]
const CITIES = [
  ['Makkah', 'Saudi Arabia', 21.4225, 39.8262, 'Asia/Riyadh'], ['Madinah', 'Saudi Arabia', 24.4709, 39.6122, 'Asia/Riyadh'],
  ['Riyadh', 'Saudi Arabia', 24.7136, 46.6753, 'Asia/Riyadh'], ['Jeddah', 'Saudi Arabia', 21.5433, 39.1728, 'Asia/Riyadh'],
  ['Dammam', 'Saudi Arabia', 26.4207, 50.0888, 'Asia/Riyadh'], ['Jerusalem', 'Palestine', 31.7683, 35.2137, 'Asia/Jerusalem'],
  ['Gaza', 'Palestine', 31.5, 34.4667, 'Asia/Gaza'], ['Amman', 'Jordan', 31.9454, 35.9284, 'Asia/Amman'],
  ['Beirut', 'Lebanon', 33.8938, 35.5018, 'Asia/Beirut'], ['Damascus', 'Syria', 33.5138, 36.2765, 'Asia/Damascus'],
  ['Baghdad', 'Iraq', 33.3152, 44.3661, 'Asia/Baghdad'], ['Kuwait City', 'Kuwait', 29.3759, 47.9774, 'Asia/Kuwait'],
  ['Doha', 'Qatar', 25.2854, 51.531, 'Asia/Qatar'], ['Manama', 'Bahrain', 26.2285, 50.586, 'Asia/Bahrain'],
  ['Dubai', 'UAE', 25.2048, 55.2708, 'Asia/Dubai'], ['Abu Dhabi', 'UAE', 24.4539, 54.3773, 'Asia/Dubai'],
  ['Muscat', 'Oman', 23.588, 58.3829, 'Asia/Muscat'], ['Sanaa', 'Yemen', 15.3694, 44.191, 'Asia/Aden'],
  ['Cairo', 'Egypt', 30.0444, 31.2357, 'Africa/Cairo'], ['Alexandria', 'Egypt', 31.2001, 29.9187, 'Africa/Cairo'],
  ['Khartoum', 'Sudan', 15.5007, 32.5599, 'Africa/Khartoum'], ['Tripoli', 'Libya', 32.8872, 13.1913, 'Africa/Tripoli'],
  ['Tunis', 'Tunisia', 36.8065, 10.1815, 'Africa/Tunis'], ['Algiers', 'Algeria', 36.7538, 3.0588, 'Africa/Algiers'],
  ['Casablanca', 'Morocco', 33.5731, -7.5898, 'Africa/Casablanca'], ['Rabat', 'Morocco', 34.0209, -6.8416, 'Africa/Casablanca'],
  ['Nouakchott', 'Mauritania', 18.0735, -15.9582, 'Africa/Nouakchott'], ['Dakar', 'Senegal', 14.7167, -17.4677, 'Africa/Dakar'],
  ['Lagos', 'Nigeria', 6.5244, 3.3792, 'Africa/Lagos'], ['Abuja', 'Nigeria', 9.0765, 7.3986, 'Africa/Lagos'],
  ['Kano', 'Nigeria', 12.0022, 8.592, 'Africa/Lagos'], ['Accra', 'Ghana', 5.6037, -0.187, 'Africa/Accra'],
  ['Addis Ababa', 'Ethiopia', 9.03, 38.74, 'Africa/Addis_Ababa'], ['Mogadishu', 'Somalia', 2.0469, 45.3182, 'Africa/Mogadishu'],
  ['Nairobi', 'Kenya', -1.2921, 36.8219, 'Africa/Nairobi'], ['Dar es Salaam', 'Tanzania', -6.7924, 39.2083, 'Africa/Dar_es_Salaam'],
  ['Johannesburg', 'South Africa', -26.2041, 28.0473, 'Africa/Johannesburg'], ['Cape Town', 'South Africa', -33.9249, 18.4241, 'Africa/Johannesburg'],
  ['Istanbul', 'Turkey', 41.0082, 28.9784, 'Europe/Istanbul'], ['Ankara', 'Turkey', 39.9334, 32.8597, 'Europe/Istanbul'],
  ['Tehran', 'Iran', 35.6892, 51.389, 'Asia/Tehran'], ['Mashhad', 'Iran', 36.2605, 59.6168, 'Asia/Tehran'],
  ['Kabul', 'Afghanistan', 34.5553, 69.2075, 'Asia/Kabul'], ['Islamabad', 'Pakistan', 33.6844, 73.0479, 'Asia/Karachi'],
  ['Karachi', 'Pakistan', 24.8607, 67.0011, 'Asia/Karachi'], ['Lahore', 'Pakistan', 31.5204, 74.3587, 'Asia/Karachi'],
  ['Delhi', 'India', 28.6139, 77.209, 'Asia/Kolkata'], ['Mumbai', 'India', 19.076, 72.8777, 'Asia/Kolkata'],
  ['Hyderabad', 'India', 17.385, 78.4867, 'Asia/Kolkata'], ['Dhaka', 'Bangladesh', 23.8103, 90.4125, 'Asia/Dhaka'],
  ['Colombo', 'Sri Lanka', 6.9271, 79.8612, 'Asia/Colombo'], ['Male', 'Maldives', 4.1755, 73.5093, 'Indian/Maldives'],
  ['Tashkent', 'Uzbekistan', 41.2995, 69.2401, 'Asia/Tashkent'], ['Baku', 'Azerbaijan', 40.4093, 49.8671, 'Asia/Baku'],
  ['Almaty', 'Kazakhstan', 43.2389, 76.8897, 'Asia/Almaty'], ['Kuala Lumpur', 'Malaysia', 3.139, 101.6869, 'Asia/Kuala_Lumpur'],
  ['Singapore', 'Singapore', 1.3521, 103.8198, 'Asia/Singapore'], ['Jakarta', 'Indonesia', -6.2088, 106.8456, 'Asia/Jakarta'],
  ['Surabaya', 'Indonesia', -7.2575, 112.7521, 'Asia/Jakarta'], ['Manila', 'Philippines', 14.5995, 120.9842, 'Asia/Manila'],
  ['Bandar Seri Begawan', 'Brunei', 4.9031, 114.9398, 'Asia/Brunei'], ['Bangkok', 'Thailand', 13.7563, 100.5018, 'Asia/Bangkok'],
  ['Beijing', 'China', 39.9042, 116.4074, 'Asia/Shanghai'], ['Urumqi', 'China', 43.8256, 87.6168, 'Asia/Urumqi'],
  ['Tokyo', 'Japan', 35.6762, 139.6503, 'Asia/Tokyo'], ['Seoul', 'South Korea', 37.5665, 126.978, 'Asia/Seoul'],
  ['Sydney', 'Australia', -33.8688, 151.2093, 'Australia/Sydney'], ['Melbourne', 'Australia', -37.8136, 144.9631, 'Australia/Melbourne'],
  ['Perth', 'Australia', -31.9505, 115.8605, 'Australia/Perth'], ['Auckland', 'New Zealand', -36.8485, 174.7633, 'Pacific/Auckland'],
  ['London', 'United Kingdom', 51.5074, -0.1278, 'Europe/London'], ['Birmingham', 'United Kingdom', 52.4862, -1.8904, 'Europe/London'],
  ['Manchester', 'United Kingdom', 53.4808, -2.2426, 'Europe/London'], ['Dublin', 'Ireland', 53.3498, -6.2603, 'Europe/Dublin'],
  ['Paris', 'France', 48.8566, 2.3522, 'Europe/Paris'], ['Marseille', 'France', 43.2965, 5.3698, 'Europe/Paris'],
  ['Brussels', 'Belgium', 50.8503, 4.3517, 'Europe/Brussels'], ['Amsterdam', 'Netherlands', 52.3676, 4.9041, 'Europe/Amsterdam'],
  ['Berlin', 'Germany', 52.52, 13.405, 'Europe/Berlin'], ['Frankfurt', 'Germany', 50.1109, 8.6821, 'Europe/Berlin'],
  ['Vienna', 'Austria', 48.2082, 16.3738, 'Europe/Vienna'], ['Zurich', 'Switzerland', 47.3769, 8.5417, 'Europe/Zurich'],
  ['Rome', 'Italy', 41.9028, 12.4964, 'Europe/Rome'], ['Madrid', 'Spain', 40.4168, -3.7038, 'Europe/Madrid'],
  ['Barcelona', 'Spain', 41.3874, 2.1686, 'Europe/Madrid'], ['Lisbon', 'Portugal', 38.7223, -9.1393, 'Europe/Lisbon'],
  ['Stockholm', 'Sweden', 59.3293, 18.0686, 'Europe/Stockholm'], ['Oslo', 'Norway', 59.9139, 10.7522, 'Europe/Oslo'],
  ['Copenhagen', 'Denmark', 55.6761, 12.5683, 'Europe/Copenhagen'], ['Helsinki', 'Finland', 60.1699, 24.9384, 'Europe/Helsinki'],
  ['Warsaw', 'Poland', 52.2297, 21.0122, 'Europe/Warsaw'], ['Sarajevo', 'Bosnia', 43.8563, 18.4131, 'Europe/Sarajevo'],
  ['Tirana', 'Albania', 41.3275, 19.8187, 'Europe/Tirane'], ['Athens', 'Greece', 37.9838, 23.7275, 'Europe/Athens'],
  ['Moscow', 'Russia', 55.7558, 37.6173, 'Europe/Moscow'], ['Kazan', 'Russia', 55.7887, 49.1221, 'Europe/Moscow'],
  ['New York', 'USA', 40.7128, -74.006, 'America/New_York'], ['Washington DC', 'USA', 38.9072, -77.0369, 'America/New_York'],
  ['Chicago', 'USA', 41.8781, -87.6298, 'America/Chicago'], ['Houston', 'USA', 29.7604, -95.3698, 'America/Chicago'],
  ['Dallas', 'USA', 32.7767, -96.797, 'America/Chicago'], ['Denver', 'USA', 39.7392, -104.9903, 'America/Denver'],
  ['Los Angeles', 'USA', 34.0522, -118.2437, 'America/Los_Angeles'], ['San Francisco', 'USA', 37.7749, -122.4194, 'America/Los_Angeles'],
  ['Seattle', 'USA', 47.6062, -122.3321, 'America/Los_Angeles'], ['Detroit', 'USA', 42.3314, -83.0458, 'America/Detroit'],
  ['Atlanta', 'USA', 33.749, -84.388, 'America/New_York'], ['Miami', 'USA', 25.7617, -80.1918, 'America/New_York'],
  ['Toronto', 'Canada', 43.6532, -79.3832, 'America/Toronto'], ['Montreal', 'Canada', 45.5017, -73.5673, 'America/Toronto'],
  ['Vancouver', 'Canada', 49.2827, -123.1207, 'America/Vancouver'], ['Mexico City', 'Mexico', 19.4326, -99.1332, 'America/Mexico_City'],
  ['Sao Paulo', 'Brazil', -23.5505, -46.6333, 'America/Sao_Paulo'], ['Buenos Aires', 'Argentina', -34.6037, -58.3816, 'America/Argentina/Buenos_Aires'],
  ['Bogota', 'Colombia', 4.711, -74.0721, 'America/Bogota'],
];

// ---------- Astronomy ----------
const rad = (d) => (d * Math.PI) / 180;
const deg = (r) => (r * 180) / Math.PI;
const fixAngle = (a) => ((a % 360) + 360) % 360;
const fixHour = (h) => ((h % 24) + 24) % 24;
const sinD = (d) => Math.sin(rad(d));
const cosD = (d) => Math.cos(rad(d));
const tanD = (d) => Math.tan(rad(d));

function julian(y, m, d) {
  if (m <= 2) { y -= 1; m += 12; }
  const A = Math.floor(y / 100);
  const B = 2 - A + Math.floor(A / 4);
  return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + d + B - 1524.5;
}

function sunPosition(jd) {
  const D = jd - 2451545.0;
  const g = fixAngle(357.529 + 0.98560028 * D);
  const q = fixAngle(280.459 + 0.98564736 * D);
  const L = fixAngle(q + 1.915 * sinD(g) + 0.02 * sinD(2 * g));
  const e = 23.439 - 0.00000036 * D;
  const RA = fixHour(deg(Math.atan2(cosD(e) * sinD(L), cosD(L))) / 15);
  return { declination: deg(Math.asin(sinD(e) * sinD(L))), equation: q / 15 - RA };
}

// Local tz offset in minutes at an instant, from the zone's own rules (handles daylight saving).
function tzOffsetMinutes(tz, instant) {
  const parts = {};
  for (const p of new Intl.DateTimeFormat('en-US', { timeZone: tz, hour12: false, year: 'numeric', month: 'numeric', day: 'numeric', hour: 'numeric', minute: 'numeric', second: 'numeric' }).formatToParts(instant)) parts[p.type] = +p.value;
  const asUtc = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour % 24, parts.minute, parts.second);
  return Math.round((asUtc - Math.floor(instant.getTime() / 1000) * 1000) / 60000);
}

function localDate(tz, instant = new Date()) {
  const p = {};
  for (const x of new Intl.DateTimeFormat('en-US', { timeZone: tz, year: 'numeric', month: 'numeric', day: 'numeric' }).formatToParts(instant)) p[x.type] = +x.value;
  return { y: p.year, m: p.month, d: p.day };
}

// Returns { fajr, sunrise, dhuhr, asr, maghrib, isha } as Date instants for the civil date {y, m, d} at the place.
function prayerTimes(date, place, opts = {}) {
  const method = PRAYER_METHODS[opts.method] || PRAYER_METHODS.mwl;
  const { lat, lon, tz } = place;
  const midnight = Date.UTC(date.y, date.m - 1, date.d);
  const offsetMin = tzOffsetMinutes(tz, new Date(midnight + 12 * 3600e3 - lon * 240e3));
  const jd = julian(date.y, date.m, date.d) - lon / (15 * 24);
  const pos = (t) => sunPosition(jd + t);
  const midDay = (t) => fixHour(12 - pos(t).equation);
  const angleTime = (angle, t, ccw) => {
    const decl = pos(t).declination;
    const noon = midDay(t);
    const x = (-sinD(angle) - sinD(decl) * sinD(lat)) / (cosD(decl) * cosD(lat));
    if (x > 1 || x < -1) return NaN; // the sun never reaches this angle (high latitudes)
    return noon + (ccw ? -1 : 1) * (deg(Math.acos(x)) / 15);
  };
  const asrTime = (factor, t) => {
    const decl = pos(t).declination;
    const angle = -deg(Math.atan(1 / (factor + tanD(Math.abs(lat - decl)))));
    return angleTime(angle, t);
  };

  let t = { fajr: 5, sunrise: 6, dhuhr: 12, asr: 13, sunset: 18, maghrib: 18, isha: 18 };
  for (let pass = 0; pass < 2; pass++) { // second pass refines each time using the first estimate
    const at = (h) => h / 24;
    t = {
      fajr: angleTime(method.fajr, at(t.fajr || 5), true),
      sunrise: angleTime(0.833, at(t.sunrise || 6), true),
      dhuhr: midDay(at(t.dhuhr)),
      asr: asrTime(opts.hanafi ? 2 : 1, at(t.asr || 13)),
      sunset: angleTime(0.833, at(t.sunset || 18)),
      maghrib: NaN,
      isha: NaN,
    };
    t.maghrib = t.sunset;
    t.isha = method.ishaMinutes ? t.maghrib + method.ishaMinutes / 60 : angleTime(method.isha, at(18));
  }

  // High latitudes: when twilight never ends, fall back to a share of the night (angle / 60).
  const night = fixHour(t.sunrise - t.sunset) || 24;
  const portion = (angle) => Math.min(0.5, angle / 60);
  if (Number.isNaN(t.fajr) || t.sunrise - t.fajr > night * portion(method.fajr) + 0.01) t.fajr = t.sunrise - night * portion(method.fajr);
  if (!method.ishaMinutes && (Number.isNaN(t.isha) || t.isha - t.sunset > night * portion(method.isha) + 0.01)) t.isha = t.sunset + night * portion(method.isha);

  const shift = offsetMin / 60 - lon / 15; // from local solar time to the zone's clock
  const out = {};
  for (const k of ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
    const hours = fixHour(t[k] + shift) + (t[k] + shift >= 24 ? 24 : 0);
    out[k] = new Date(midnight - offsetMin * 60e3 + Math.round(hours * 60) * 60e3);
  }
  return out;
}

function qiblaBearing(lat, lon) {
  const dl = rad(KAABA.lon - lon);
  const p1 = rad(lat), p2 = rad(KAABA.lat);
  return fixAngle(deg(Math.atan2(Math.sin(dl), Math.cos(p1) * Math.tan(p2) - Math.sin(p1) * Math.cos(dl))));
}

function distanceToKaabaKm(lat, lon) {
  const dl = rad(KAABA.lon - lon), p1 = rad(lat), p2 = rad(KAABA.lat);
  const c = Math.acos(Math.min(1, Math.sin(p1) * Math.sin(p2) + Math.cos(p1) * Math.cos(p2) * Math.cos(dl)));
  return c * 6371;
}

const COMPASS = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
const compassName = (b) => COMPASS[Math.round(b / 22.5) % 16];

// The next prayer after `now` at a place: { key, at, today } (rolls over to tomorrow's Fajr after Isha).
function nextPrayer(place, opts, now = new Date()) {
  const order = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  const today = localDate(place.tz, now);
  const t = prayerTimes(today, place, opts);
  for (const key of order) if (t[key] > now) return { key, at: t[key], today: t };
  const tomorrow = localDate(place.tz, new Date(now.getTime() + 86400e3));
  const tt = prayerTimes(tomorrow, place, opts);
  return { key: 'fajr', at: tt.fajr, today: t };
}
