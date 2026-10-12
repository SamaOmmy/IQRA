import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'page_scaffold.dart';
import 'widgets.dart';

const _repo = 'SamaOmmy/IQRA';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String? _update;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) => mounted ? setState(() => _version = p.version) : null);
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _update = null;
    });
    try {
      final res = await http.get(Uri.parse('https://api.github.com/repos/$_repo/releases/latest'), headers: {'Accept': 'application/vnd.github+json'});
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (j['tag_name'] as String).replaceFirst('v', '');
      setState(() => _update = _newer(tag, _version) ? 'Version $tag is available.' : 'You have the latest version.');
      if (_newer(tag, _version)) {
        final url = j['html_url'] as String;
        if (mounted) showToast(context, 'Version $tag is available');
        await launchUrl(Uri.parse(url));
      }
    } catch (_) {
      setState(() => _update = 'Could not check. Try again when you are online.');
    }
    if (mounted) setState(() => _checking = false);
  }

  bool _newer(String a, String b) {
    List<int> p(String s) => s.split('.').map((x) => int.tryParse(x.replaceAll(RegExp(r'\D'), '')) ?? 0).toList();
    final x = p(a), y = p(b);
    for (var i = 0; i < 3; i++) {
      final u = i < x.length ? x[i] : 0, v = i < y.length ? y[i] : 0;
      if (u != v) return u > v;
    }
    return false;
  }

  Future<void> _clearAudio() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/audio');
    if (await d.exists()) await d.delete(recursive: true);
    if (mounted) showToast(context, 'Downloaded recitations removed');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppStore>();
    Widget group(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(6, 0, 0, 8), child: Text(title.toUpperCase(), style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
            Container(decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: children)),
          ]),
        );

    return LargePage(
      title: 'Settings',
      maxWidth: 760,
      slivers: [
        SliverToBoxAdapter(
          child: group('Theme', [
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
              child: Row(children: [
                const Expanded(child: Text('Accent colour', style: TextStyle(fontWeight: FontWeight.w600))),
                Wrap(spacing: 8, children: [
                  for (final a in kAccents)
                    GestureDetector(
                      onTap: () => s.accent = a.$2?.toARGB32() ?? 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 26,
                        height: 26,
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
            SwitchListTile(title: const Text('Gentle animations'), subtitle: const Text('Cards glide in, pages turn smoothly'), value: s.motion, onChanged: (v) => s.motion = v),
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
            ListTile(title: const Text('Remove downloaded recitations'), subtitle: const Text('Frees space; they download again when played'), trailing: const Icon(Icons.delete_outline_rounded), onTap: _clearAudio),
          ]),
        ),
        SliverToBoxAdapter(
          child: group('About', [
            ListTile(title: const Text('IQRA'), subtitle: Text('Version $_version · free and open source (MIT)')),
            ListTile(
              title: const Text('Check for updates'),
              subtitle: Text(_checking ? 'Checking…' : (_update ?? 'See if a newer version is available')),
              trailing: const Icon(Icons.refresh_rounded),
              onTap: _checking ? null : _check,
            ),
            ListTile(title: const Text('Source code and licences'), subtitle: const Text('github.com/SamaOmmy/IQRA'), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => launchUrl(Uri.parse('https://github.com/$_repo'))),
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

  void _pickTranslation(BuildContext context) {
    final s = context.read<AppStore>();
    final c = context.c;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
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
      onTap: onTap,
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
