import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/prayer.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../widgets.dart';
import 'city_picker.dart';
import 'qibla_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final place = store.place;
    if (place == null) {
      return LargePage(title: 'Prayer times', slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_city_rounded, size: 56, color: c.accent),
                const SizedBox(height: 14),
                const Text('Choose your city', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Prayer times and the qibla are worked out on your device from your city. Nothing is sent anywhere.', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.45)),
                const SizedBox(height: 18),
                FilledButton(onPressed: () => pickCity(context), style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)), child: const Text('Choose city')),
              ]),
            ),
          ),
        ),
      ]);
    }
    final times = store.prayersOn();
    final next = store.upcoming();
    final left = next.at.difference(DateTime.now().toUtc());
    final bearing = qiblaBearing(place.lat, place.lon);
    final dist = distanceToKaabaKm(place.lat, place.lon);
    final method = kPrayerMethods.firstWhere((m) => m.id == store.prayerMethod, orElse: () => kPrayerMethods.first);
    return LargePage(
      title: 'Prayer times',
      subtitle: '${place.name}${place.country.isEmpty ? '' : ', ${place.country}'}',
      maxWidth: 760,
      actions: [IconButton(onPressed: () => pickCity(context), icon: Icon(Icons.edit_location_alt_rounded, color: c.accent), tooltip: 'Change city')],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: ColorTile(
              seed: 5,
              height: 176,
              radius: 24,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NEXT · ${kPrayerNames[next.key]!.toUpperCase()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w800, letterSpacing: 1.3, fontSize: 12)),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${left.inHours.toString().padLeft(2, '0')}:${(left.inMinutes % 60).toString().padLeft(2, '0')}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                  Text('at ${clockText(next.at, place, h24: store.clock24)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15)),
                ]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                for (var i = 0; i < kPrayerKeys.length; i++) ...[
                  if (i > 0) const Divider1(indent: 18),
                  Builder(builder: (_) {
                    final k = kPrayerKeys[i];
                    final isNext = k == next.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(children: [
                        Icon(k == 'sunrise' ? Icons.wb_twilight_rounded : Icons.circle, size: k == 'sunrise' ? 20 : 10, color: isNext ? c.accent : c.textSecondary),
                        const SizedBox(width: 14),
                        Expanded(child: Text(kPrayerNames[k]!, style: TextStyle(fontSize: 16.5, fontWeight: isNext ? FontWeight.w800 : FontWeight.w600, color: isNext ? c.accent : c.text))),
                        Directionality(textDirection: TextDirection.rtl, child: Text(kPrayerArabic[k]!, style: TextStyle(fontFamily: kArabicFont, color: c.textSecondary, fontSize: 17))),
                        const SizedBox(width: 18),
                        Text(clockText(times[k]!, place, h24: store.clock24), style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: isNext ? c.accent : c.text, fontFeatures: const [FontFeature.tabularFigures()])),
                      ]),
                    );
                  }),
                ],
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Pressable(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
              radius: 20,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  SizedBox(width: 92, height: 92, child: QiblaDial(heading: null, bearing: bearing, aligned: false, accent: c.accent, good: c.accent, text: c.text, dim: c.textSecondary, surface: c.bg)),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Qibla', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${bearing.toStringAsFixed(1)}° ${compassName(bearing)}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 15.5)),
                      Text('${dist.round()} km to the Ka‘bah', style: TextStyle(color: c.textSecondary)),
                      const SizedBox(height: 6),
                      Text('Open the compass', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ]),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                ]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
              child: Material(
                type: MaterialType.transparency,
                child: Column(children: [
                Row(children: [
                  const Text('Method', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: method.id,
                        dropdownColor: c.surface,
                        alignment: Alignment.centerRight,
                        items: [for (final m in kPrayerMethods) DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))],
                        onChanged: (v) => v == null ? null : store.prayerMethod = v,
                      ),
                    ),
                  ),
                ]),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Hanafi Asr (later)'), value: store.hanafi, onChanged: (v) => store.hanafi = v),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('24-hour clock'), value: store.clock24, onChanged: (v) => store.clock24 = v),
                const Divider1(),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: const Text('Adjust minutes', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Match your local mosque timetable', style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
                  children: [
                    for (final k in kPrayerKeys) _AdjustRow(k: k, store: store),
                    const SizedBox(height: 6),
                  ],
                ),
              ]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
            child: Text(
              'Calculated on your device for ${place.name} using ${method.name}${method.ishaMinutes > 0 ? ' (Isha ${method.ishaMinutes} minutes after Maghrib)' : ' (Fajr ${method.fajr}°, Isha ${method.isha}°)'}. They are estimates: if your mosque publishes a timetable, use “Adjust minutes” to match it.',
              style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.45),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdjustRow extends StatelessWidget {
  const _AdjustRow({required this.k, required this.store});
  final String k;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final v = store.prayerAdjust[k] ?? 0;
    return Row(children: [
      Expanded(child: Text(kPrayerNames[k]!, style: const TextStyle(fontSize: 15))),
      IconButton(visualDensity: VisualDensity.compact, onPressed: () => store.setPrayerAdjust(k, v - 1), icon: const Icon(Icons.remove_circle_outline_rounded)),
      SizedBox(width: 60, child: Text(v == 0 ? '0 min' : '${v > 0 ? '+' : ''}$v min', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: v == 0 ? c.textSecondary : c.accent))),
      IconButton(visualDensity: VisualDensity.compact, onPressed: () => store.setPrayerAdjust(k, v + 1), icon: const Icon(Icons.add_circle_outline_rounded)),
    ]);
  }
}
