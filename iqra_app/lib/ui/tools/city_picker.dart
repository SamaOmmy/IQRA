import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/cities.dart';
import '../../core/prayer.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Opens the city sheet and saves the chosen place. When the country changes, the calculation method most people there use is
/// selected too (it can still be changed in Settings).
Future<void> pickCity(BuildContext context) {
  final store = context.read<AppStore>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CityPicker(onPick: (p) {
      final old = store.place;
      store.place = p;
      if (old == null || old.country != p.country) store.prayerMethod = methodForCountry(p.country);
      Navigator.of(ctx).pop();
    }),
  );
}

double _km(double lat1, double lon1, double lat2, double lon2) {
  double r(double d) => d * math.pi / 180;
  final a = math.pow(math.sin(r(lat2 - lat1) / 2), 2) + math.cos(r(lat1)) * math.cos(r(lat2)) * math.pow(math.sin(r(lon2 - lon1) / 2), 2);
  return 12742 * math.asin(math.sqrt(a));
}

/// The saved list's closest city, whose time zone is borrowed for a place found by GPS (it keeps daylight saving correct).
Place nearestCity(double lat, double lon) {
  Place best = kCities.first;
  var bestD = double.infinity;
  for (final p in kCities) {
    final d = _km(lat, lon, p.lat, p.lon);
    if (d < bestD) {
      bestD = d;
      best = p;
    }
  }
  return best;
}

/// Reads the device position once (city-level accuracy is enough for prayer times and the qibla).
Future<Place> locateMe() async {
  if (!await Geolocator.isLocationServiceEnabled()) throw 'Location is switched off on this device.';
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    throw 'Location permission was not given. You can still choose your city from the list.';
  }
  final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 25)));
  final near = nearestCity(pos.latitude, pos.longitude);
  return Place('Near ${near.name}', near.country, double.parse(pos.latitude.toStringAsFixed(4)), double.parse(pos.longitude.toStringAsFixed(4)), near.tz);
}

class CityPicker extends StatefulWidget {
  const CityPicker({super.key, required this.onPick});
  final ValueChanged<Place> onPick;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  String _q = '';
  bool _locating = false;
  String? _error;

  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final p = await locateMe();
      if (mounted) widget.onPick(p);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _error = e is String ? e : 'Could not find your location. Please choose your city from the list.';
        });
      }
    }
  }

  Future<void> _manual() async {
    final p = await showDialog<Place>(context: context, builder: (_) => const _ManualPlace());
    if (p != null && mounted) widget.onPick(p);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _q.trim().toLowerCase();
    final list = [
      for (final p in kCities)
        if (q.isEmpty || '${p.name} ${p.country}'.toLowerCase().contains(q)) p,
    ];
    return Align(
      alignment: Alignment.bottomCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Glass(
          blur: 40,
          opacity: 0.97,
          color: c.bg,
          radius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 38, height: 5, decoration: BoxDecoration(color: c.separator, borderRadius: BorderRadius.circular(3))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(hintText: 'Search a city or country', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _useLocation,
                    icon: _locating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(_locating ? 'Finding…' : 'Use my location', maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(foregroundColor: c.accent, side: BorderSide(color: c.accent.withValues(alpha: 0.5)), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _manual,
                    icon: const Icon(Icons.pin_drop_outlined, size: 18),
                    label: const Text('Enter coordinates', maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(foregroundColor: c.text, side: BorderSide(color: c.separator), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ]),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 0), child: Text(_error!, style: TextStyle(color: Colors.redAccent.shade200, fontSize: 13))),
            const SizedBox(height: 6),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No city matches “$_q”. Use “Enter coordinates” to add your place.', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary))))
                  : ListView.builder(
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

class _ManualPlace extends StatefulWidget {
  const _ManualPlace();

  @override
  State<_ManualPlace> createState() => _ManualPlaceState();
}

class _ManualPlaceState extends State<_ManualPlace> {
  final _name = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _off = TextEditingController(text: (DateTime.now().timeZoneOffset.inMinutes / 60).toString().replaceAll(RegExp(r'\.0$'), ''));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    _off.dispose();
    super.dispose();
  }

  void _save() {
    final lat = double.tryParse(_lat.text.trim()), lon = double.tryParse(_lon.text.trim()), off = double.tryParse(_off.text.trim());
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      setState(() => _error = 'Latitude must be between -90 and 90, longitude between -180 and 180.');
      return;
    }
    if (off == null || off < -12 || off > 14) {
      setState(() => _error = 'The time zone is hours from UTC, for example 3 or 5.5.');
      return;
    }
    final name = _name.text.trim().isEmpty ? 'My place' : _name.text.trim();
    Navigator.of(context).pop(Place(name, '', lat, lon, 'UTC${off >= 0 ? '+' : ''}${off == off.roundToDouble() ? off.round() : off}'));
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label, {bool number = true}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(controller: c, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
        );
    return AlertDialog(
      title: const Text('Enter a place'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          field(_name, 'Name', number: false),
          field(_lat, 'Latitude (for example -6.79)'),
          field(_lon, 'Longitude (for example 39.21)'),
          field(_off, 'Hours from UTC (for example 3)'),
          if (_error != null) Text(_error!, style: TextStyle(color: Colors.redAccent.shade200, fontSize: 13)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
