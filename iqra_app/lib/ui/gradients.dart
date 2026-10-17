import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Gradients drawn the cheap way. Asking the graphics chip to evaluate a gradient shader for every tile on every frame of a scroll
/// is very slow on many Windows drivers (a plain two-colour tile cost about 2 ms each: a screen of tiles could not hold 60 fps).
/// A smooth gradient survives being stretched, so each one is drawn once into a tiny image, kept, and then painted as a plain
/// image, which costs next to nothing.
class Baked {
  static final Map<String, ui.Image> _cache = {};
  static const _limit = 400;

  static ui.Image _get(String key, int w, int h, ui.Shader Function(Rect) shader) {
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit; // most recently used goes last
      return hit;
    }
    final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(rect, Paint()..shader = shader(rect));
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    _cache[key] = img;
    if (_cache.length > _limit) _cache.remove(_cache.keys.first)?.dispose();
    return img;
  }

  /// Flutter's own gradients space the colours evenly when no stops are given; the engine's shader insists on stops for more than two colours.
  static List<double>? _even(List<Color> colors, List<double>? stops) {
    if (stops != null || colors.length == 2) return stops;
    return [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];
  }

  static (int, int) _dims(double aspect) {
    const w = 64;
    return (w, (w / aspect).round().clamp(8, 256));
  }

  static ui.Image linear(List<Color> colors, List<double>? stops, Alignment begin, Alignment end, double aspect) {
    final (w, h) = _dims(aspect);
    final key = 'L${colors.map((c) => c.toARGB32()).join(',')}|${stops?.join(',')}|${begin.x},${begin.y}>${end.x},${end.y}|$w$h';
    final st = _even(colors, stops);
    return _get(key, w, h, (r) => ui.Gradient.linear(begin.withinRect(r), end.withinRect(r), colors, st));
  }

  static ui.Image radial(List<Color> colors, List<double>? stops, Alignment center, double radius, double aspect) {
    final (w, h) = _dims(aspect);
    final key = 'R${colors.map((c) => c.toARGB32()).join(',')}|${stops?.join(',')}|${center.x},${center.y}@$radius|$w$h';
    final st = _even(colors, stops);
    return _get(key, w, h, (r) => ui.Gradient.radial(center.withinRect(r), radius * (r.width < r.height ? r.width : r.height), colors, st));
  }
}

/// Paints a (baked) linear or radial gradient, optionally with rounded corners.
class GradientPainter extends CustomPainter {
  const GradientPainter.linear(this.colors, {this.stops, this.begin = Alignment.topLeft, this.end = Alignment.bottomRight, this.radius = 0})
      : radial = false,
        center = Alignment.center,
        spread = 1;
  const GradientPainter.radial(this.colors, {this.center = Alignment.center, this.spread = 1, this.radius = 0, this.stops})
      : radial = true,
        begin = Alignment.topLeft,
        end = Alignment.bottomRight;

  final List<Color> colors;
  final List<double>? stops;
  final bool radial;
  final Alignment begin, end, center;
  final double spread, radius;

  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final aspect = ((size.width / size.height) * 4).round() / 4;
    final img = radial
        ? Baked.radial(colors, stops, center, spread, aspect.clamp(0.25, 8.0))
        : Baked.linear(colors, stops, begin, end, aspect.clamp(0.25, 8.0));
    final dst = Offset.zero & size;
    if (radius > 0) {
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(dst, Radius.circular(radius)));
    }
    canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), dst, _paint);
    if (radius > 0) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GradientPainter old) =>
      old.radial != radial || old.radius != radius || old.begin != begin || old.end != end || old.center != center || old.spread != spread || !_same(old.colors, colors) || !_same(old.stops, stops);

  static bool _same(List? a, List? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A box with a gradient background (a replacement for a `BoxDecoration(gradient: ...)`).
class GradientBox extends StatelessWidget {
  const GradientBox({super.key, required this.colors, this.stops, this.begin = Alignment.topLeft, this.end = Alignment.bottomRight, this.radius = 0, this.width, this.height, this.child});
  final List<Color> colors;
  final List<double>? stops;
  final Alignment begin, end;
  final double radius;
  final double? width, height;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: GradientPainter.linear(colors, stops: stops, begin: begin, end: end, radius: radius), child: child),
      );
}
