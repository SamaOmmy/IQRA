import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/cities.dart';
import '../core/prayer.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'tools/city_picker.dart';
import 'widgets.dart';

/// A short first-run setup: city (for prayer times), theme and translation.
class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  int _step = 0;
  String _q = '';
  bool _locating = false;
  String? _locError;

  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _locError = null;
    });
    final store = context.read<AppStore>();
    try {
      final p = await locateMe();
      store.place = p;
      store.prayerMethod = methodForCountry(p.country);
      if (mounted) setState(() => _locating = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locError = e is String ? 'Could not use location. Choose a city below.' : 'Could not find your location. Choose a city below.';
        });
      }
    }
  }

  void _next() {
    if (_step >= 2) {
      context.read<AppStore>().seenWelcome = true;
      widget.onDone();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final titles = ['Welcome to IQRA', 'Where are you?', 'Make it yours'];
    final subs = [
      'A quiet place to read, listen to and learn from the Qur’an. Everything works offline, nothing is tracked, and it is free.',
      'Choose a city for accurate prayer times and the qibla direction. You can skip this and set it later.',
      'Pick a look and the translation you read in. Both can be changed any time in Settings.',
    ];
    final cities = [
      for (final p in kCities)
        if (_q.isEmpty || '${p.name} ${p.country}'.toLowerCase().contains(_q.toLowerCase())) p,
    ].take(40).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 4,
                        decoration: BoxDecoration(color: i <= _step ? c.accent : c.separator, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                ]),
                const SizedBox(height: 34),
                if (_step == 0) ...[
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [c.accent, c.accent.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: Text('ق', style: TextStyle(fontFamily: kArabicFont, fontSize: 48, color: c.onAccent, height: 1.2)),
                  ),
                  const SizedBox(height: 22),
                ],
                Text(titles[_step], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                const SizedBox(height: 10),
                Text(subs[_step], style: TextStyle(color: c.textSecondary, fontSize: 16, height: 1.5)),
                const SizedBox(height: 22),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_step) {
                      0 => const SizedBox(key: ValueKey('a')),
                      1 => Column(key: const ValueKey('b'), children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _locating ? null : _useLocation,
                              icon: _locating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, size: 18),
                              label: Text(_locating ? 'Finding your location…' : (_locError ?? 'Use my location')),
                            ),
                          ),
                          TextField(
                            onChanged: (v) => setState(() => _q = v),
                            decoration: InputDecoration(hintText: 'Search a city', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: cities.length,
                              itemBuilder: (_, i) {
                                final p = cities[i];
                                final sel = store.place?.name == p.name;
                                return ListTile(
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(p.country),
                                  trailing: sel ? Icon(Icons.check_circle_rounded, color: c.accent) : null,
                                  onTap: () {
                                    store.place = p;
                                    store.prayerMethod = methodForCountry(p.country);
                                  },
                                );
                              },
                            ),
                          ),
                        ]),
                      _ => ListView(key: const ValueKey('c'), children: [
                          Wrap(spacing: 14, runSpacing: 14, children: [
                            for (final t in [('auto', 'Auto'), for (final k in kThemes) (k.id, k.name)])
                              GestureDetector(
                                onTap: () => store.theme = t.$1,
                                child: Column(children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 78,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: resolveTheme(t.$1, MediaQuery.platformBrightnessOf(context)).colors.bg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: store.theme == t.$1 ? c.accent : c.separator, width: store.theme == t.$1 ? 3 : 1),
                                    ),
                                    child: Center(child: Container(width: 26, height: 10, decoration: BoxDecoration(color: resolveTheme(t.$1, MediaQuery.platformBrightnessOf(context)).colors.accent, borderRadius: BorderRadius.circular(5)))),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(t.$2, style: TextStyle(fontSize: 12, fontWeight: store.theme == t.$1 ? FontWeight.w800 : FontWeight.w500)),
                                ]),
                              ),
                          ]),
                          const SizedBox(height: 22),
                          Text('Translation', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.6)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: store.translationId,
                              dropdownColor: c.surface,
                              items: [for (final t in Quran.I.translations) DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.lang})', overflow: TextOverflow.ellipsis))],
                              onChanged: (v) => v == null ? null : store.translationId = v,
                            ),
                          ),
                        ]),
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  if (_step == 1) TextButton(onPressed: _next, child: const Text('Skip')),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15)),
                    child: Text(_step == 2 ? 'Start reading' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
