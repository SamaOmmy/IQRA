import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'adhan.dart';
import 'content.dart';
import 'prayer.dart';
import 'quran.dart';
import 'store.dart';

/// Prayer-time reminders.
///
/// Android: scheduled on the device for the next three days, so they arrive even when the app is closed.
/// Windows: toasts shown by the app while it is running (it can stay minimised).
class PrayerNotifier {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _exact = false;
  static const _native = MethodChannel('iqra/adhan');
  static final List<Timer> _timers = [];

  static Future<void> init() async {
    if (_ready || !Platform.isAndroid) return;
    try {
      await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _ready = true;
    } catch (e) {
      debugPrint('notifications unavailable: $e');
    }
  }

  /// Asks for notification permission (Android 13+). Returns true if reminders can be shown.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    await init();
    if (!_ready) return false;
    final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return (await a?.requestNotificationsPermission()) ?? true;
  }

  static void _clearTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Replaces all scheduled reminders with the upcoming prayers for the saved city.
  static Future<void> reschedule(AppStore s) async {
    _clearTimers();
    final place = s.place;
    if (Platform.isAndroid) {
      await init();
      if (!_ready) return;
      try {
        await _plugin.cancelAll();
      } catch (_) {}
    }
    final now = DateTime.now().toUtc();
    var id = 1;
    if (Platform.isAndroid) {
      // exact alarms make the adhan sound at the minute; without the permission Android may delay it by several minutes
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        _exact = (await a?.canScheduleExactNotifications()) ?? false;
      } catch (_) {
        _exact = false;
      }
    }
    final days = Platform.isAndroid ? 7 : 2;

    Future<void> schedule(int id, DateTime at, String title, String body, String channel, {bool adhan = false}) async {
      if (Platform.isAndroid) {
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(at, tz.UTC),
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                adhan ? 'prayer_adhan' : channel,
                adhan ? 'Adhan' : (channel == 'prayer_times' ? 'Prayer times' : 'Verse of the day'),
                channelDescription: adhan ? 'The call to prayer when a prayer time begins' : (channel == 'prayer_times' ? 'A reminder when a prayer time begins' : 'One verse each day'),
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                sound: adhan ? const RawResourceAndroidNotificationSound('adhan') : null,
                audioAttributesUsage: adhan ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
                category: AndroidNotificationCategory.alarm,
              ),
            ),
            androidScheduleMode: _exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('could not schedule $title: $e');
        }
      } else if (Platform.isWindows) {
        _timers.add(Timer(at.difference(DateTime.now().toUtc()), () async {
          await _windowsToast(title, body);
          if (adhan) AdhanPlayer.play(sound: s.adhanSound);
          reschedule(s);
        }));
      }
    }

    final native = <Map<String, Object>>[];
    if (Platform.isAndroid) await setSound(s.adhanSound);
    if (s.notifyPrayers && place != null) {
      for (var d = 0; d < days; d++) {
        final date = localDate(place.tz, now.add(Duration(days: d)));
        final times = s.prayersOn(date);
        for (final k in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
          if (!s.alertPrayers.contains(k)) continue;
          final at = times[k]!;
          if (!at.isAfter(now)) continue;
          final title = '${kPrayerNames[k]} · ${kPrayerArabic[k]}', body = 'It is time for ${kPrayerNames[k]} in ${place.name}';
          if (Platform.isAndroid) {
            // alarm-clock alarms handled by the app itself, so the adhan rings like an alarm even when the app is closed
            native.add({'id': id++, 'at': at.millisecondsSinceEpoch, 'title': title, 'body': body, 'adhan': s.adhan});
          } else {
            await schedule(id++, at, title, body, 'prayer_times', adhan: s.adhan);
          }
        }
      }
    }

    if (Platform.isAndroid) {
      try {
        if (native.isEmpty) {
          await _native.invokeMethod('cancel');
        } else {
          await _native.invokeMethod('schedule', {'items': jsonEncode(native)});
        }
      } catch (e) {
        debugPrint('could not schedule the adhan: $e');
      }
    }

    // one verse a day at the chosen time
    if (s.dailyVerseAt >= 0) {
      final local = DateTime.now();
      for (var d = 0; d < days + 1; d++) {
        final day = DateTime(local.year, local.month, local.day).add(Duration(days: d));
        final at = DateTime(day.year, day.month, day.day, s.dailyVerseAt ~/ 60, s.dailyVerseAt % 60);
        if (!at.isAfter(DateTime.now())) continue;
        final refs = Content.I.dailyVerses;
        final ref = refs[(DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 86400000) % refs.length];
        final surah = ref[0] as int, ayah = ref[1] as int;
        final a = Quran.I.ayah(surah, ayah);
        var text = a.t;
        if (text.length > 170) text = '${text.substring(0, 168)}…';
        await schedule(100 + d, at.toUtc(), 'Verse of the day · ${Quran.I.surah(surah).en} $surah:$ayah', text, 'daily_verse');
      }
    }
  }

  /// Tells the Android alarm service which recording to play.
  static Future<void> setSound(int n) async {
    if (!Platform.isAndroid) return;
    try {
      await _native.invokeMethod('setSound', {'n': n});
    } catch (_) {}
  }

  static Future<void> test({bool adhan = false, int sound = 2}) async {
    if (Platform.isWindows) {
      await _windowsToast('IQRA', 'Prayer reminders are working.');
      if (adhan) AdhanPlayer.play(sound: sound);
      return;
    }
    if (Platform.isAndroid) {
      await requestPermission();
      try {
        await setSound(sound);
        await _native.invokeMethod('test', {'title': 'IQRA', 'body': 'Prayer reminders are working.', 'adhan': adhan});
        return;
      } catch (_) {}
    }
    await init();
    if (!_ready) return;
    await _plugin.show(
      id: 999,
      title: 'IQRA',
      body: 'Prayer reminders are working.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          adhan ? 'prayer_adhan' : 'prayer_times',
          adhan ? 'Adhan' : 'Prayer times',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: adhan ? const RawResourceAndroidNotificationSound('adhan') : null,
        ),
      ),
    );
  }

  static String _xml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');

  static Future<void> _windowsToast(String title, String body) async {
    final script = '''
\$ErrorActionPreference = 'SilentlyContinue'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml('<toast><visual><binding template="ToastText02"><text id="1">${_xml(title)}</text><text id="2">${_xml(body)}</text></binding></visual><audio src="ms-winsoundevent:Notification.Reminder"/></toast>')
\$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\WindowsPowerShell\\v1.0\\powershell.exe').Show(\$toast)
''';
    // UTF-16LE base64 keeps Arabic letters intact on the command line
    final units = script.codeUnits;
    final bytes = <int>[for (final u in units) ...[u & 0xff, u >> 8]];
    try {
      await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-EncodedCommand', base64.encode(bytes)]);
    } catch (e) {
      debugPrint('toast failed: $e');
    }
  }
}
