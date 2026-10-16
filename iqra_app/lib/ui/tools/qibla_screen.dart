import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../../core/prayer.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import 'city_picker.dart';

const _geo = MethodChannel('iqra/geo');

/// Qibla finder. On a phone the dial turns with the device (true north, using the phone's magnetic model); on a PC it shows the
/// bearing to read against any compass.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading; // smoothed magnetic heading, degrees
  double _declination = 0;
  double? _accuracy;
  bool _sensor = false, _waiting = true, _wasAligned = false;
  Timer? _giveUp;
  Place? _declFor;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      final stream = FlutterCompass.events;
      if (stream != null) {
        _sensor = true;
        _sub = stream.listen(_onEvent, onError: (_) => setState(() {
              _sensor = false;
              _waiting = false;
            }));
        // a phone without a magnetometer never sends a heading
        _giveUp = Timer(const Duration(seconds: 4), () {
          if (mounted && _heading == null) {
            setState(() {
              _sensor = false;
              _waiting = false;
            });
          }
        });
      }
    } else {
      _waiting = false;
    }
  }

  void _onEvent(CompassEvent e) {
    final h = e.heading;
    if (h == null || !mounted) return;
    final target = (h % 360 + 360) % 360;
    final cur = _heading;
    double next;
    if (cur == null) {
      next = target;
    } else {
      // low-pass on the circle so the dial does not jitter or spin the long way round at north
      final diff = ((target - cur + 540) % 360) - 180;
      next = (cur + diff * 0.22 + 360) % 360;
    }
    setState(() {
      _heading = next;
      _accuracy = e.accuracy;
      _waiting = false;
    });
  }

  Future<void> _loadDeclination(Place p) async {
    if (_declFor == p || !Platform.isAndroid) return;
    _declFor = p;
    try {
      final d = await _geo.invokeMethod<double>('declination', {'lat': p.lat, 'lon': p.lon});
      if (mounted) setState(() => _declination = d ?? 0);
    } catch (_) {
      _declination = 0;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _giveUp?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final place = context.watch<AppStore>().place;
    if (place == null) {
      return LargePage(title: 'Qibla', slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.explore_rounded, size: 56, color: c.accent),
                const SizedBox(height: 14),
                const Text('Choose your city', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('The qibla direction is worked out from where you are.', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.45)),
                const SizedBox(height: 18),
                FilledButton(onPressed: () => pickCity(context), style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)), child: const Text('Choose city')),
              ]),
            ),
          ),
        ),
      ]);
    }
    _loadDeclination(place);
    final bearing = qiblaBearing(place.lat, place.lon);
    final dist = distanceToKaabaKm(place.lat, place.lon);
    final heading = _heading == null ? null : (_heading! + _declination + 360) % 360;
    final off = heading == null ? null : ((bearing - heading + 540) % 360) - 180; // + means turn right
    final aligned = off != null && off.abs() <= 3;
    if (aligned && !_wasAligned) HapticFeedback.mediumImpact();
    _wasAligned = aligned;
    final good = const Color(0xFF30B261);
    final needsCalibration = _sensor && _heading != null && (_accuracy == null ? false : _accuracy! > 25);

    String status;
    if (!Platform.isAndroid || (!_sensor && !_waiting)) {
      status = 'Face ${bearing.toStringAsFixed(0)}° ${compassName(bearing)} from true north.';
    } else if (heading == null) {
      status = 'Looking for the compass…';
    } else if (aligned) {
      status = 'You are facing the Qibla';
    } else {
      status = off! > 0 ? 'Turn right ${off.abs().round()}°' : 'Turn left ${off.abs().round()}°';
    }

    return LargePage(
      title: 'Qibla',
      subtitle: '${place.name}${place.country.isEmpty ? '' : ', ${place.country}'}',
      maxWidth: 640,
      actions: [IconButton(onPressed: () => pickCity(context), icon: Icon(Icons.edit_location_alt_rounded, color: c.accent), tooltip: 'Change city')],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(children: [
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(builder: (context, box) {
                  final side = math.min(box.maxWidth, 360.0);
                  return Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: QiblaDial(heading: heading, bearing: bearing, aligned: aligned, accent: c.accent, good: good, text: c.text, dim: c.textSecondary, surface: c.surface),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(status, key: ValueKey(status), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: aligned ? good : c.text)),
              ),
              const SizedBox(height: 6),
              Text('Qibla ${bearing.toStringAsFixed(1)}° ${compassName(bearing)} · ${dist.round()} km to the Ka‘bah', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 14.5)),
            ]),
          ),
        ),
        if (needsCalibration)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _Note(icon: Icons.sync_rounded, text: 'The compass needs calibrating. Move your phone in a figure-eight a few times, away from metal and magnets.'),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _Note(
              icon: Icons.info_outline_rounded,
              text: Platform.isAndroid
                  ? (_sensor || _waiting
                      ? 'Hold the phone flat and level. The green Ka‘bah marker points to the Qibla; turn until it reaches the top. Corrected for magnetic declination (${_declination.toStringAsFixed(1)}°).'
                      : 'This phone has no compass sensor. Use the bearing above with any compass, or follow the sun: the bearing is measured clockwise from true north.')
                  : 'A PC has no compass. Use the bearing above with a compass or a phone, measuring clockwise from true north. The IQRA phone app shows a live compass.',
            ),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: c.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.45))),
      ]),
    );
  }
}

/// The compass dial. [heading] is the true heading of the top of the device (null = no sensor: north stays up).
class QiblaDial extends StatelessWidget {
  const QiblaDial({super.key, required this.heading, required this.bearing, required this.aligned, required this.accent, required this.good, required this.text, required this.dim, required this.surface});
  final double? heading;
  final double bearing;
  final bool aligned;
  final Color accent, good, text, dim, surface;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DialPainter(this));
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.d);
  final QiblaDial d;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 6;
    final ring = d.aligned ? d.good : d.accent;
    canvas.drawCircle(center, r, Paint()..color = d.surface);
    canvas.drawCircle(center, r, Paint()..color = ring.withValues(alpha: d.aligned ? 0.9 : 0.35)..style = PaintingStyle.stroke..strokeWidth = d.aligned ? 5 : 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-(d.heading ?? 0) * math.pi / 180);

    Offset at(double deg, double radius) => Offset(math.sin(deg * math.pi / 180), -math.cos(deg * math.pi / 180)) * radius;
    for (var deg = 0; deg < 360; deg += 5) {
      final major = deg % 90 == 0, mid = deg % 30 == 0;
      final len = major ? 16.0 : (mid ? 11.0 : 6.0);
      canvas.drawLine(at(deg.toDouble(), r - 8), at(deg.toDouble(), r - 8 - len), Paint()..color = major ? d.text : d.dim.withValues(alpha: mid ? 0.9 : 0.5)..strokeWidth = major ? 2.4 : 1.2);
    }
    const labels = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    labels.forEach((deg, s) {
      final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(color: deg == 0 ? const Color(0xFFE5484D) : d.text, fontSize: r * 0.115, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
      canvas.save();
      final p = at(deg.toDouble(), r - 8 - 16 - tp.height * 0.9);
      canvas.translate(p.dx, p.dy);
      canvas.rotate(deg * 0 + 0);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    });

    // direction line and the Ka'bah marker at the qibla bearing
    final tip = at(d.bearing, r * 0.62);
    canvas.drawLine(Offset.zero, tip, Paint()..color = ring..strokeWidth = 5..strokeCap = StrokeCap.round);
    final marker = at(d.bearing, r * 0.76);
    final s = r * 0.12;
    canvas.save();
    canvas.translate(marker.dx, marker.dy);
    canvas.rotate(d.bearing * math.pi / 180);
    final box = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 2), Radius.circular(s * 0.28));
    canvas.drawRRect(box, Paint()..color = const Color(0xFF15151A));
    canvas.drawRect(Rect.fromLTWH(-s, -s * 0.35, s * 2, s * 0.32), Paint()..color = const Color(0xFFD7B25A));
    canvas.drawRRect(box, Paint()..color = ring..style = PaintingStyle.stroke..strokeWidth = 2.2);
    canvas.restore();
    canvas.drawCircle(Offset.zero, 7, Paint()..color = d.text);
    canvas.drawCircle(Offset.zero, 3, Paint()..color = d.surface);
    canvas.restore();

    // fixed pointer at the top: where the phone is facing
    final path = Path()
      ..moveTo(center.dx, center.dy - r + 2)
      ..lineTo(center.dx - 9, center.dy - r - 8 + 2 + 0)
      ..lineTo(center.dx + 9, center.dy - r - 8 + 2)
      ..close();
    canvas.drawPath(path, Paint()..color = ring);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.d.heading != d.heading || old.d.bearing != d.bearing || old.d.aligned != d.aligned || old.d.accent != d.accent || old.d.surface != d.surface;
}
