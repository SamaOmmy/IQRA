import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../core/store.dart';
import '../core/theme.dart';

/// Changing the theme as a wave: the old look is frozen on top, and a rippling edge sweeps out from the button that was pressed,
/// uncovering the new look underneath until it has covered the whole screen.
class ThemeWave {
  static final GlobalKey boundary = GlobalKey();
  static final GlobalKey outer = GlobalKey(); // the app plus the wave on top (for the dev screenshots)
  static final ValueNotifier<_Snap?> _snap = ValueNotifier(null);

  /// True while a wave is running: the theme itself then switches instantly (the wave is the transition).
  static bool busy = false;

  /// Runs [change] (which switches the theme) with the wave starting at the centre of [from].
  static void run(BuildContext from, VoidCallback change, {Offset? at}) {
    final store = from.read<AppStore>();
    final box = from.findRenderObject();
    final root = boundary.currentContext?.findRenderObject();
    if (!store.motion || MediaQuery.of(from).disableAnimations || busy || box is! RenderBox || !box.hasSize || root is! RenderRepaintBoundary || !root.hasSize) {
      change();
      return;
    }
    final origin = at ?? box.localToGlobal(box.size.center(Offset.zero));
    final dpr = View.of(from).devicePixelRatio;
    final ui.Image image;
    try {
      image = root.toImageSync(pixelRatio: math.min(dpr, 1.5));
    } catch (_) {
      change();
      return;
    }
    busy = true;
    _snap.value = _Snap(image, origin, math.min(dpr, 1.5));
    change();
  }

  static void _done() {
    final s = _snap.value;
    _snap.value = null;
    busy = false;
    s?.image.dispose();
  }
}

class _Snap {
  _Snap(this.image, this.origin, this.scale);
  final ui.Image image;
  final Offset origin;
  final double scale;
}

/// Wraps the app: paints the wave over it while one is running. Place it around the app's content.
class ThemeWaveHost extends StatefulWidget {
  const ThemeWaveHost({super.key, required this.child});
  final Widget child;

  @override
  State<ThemeWaveHost> createState() => _ThemeWaveHostState();
}

class _ThemeWaveHostState extends State<ThemeWaveHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  _Snap? _current;

  @override
  void initState() {
    super.initState();
    ThemeWave._snap.addListener(_onSnap);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        ThemeWave._done();
      }
    });
  }

  @override
  void dispose() {
    ThemeWave._snap.removeListener(_onSnap);
    _c.dispose();
    super.dispose();
  }

  void _onSnap() {
    final s = ThemeWave._snap.value;
    setState(() => _current = s);
    if (s != null) {
      // starts after the new theme has had a frame to build underneath
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ThemeWave._snap.value == s) _c.forward(from: 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _current;
    return RepaintBoundary(key: ThemeWave.outer, child: Stack(fit: StackFit.passthrough, children: [
      RepaintBoundary(key: ThemeWave.boundary, child: widget.child),
      if (snap != null)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(painter: _WavePainter(snap, Curves.easeInOutCubic.transform(_c.value), _c.value, context.c.accent)),
            ),
          ),
        ),
    ]));
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.snap, this.t, this.raw, this.accent);
  final _Snap snap;
  final double t, raw;
  final Color accent;

  Path _ring(Size size, double radius, double phase) {
    // a circle whose edge ripples; the ripple eases away as the wave reaches the corners
    final amp = math.min(26 * math.sin(math.pi * raw.clamp(0.0, 1.0)) + 4, radius * 0.2);
    final path = Path();
    const n = 120;
    for (var i = 0; i <= n; i++) {
      final a = i / n * 2 * math.pi;
      final r = radius + amp * math.sin(a * 7 + phase) * 0.6 + amp * math.sin(a * 3 - phase * 0.7) * 0.4;
      final p = snap.origin + Offset(math.cos(a), math.sin(a)) * math.max(0, r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final far = [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)].map((o) => (o - snap.origin).distance).reduce(math.max);
    final radius = (far + 60) * t;
    final ring = _ring(size, radius, raw * 9);
    final old = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), ring);
    canvas.save();
    canvas.clipPath(old, doAntiAlias: true);
    canvas.drawImageRect(
      snap.image,
      Rect.fromLTWH(0, 0, snap.image.width.toDouble(), snap.image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.restore();
    // a soft glowing crest along the edge of the wave
    final fade = (1 - raw).clamp(0.0, 1.0);
    canvas.drawPath(ring, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = accent.withValues(alpha: 0.16 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(ring, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.55 * fade));
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.raw != raw || old.snap != snap || old.accent != accent;
}

/// The sun / moon button that flips between light and dark with the wave.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.color, this.size = 24});
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final system = MediaQuery.platformBrightnessOf(context);
    final dark = resolveTheme(store.theme, system).colors.dark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => ThemeWave.run(context, () => store.toggleDark(system)),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (w, a) => RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(a), child: ScaleTransition(scale: a, child: w)),
        child: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, key: ValueKey(dark), size: size, color: color ?? context.c.textSecondary),
      ),
    );
  }
}
