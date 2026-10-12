import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/cities.dart';
import '../../core/prayer.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../widgets.dart';

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
                FilledButton(onPressed: () => _pickCity(context), style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)), child: const Text('Choose city')),
              ]),
            ),
          ),
        ),
      ]);
    }
    final times = prayerTimes(localDate(place.tz, DateTime.now()), place, method: store.prayerMethod, hanafi: store.hanafi);
    final next = nextPrayer(place, method: store.prayerMethod, hanafi: store.hanafi);
    final left = next.at.difference(DateTime.now().toUtc());
    final bearing = qiblaBearing(place.lat, place.lon);
    final dist = distanceToKaabaKm(place.lat, place.lon);
    return LargePage(
      title: 'Prayer times',
      subtitle: '${place.name}, ${place.country}',
      maxWidth: 760,
      actions: [IconButton(onPressed: () => _pickCity(context), icon: Icon(Icons.edit_location_alt_rounded, color: c.accent))],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: ColorTile(
              seed: 5,
              height: 150,
              radius: 24,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NEXT · ${kPrayerNames[next.key]!.toUpperCase()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w800, letterSpacing: 1.3, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${left.inHours.toString().padLeft(2, '0')}:${(left.inMinutes % 60).toString().padLeft(2, '0')}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
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
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(painter: _QiblaPainter(bearing, c.accent, c.text, c.textSecondary)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Qibla', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${bearing.toStringAsFixed(1)}° ${compassName(bearing)} from true north', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 15.5)),
                    const SizedBox(height: 4),
                    Text('${dist.round()} km to the Ka‘bah', style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 6),
                    Text('Face this bearing from north, using a compass.', style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.4)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Row(children: [
                  const Expanded(child: Text('Method', style: TextStyle(fontWeight: FontWeight.w600))),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: store.prayerMethod,
                      dropdownColor: c.surface,
                      items: [for (final m in kPrayerMethods) DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 14)))],
                      onChanged: (v) => v == null ? null : store.prayerMethod = v,
                    ),
                  ),
                ]),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Hanafi Asr (later)'), value: store.hanafi, onChanged: (v) => store.hanafi = v),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('24-hour clock'), value: store.clock24, onChanged: (v) => store.clock24 = v),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
            child: Text('Times are calculated on your device and are estimates. Please confirm against your local mosque.', style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.45)),
          ),
        ),
      ],
    );
  }

  void _pickCity(BuildContext context) {
    final store = context.read<AppStore>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CityPicker(onPick: (p) {
        store.place = p;
        Navigator.of(ctx).pop();
      }),
    );
  }
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({required this.onPick});
  final ValueChanged<Place> onPick;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final list = [
      for (final p in kCities)
        if (_q.isEmpty || '${p.name} ${p.country}'.toLowerCase().contains(_q.toLowerCase())) p,
    ];
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Glass(
          blur: 40,
          opacity: 0.96,
          color: c.bg,
          radius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 38, height: 5, decoration: BoxDecoration(color: c.separator, borderRadius: BorderRadius.circular(3))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(hintText: 'Search a city or country', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(list[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(list[i].country),
                  onTap: () => widget.onPick(list[i]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QiblaPainter extends CustomPainter {
  _QiblaPainter(this.bearing, this.accent, this.text, this.dim);
  final double bearing;
  final Color accent, text, dim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = dim.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(c + Offset(math.sin(a), -math.cos(a)) * (r - 8), c + Offset(math.sin(a), -math.cos(a)) * r, Paint()..color = dim..strokeWidth = 2);
    }
    final tp = TextPainter(text: TextSpan(text: 'N', style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - r + 10));
    final a = bearing * math.pi / 180;
    final tip = c + Offset(math.sin(a), -math.cos(a)) * (r - 14);
    canvas.drawLine(c, tip, Paint()..color = accent..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawCircle(tip, 7, Paint()..color = accent);
    canvas.drawCircle(c, 5, Paint()..color = text);
  }

  @override
  bool shouldRepaint(covariant _QiblaPainter old) => old.bearing != bearing || old.accent != accent;
}
