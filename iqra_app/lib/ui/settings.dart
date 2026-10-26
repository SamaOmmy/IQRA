import 'dart:io' show File, Platform;

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/phone.dart';
import '../core/media_session.dart';
import '../core/adhan.dart';
import '../core/audio.dart';
import '../core/notify.dart';
import '../core/prayer.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/updates.dart';
import 'downloads_screen.dart';
import 'page_scaffold.dart';
import 'plan_screen.dart';
import 'theme_wave.dart';
import 'tools/prayer_screen.dart';
import 'widgets.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppStore>();
    final up = context.watch<UpdateChecker>();
    Widget group(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(6, 0, 0, 8), child: Text(title.toUpperCase(), style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
            Container(decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 4), child: Material(type: MaterialType.transparency, child: Column(children: children))),
          ]),
        );
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return LargePage(
      title: 'Settings',
      maxWidth: 760,
      slivers: [
        SliverToBoxAdapter(
          child: group('Theme', [
            Builder(builder: (context) {
              final dark = resolveTheme(s.theme, MediaQuery.platformBrightnessOf(context)).colors.dark;
              return ListTile(
                title: const Text('Dark mode'),
                subtitle: Text(dark ? 'On. Tap to go back to a light look.' : 'Off. Tap for a dark look that is easier on the eyes at night.'),
                trailing: const ThemeToggleButton(),
                onTap: () => ThemeWave.run(context, () => s.toggleDark(MediaQuery.platformBrightnessOf(context))),
              );
            }),
            const Divider1(indent: 16),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(spacing: 12, runSpacing: 12, children: [
                _ThemeChip(id: 'auto', name: 'Auto', colors: resolveTheme('auto', MediaQuery.platformBrightnessOf(context)).colors, selected: s.theme == 'auto', onTap: () => s.theme = 'auto'),
                for (final t in kThemes) _ThemeChip(id: t.id, name: t.name, colors: t.colors, selected: s.theme == t.id, onTap: () => s.theme = t.id),
              ]),
            ),
            const Divider1(indent: 16),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Accent colour', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final a in kAccents)
                    GestureDetector(
                      onTap: () => s.accent = a.$2?.toARGB32() ?? 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: a.$2 ?? c.surfaceAlt,
                          border: Border.all(color: (s.accent == (a.$2?.toARGB32() ?? 0)) ? c.text : Colors.transparent, width: 2.5),
                        ),
                        child: a.$2 == null ? Icon(Icons.auto_awesome_rounded, size: 14, color: c.textSecondary) : null,
                      ),
                    ),
                ]),
              ]),
            ),
            SwitchListTile(title: const Text('Quick access button'), subtitle: const Text('A small floating button on every screen of the phone: light/dark, search, home and settings. Drag it where you like.'), value: s.uiInt('qa', 1) == 1, onChanged: (v) => s.setUiInt('qa', v ? 1 : 0)),
            SwitchListTile(title: const Text('Gentle animations'), subtitle: const Text('Cards glide in, pages turn smoothly'), value: s.motion, onChanged: (v) => s.motion = v),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Visual effects', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Text('Automatic keeps everything smooth by itself and drops the fancy reveals on a device that struggles. Light is the smoothest on older hardware. Full adds the frosted-glass blur on a computer with a good graphics chip.', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Segmented(items: const ['Automatic', 'Full', 'Light'], index: s.effects.clamp(0, 2), onChanged: (i) => s.effects = i),
              ]),
            ),
          ]),
        ),
        SliverToBoxAdapter(
          child: group('Reading', [
            ListTile(
              title: const Text('Translation'),
              subtitle: Text(Quran.I.translations.firstWhere((t) => t.id == s.translationId, orElse: () => Quran.I.translations.first).name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickTranslation(context),
            ),
            SwitchListTile(title: const Text('Show translation under verses'), value: s.showTranslation, onChanged: (v) => s.showTranslation = v),
            ListTile(title: const Text('Arabic text size'), subtitle: Slider(min: 22, max: 48, value: s.arabicSize.clamp(22, 48), onChanged: (v) => s.arabicSize = v)),
            ListTile(title: const Text('Translation text size'), subtitle: Slider(min: 13, max: 26, value: s.translationSize.clamp(13, 26), onChanged: (v) => s.translationSize = v)),
            SwitchListTile(title: const Text('Open the mushaf page view'), subtitle: const Text('Otherwise opens verse by verse'), value: s.mushafView, onChanged: (v) => s.mushafView = v),
            ListTile(title: const Text('Khatam plan'), subtitle: Text(s.plan == null ? 'Finish the Qur’an in a time you choose' : 'A plan is in progress'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => push(const PlanScreen())),
          ]),
        ),
        SliverToBoxAdapter(
          child: group('Audio', [
            ListTile(
              title: const Text('Reciter'),
              subtitle: Text(reciterName(s.reciter)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickReciter(context),
            ),
            SwitchListTile(title: const Text('Continue to the next surah'), value: s.continuous, onChanged: (v) => s.continuous = v),
            SwitchListTile(title: const Text('Play surahs as one connected recording'), subtitle: const Text('No pauses between verses, as the reciter delivered it. Needs an internet connection; reciters without a full recording, and repeating a verse, use the verse files.'), value: s.wholeSurah, onChanged: (v) => s.wholeSurah = v),
            if (Platform.isAndroid) const _PhoneControlsTile(),
            ListTile(title: const Text('Downloads'), subtitle: const Text('Recitations and tafsir for offline use'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => push(const DownloadsScreen())),
          ]),
        ),
        SliverToBoxAdapter(
          child: group('Prayer', [
            ListTile(
              title: const Text('City and calculation'),
              subtitle: Text(s.place == null ? 'Not set' : '${s.place!.name}${s.place!.country.isEmpty ? '' : ', ${s.place!.country}'}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => push(const PrayerScreen()),
            ),
            SwitchListTile(
              title: const Text('Prayer time reminders'),
              subtitle: Text(s.place == null ? 'Choose a city first' : 'A notification when each prayer begins'),
              value: s.notifyPrayers && s.place != null,
              onChanged: s.place == null
                  ? null
                  : (v) async {
                      if (v) {
                        final ok = await PrayerNotifier.requestPermission();
                        if (!ok && context.mounted) showToast(context, 'Notifications are turned off for IQRA in system settings');
                      }
                      s.notifyPrayers = v;
                    },
            ),
            SwitchListTile(
              title: const Text('Play the adhan'),
              subtitle: const Text('The call to prayer sounds with each reminder'),
              value: s.adhan,
              onChanged: (v) => s.adhan = v,
            ),
            if (s.notifyPrayers && s.place != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Remind me for', style: TextStyle(color: context.c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (final k in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
                      FilterChip(
                        label: Text(kPrayerNames[k]!),
                        selected: s.alertPrayers.contains(k),
                        showCheckmark: false,
                        selectedColor: context.c.accent.withValues(alpha: 0.2),
                        onSelected: (v) => s.setAlert(k, v),
                      ),
                  ]),
                ]),
              ),
            if (s.adhan)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Adhan sound', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < AdhanPlayer.names.length; i++)
                      ChoiceChip(
                        label: Text(AdhanPlayer.names[i]),
                        selected: s.adhanSound == i + 1,
                        showCheckmark: false,
                        selectedColor: context.c.accent.withValues(alpha: 0.2),
                        onSelected: (_) {
                          s.adhanSound = i + 1;
                          PrayerNotifier.setSound(i + 1);
                          AdhanPlayer.play(sound: i + 1);
                        },
                      ),
                    ChoiceChip(
                      avatar: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(s.adhanSound == 0 && s.adhanFile != null ? 'My own' : 'Choose my own…'),
                      selected: s.adhanSound == 0,
                      showCheckmark: false,
                      selectedColor: context.c.accent.withValues(alpha: 0.2),
                      onSelected: (_) => _pickOwnAdhan(context, s),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Text(
                        const [
                          'Madinah: the call to prayer from the Prophet\'s Mosque, by ejaz215 (CC BY 3.0)',
                          'Casablanca: the Hassan II Mosque, by Fraguando (CC BY-SA 4.0)',
                          'Ramadan: a mosque call during Ramadan, by daSupremo (CC BY-SA 4.0)',
                          'Calm: "Beautiful adhan" by Adam-synagda (CC0)',
                          'Classic: recorded by Aaqib Azeez (CC BY-SA 4.0)',
                        ][(s.adhanSound - 1).clamp(0, 4)],
                        style: TextStyle(color: context.c.textSecondary, fontSize: 12.5),
                      ),
                    ),
                    IconButton(onPressed: () => AdhanPlayer.play(sound: s.adhanSound, file: s.adhanFile), tooltip: 'Listen', icon: const Icon(Icons.play_circle_outline_rounded)),
                    IconButton(onPressed: AdhanPlayer.stop, tooltip: 'Stop', icon: const Icon(Icons.stop_circle_outlined)),
                  ]),
                ]),
              ),
            ListTile(
              title: const Text('Hijri date adjustment'),
              subtitle: Text(s.hijriAdjust == 0 ? 'As calculated. Change it by a day if your local moon sighting differs.' : '${s.hijriAdjust > 0 ? '+' : ''}${s.hijriAdjust} day${s.hijriAdjust.abs() == 1 ? '' : 's'} from the calculated date'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: s.hijriAdjust <= -2 ? null : () => s.hijriAdjust = s.hijriAdjust - 1, icon: const Icon(Icons.remove_circle_outline_rounded)),
                IconButton(onPressed: s.hijriAdjust >= 2 ? null : () => s.hijriAdjust = s.hijriAdjust + 1, icon: const Icon(Icons.add_circle_outline_rounded)),
              ]),
            ),
            ListTile(
              title: const Text('Verse of the day reminder'),
              subtitle: Text(s.dailyVerseAt < 0 ? 'Off' : '${(s.dailyVerseAt ~/ 60).toString().padLeft(2, '0')}:${(s.dailyVerseAt % 60).toString().padLeft(2, '0')} every day'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickVerseTime(context),
            ),
            if ((s.notifyPrayers && s.place != null) || s.dailyVerseAt >= 0)
              ListTile(title: const Text('Send a test notification'), trailing: const Icon(Icons.notifications_active_outlined), onTap: () => PrayerNotifier.test(adhan: s.adhan, sound: s.adhanSound, file: s.adhanFile)),
          ]),
        ),
        SliverToBoxAdapter(
          child: group('Your data', [
            ListTile(
              title: const Text('Copy a backup'),
              subtitle: const Text('Bookmarks, notes, progress and settings, as text you can keep'),
              trailing: const Icon(Icons.copy_all_rounded),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: s.exportBackup()));
                if (context.mounted) showToast(context, 'Backup copied. Paste it somewhere safe.');
              },
            ),
            ListTile(
              title: const Text('Restore from a backup'),
              subtitle: const Text('Paste a backup you copied before'),
              trailing: const Icon(Icons.restore_rounded),
              onTap: () => _restoreDialog(context),
            ),
          ]),
        ),
        SliverToBoxAdapter(
          child: group('About', [
            ListTile(title: const Text('IQRA'), subtitle: Text('Version ${up.current.isEmpty ? '…' : up.current} · free and open source (MIT)')),
            ListTile(
              title: Text(up.available ? 'Update to ${up.latest}' : 'Check for updates'),
              subtitle: Text(up.downloading ? (up.installMessage ?? 'Downloading…') : (up.checking ? 'Checking…' : (up.installMessage ?? up.message ?? 'See if a newer version is available'))),
              trailing: up.downloading ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, value: up.progress == 0 ? null : up.progress)) : Icon(up.available ? Icons.system_update_alt_rounded : Icons.refresh_rounded),
              onTap: up.checking || up.downloading
                  ? null
                  : () async {
                      if (up.available) {
                        await up.install();
                      } else {
                        await up.check(announce: true);
                      }
                    },
            ),
            ListTile(title: const Text('Source code and licences'), subtitle: const Text('github.com/SamaOmmy/IQRA'), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => launchUrl(Uri.parse('https://github.com/$kRepo'))),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                'Qur’an text and word data: quran.com (Quran Foundation). Recitations: everyayah.com. Translations and tafsir: the open-data sources credited in NOTICE.md. Stories, guides and hadith summaries are written for IQRA; please review them with a scholar.',
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  void _pickVerseTime(BuildContext context) {
    final s = context.read<AppStore>();
    const options = <(String, int)>[('Off', -1), ('6:00 AM', 360), ('7:00 AM', 420), ('8:00 AM', 480), ('12:30 PM', 750), ('6:00 PM', 1080), ('9:00 PM', 1260)];
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Verse of the day'),
        children: [
          for (final o in options)
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(ctx);
                if (o.$2 >= 0) await PrayerNotifier.requestPermission();
                s.dailyVerseAt = o.$2;
              },
              child: Row(children: [
                Expanded(child: Text(o.$1, style: const TextStyle(fontSize: 16))),
                if (s.dailyVerseAt == o.$2) Icon(Icons.check_rounded, color: ctx.c.accent),
              ]),
            ),
        ],
      ),
    );
  }

  void _restoreDialog(BuildContext context) {
    final store = context.read<AppStore>();
    final ctl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore a backup'),
        content: SizedBox(
          width: 420,
          child: TextField(controller: ctl, minLines: 4, maxLines: 8, decoration: const InputDecoration(hintText: 'Paste the backup text here')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              try {
                final n = store.importBackup(ctl.text.trim());
                Navigator.pop(ctx);
                showToast(context, 'Restored $n settings');
              } catch (_) {
                showToast(ctx, 'That is not an IQRA backup');
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _pickTranslation(BuildContext context) {
    final s = context.read<AppStore>();
    final c = context.c;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: Glass(
            blur: 40,
            opacity: 0.96,
            color: c.bg,
            radius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Column(children: [
              const Padding(padding: EdgeInsets.fromLTRB(22, 20, 22, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Translation', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)))),
              Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Other languages download once, then work offline.', style: TextStyle(color: c.textSecondary, fontSize: 13)))),
              Expanded(
                child: ListView(children: [
                  for (final t in Quran.I.translations)
                    ListTile(
                      title: Text(t.name),
                      subtitle: Text(t.lang.toUpperCase()),
                      trailing: t.id == s.translationId ? Icon(Icons.check_rounded, color: c.accent) : null,
                      onTap: () {
                        s.translationId = t.id;
                        Navigator.of(ctx).pop();
                      },
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _pickReciter(BuildContext context) {
    final s = context.read<AppStore>();
    final c = context.c;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Glass(
            blur: 40,
            opacity: 0.96,
            color: c.bg,
            radius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: ListView(children: [
              for (final r in kReciters)
                ListTile(
                  title: Text(r.$2),
                  trailing: r.$1 == s.reciter ? Icon(Icons.check_rounded, color: c.accent) : null,
                  onTap: () {
                    s.reciter = r.$1;
                    Navigator.of(ctx).pop();
                    final au = context.read<AudioController>();
                    final now = au.current;
                    if (now != null && au.playing) au.playVerse(now.s, now.a); // carry on in the new voice
                  },
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.id, required this.name, required this.colors, required this.selected, required this.onTap});
  final String id, name;
  final IqraColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => selected ? onTap() : ThemeWave.run(context, onTap),
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 72,
          height: 54,
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? c.accent : c.separator, width: selected ? 2.5 : 1),
          ),
          child: Stack(children: [
            Positioned(left: 8, top: 8, right: 22, child: Container(height: 5, decoration: BoxDecoration(color: colors.text, borderRadius: BorderRadius.circular(3)))),
            Positioned(left: 8, top: 19, right: 38, child: Container(height: 4, decoration: BoxDecoration(color: colors.textSecondary, borderRadius: BorderRadius.circular(3)))),
            Positioned(left: 8, bottom: 8, child: Container(width: 22, height: 10, decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(5)))),
          ]),
        ),
        const SizedBox(height: 5),
        Text(name, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
      ]),
    );
  }
}


/// Android: shows whether the lock-screen / notification controls can appear, and fixes the usual reasons with one tap.
/// Lets the person use any audio file from the device as the adhan (copied into the app, so it keeps working).
Future<void> _pickOwnAdhan(BuildContext context, AppStore s) async {
  try {
    final file = await openFile(acceptedTypeGroups: const [XTypeGroup(label: 'Audio', extensions: ['mp3', 'ogg', 'm4a', 'wav', 'aac', 'opus', 'flac'])]);
    if (file == null) return;
    final dir = await getApplicationSupportDirectory();
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'mp3';
    final dest = File('${dir.path}${Platform.pathSeparator}adhan_own.$ext');
    await dest.writeAsBytes(await file.readAsBytes(), flush: true);
    s.adhanFile = dest.path;
    s.adhanSound = 0;
    PrayerNotifier.setSound(0, path: dest.path);
    AdhanPlayer.play(sound: 0, file: dest.path);
  } catch (e) {
    if (context.mounted) showToast(context, 'Could not use that file ($e)');
  }
}

class _PhoneControlsTile extends StatefulWidget {
  const _PhoneControlsTile();

  @override
  State<_PhoneControlsTile> createState() => _PhoneControlsTileState();
}

class _PhoneControlsTileState extends State<_PhoneControlsTile> with WidgetsBindingObserver {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(); // back from the system settings page
  }

  Future<void> _check() async {
    final on = await PhoneSetup.notificationsOn();
    if (mounted) setState(() => _allowed = on);
  }

  Future<void> _fix() async {
    if (_allowed == false) {
      await PrayerNotifier.requestPermission();
      await _check();
      if (_allowed == false) await PhoneSetup.openNotificationSettings(); // the system will not ask again: open its page
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ValueListenableBuilder<String>(
        valueListenable: IqraMediaSession.status,
        builder: (_, st, __) {
          final off = _allowed == false;
          final failed = st.startsWith('Could not');
          return ListTile(
            leading: Icon(off || failed ? Icons.notifications_off_rounded : Icons.lock_clock_rounded, color: off || failed ? Colors.orange : c.accent),
            title: const Text('Lock-screen and notification controls'),
            subtitle: Text(
              failed
                  ? 'Not available: ${st.replaceFirst('Could not start: ', '')}'
                  : off
                      ? 'Notifications are off for IQRA, so the controls cannot show. Tap to turn them on.'
                      : 'On: while a recitation plays you can pause, skip and bookmark from the lock screen and the notification.',
            ),
            trailing: off ? const Icon(Icons.chevron_right_rounded) : null,
            onTap: off ? _fix : null,
          );
        },
      ),
      ListTile(
        leading: Icon(Icons.battery_saver_rounded, color: c.accent),
        title: const Text('Keep playing in the background'),
        subtitle: const Text('If your phone stops the recitation, or misses the adhan, when the screen is off: open this page and set IQRA to Unrestricted (or Do not optimise).'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: PhoneSetup.openBatterySettings,
      ),
    ]);
  }
}
