import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/perf.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'gradients.dart';

const kArabicFont = 'OldMadina';

/// True when the person asked for gentle motion (Settings) and the system hasn't asked for less.
bool motionOn(BuildContext context) =>
    context.read<AppStore>().motion && !MediaQuery.of(context).disableAnimations;

/// Frosted translucent surface: the look of Apple Music's bars and panels.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.blur = 28, this.opacity = 0.72, this.color, this.radius, this.border = false});
  final Widget child;
  final double blur, opacity;
  final Color? color;
  final BorderRadius? radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final phone = !Perf.glassBlur; // a live blur over scrolling content costs a frame on every frame of a scroll: a nearly solid surface instead
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: (color ?? c.bg).withValues(alpha: phone ? math.max(opacity, 0.985) : opacity),
        borderRadius: radius,
        border: border ? Border.all(color: c.separator.withValues(alpha: 0.7)) : null,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
    Widget w = phone ? box : BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: box);
    w = radius != null ? ClipRRect(borderRadius: radius!, child: w) : ClipRect(child: w);
    return w;
  }
}

/// Scales slightly while pressed and lifts a hover tint on desktop.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.onSecondaryTap, this.radius = 14, this.scale = 0.97, this.hover = true});
  final Widget child;
  final VoidCallback? onTap, onLongPress, onSecondaryTap;
  final double radius, scale;
  final bool hover;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false, _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: widget.hover && _hover ? c.text.withValues(alpha: 0.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

const _artPalette = <(Color, Color)>[
  (Color(0xFF0F8B6D), Color(0xFF38D2A8)),
  (Color(0xFF1D4E89), Color(0xFF58B0E0)),
  (Color(0xFF6D28D9), Color(0xFFB794F6)),
  (Color(0xFFB5179E), Color(0xFFFF5FA2)),
  (Color(0xFFD9602F), Color(0xFFF7B267)),
  (Color(0xFF1F5F5B), Color(0xFF45B7A5)),
  (Color(0xFFC1123F), Color(0xFFFF7A93)),
  (Color(0xFF3A2FA3), Color(0xFF6C7BFF)),
  (Color(0xFF8A5A22), Color(0xFFE0B25A)),
  (Color(0xFF14505F), Color(0xFF7FC29B)),
  (Color(0xFF4B2A63), Color(0xFF9B6BB5)),
  (Color(0xFF0B486B), Color(0xFFF08A4B)),
];

(Color, Color) artColors(int seed) => _artPalette[seed % _artPalette.length];

/// Decorative geometric patterns for artwork. Each surah gets one of them, chosen by its number.
class ArtPatternPainter extends CustomPainter {
  ArtPatternPainter(this.kind, this.color);
  final int kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, w / 110);
    final fill = Paint()..color = color.withValues(alpha: color.a * 0.55);
    switch (kind % 6) {
      case 0: // nested squares: the eight-pointed star
        final cx = w * 0.82, cy = h * 0.2;
        for (var ring = 0; ring < 4; ring++) {
          final r = w * (0.18 + ring * 0.13);
          for (var k = 0; k < 2; k++) {
            final path = Path();
            for (var i = 0; i < 4; i++) {
              final a = math.pi / 4 * k + i * math.pi / 2;
              final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
              i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
            }
            path.close();
            canvas.drawPath(path, stroke);
          }
        }
      case 1: // honeycomb
        final r = w * 0.15;
        final dx = r * math.sqrt(3), dy = r * 1.5;
        for (var row = -1; row < h / dy + 1; row++) {
          for (var col = -1; col < w / dx + 1; col++) {
            final cx = col * dx + (row.isOdd ? dx / 2 : 0) + w * 0.18;
            final cy = row * dy + h * 0.02;
            if (cx < w * 0.25 && cy > h * 0.45) continue;
            final path = Path();
            for (var i = 0; i < 6; i++) {
              final a = math.pi / 6 + i * math.pi / 3;
              final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
              i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
            }
            path.close();
            canvas.drawPath(path, stroke);
          }
        }
      case 2: // mihrab arches
        for (var i = 0; i < 5; i++) {
          final r = w * (0.2 + i * 0.12);
          final rect = Rect.fromCenter(center: Offset(w * 0.78, h * 0.12), width: r * 2, height: r * 2.6);
          canvas.drawArc(rect, math.pi, math.pi, false, stroke);
          canvas.drawLine(Offset(rect.left, rect.center.dy), Offset(rect.left, h), stroke);
          canvas.drawLine(Offset(rect.right, rect.center.dy), Offset(rect.right, h), stroke);
        }
      case 3: // overlapping circles
        final r = w * 0.2;
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            canvas.drawCircle(Offset(w * 0.45 + i * r * 0.9, h * -0.02 + j * r * 0.9), r, stroke);
          }
        }
      case 4: // diamond lattice
        final step = w * 0.17;
        for (var i = -2; i < (w + h) / step + 2; i++) {
          canvas.drawLine(Offset(i * step, 0), Offset(i * step + h, h), stroke);
          canvas.drawLine(Offset(i * step, h), Offset(i * step + h, 0), stroke);
        }
      default: // dotted rosette
        final cx = w * 0.8, cy = h * 0.22;
        for (var ring = 1; ring <= 5; ring++) {
          final r = w * 0.08 * ring;
          final n = 6 + ring * 4;
          for (var i = 0; i < n; i++) {
            final a = i * 2 * math.pi / n + ring * 0.3;
            canvas.drawCircle(Offset(cx + r * math.cos(a), cy + r * math.sin(a)), math.max(1.2, w / 70), fill);
          }
        }
    }
  }

  @override
  bool shouldRepaint(covariant ArtPatternPainter old) => old.kind != kind || old.color != color;
}

/// A surah's "album cover": gradient, geometric pattern, number and calligraphy.
class SurahArt extends StatelessWidget {
  const SurahArt({super.key, required this.surah, this.size = 140, this.radius, this.showName = true});
  final int surah;
  final double size;
  final double? radius;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final (a, b) = artColors(surah * 5 + 2);
    final s = Quran.I.surah(surah);
    final r = radius ?? size * 0.1;
    return RepaintBoundary(child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: [BoxShadow(color: a.withValues(alpha: 0.3), blurRadius: size * 0.14, offset: Offset(0, size * 0.06))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GradientPainter.linear([a, b]))),
          // soft light from the top corner
          Positioned.fill(child: CustomPaint(painter: GradientPainter.radial([Colors.white.withValues(alpha: 0.22), Colors.transparent], center: const Alignment(-0.7, -0.9), spread: 1.2))),
          Positioned.fill(child: CustomPaint(painter: ArtPatternPainter(surah, Colors.white.withValues(alpha: 0.2)))),
          // a large faint copy of the name behind everything
          if (showName && size > 90)
            Positioned(
              right: -size * 0.05,
              bottom: -size * 0.14,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(s.ar, style: TextStyle(fontFamily: kArabicFont, color: Colors.white.withValues(alpha: 0.1), fontSize: size * 0.62, height: 1)),
              ),
            ),
          Positioned(
            left: size * 0.09,
            top: size * 0.07,
            child: Text('$surah', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w800, fontSize: size * 0.12)),
          ),
          if (showName)
            Positioned(
              left: size * 0.07,
              right: size * 0.07,
              bottom: size * 0.07,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(s.ar, style: TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: size * 0.24, height: 1.2)),
                ),
              ),
            ),
          // thin inner highlight, like the edge of a record sleeve
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: math.max(0.8, size / 180)),
              ),
            ),
          ),
        ]),
      ),
    ));
  }
}

/// Artwork with a play button that appears on hover (desktop), as in Apple Music.
class ArtTile extends StatefulWidget {
  const ArtTile({super.key, required this.surah, required this.onOpen, required this.onPlay, this.onMore});
  final int surah;
  final VoidCallback onOpen, onPlay;
  final VoidCallback? onMore;

  @override
  State<ArtTile> createState() => _ArtTileState();
}

class _ArtTileState extends State<ArtTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = Quran.I.surah(widget.surah);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        onLongPress: widget.onPlay,
        onSecondaryTap: widget.onMore,
        child: AnimatedScale(
          scale: _hover ? 1.025 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LayoutBuilder(builder: (_, b) {
              return Stack(children: [
                SurahArt(surah: widget.surah, size: b.maxWidth),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: AnimatedOpacity(
                    opacity: _hover ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: !_hover,
                      child: GestureDetector(
                        onTap: widget.onPlay,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10)]),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 26),
                        ),
                      ),
                    ),
                  ),
                ),
              ]);
            }),
            const SizedBox(height: 9),
            Text(s.en, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            Text('${s.meaning} · ${s.ayahs.length}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

/// A sliver grid whose tiles keep a fixed text height under square artwork, at any window width.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.count, required this.builder, this.minTile = 160, this.gap = 16, this.extra = 68, this.padding = 20});
  final int count;
  final Widget Function(BuildContext, int) builder;
  final double minTile, gap, extra, padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 0),
      sliver: SliverLayoutBuilder(builder: (context, c) {
        final w = c.crossAxisExtent;
        final cols = math.max(2, ((w + gap) / (minTile + gap)).floor());
        final tile = (w - gap * (cols - 1)) / cols;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: gap + 4, crossAxisSpacing: gap, mainAxisExtent: tile + extra),
          itemCount: count,
          itemBuilder: builder,
        );
      }),
    );
  }
}

/// A coloured tile for non-surah things (collections, stories, tools).
class ColorTile extends StatelessWidget {
  const ColorTile({super.key, required this.seed, required this.child, this.width, this.height, this.radius = 18});
  final int seed;
  final Widget child;
  final double? width, height, radius;

  @override
  Widget build(BuildContext context) {
    final (a, b) = artColors(seed);
    final r = radius ?? 18;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(r)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GradientPainter.linear([a, b]))),
          Positioned.fill(child: CustomPaint(painter: GradientPainter.radial([Colors.white.withValues(alpha: 0.2), Colors.transparent], center: const Alignment(-0.8, -1), spread: 1.3))),
          Positioned.fill(child: CustomPaint(painter: ArtPatternPainter(seed, Colors.white.withValues(alpha: 0.16)))),
          child,
        ]),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onMore, this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 10), this.subtitle});
  final String title;
  final String? subtitle;
  final VoidCallback? onMore;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final row = Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Flexible(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.3))),
      if (onMore != null) ...[
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 24),
      ],
    ]);
    return Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        onMore == null ? row : Pressable(onTap: onMore, radius: 8, hover: false, child: row),
        if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: TextStyle(color: c.textSecondary, fontSize: 14))),
      ]),
    );
  }
}

/// A horizontally scrolling shelf.
class Shelf extends StatelessWidget {
  const Shelf({super.key, required this.height, required this.children, this.gap = 14, this.padding = const EdgeInsets.symmetric(horizontal: 24)});
  final double height, gap;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.selected = false, this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      radius: 100,
      scale: 0.95,
      hover: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: selected ? c.accent : c.surface, borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: selected ? c.onAccent : c.text), const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? c.onAccent : c.text)),
        ]),
      ),
    );
  }
}

/// Inline segmented control in the iOS / Apple Music style. Scales down rather than overflowing on narrow screens.
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.index, required this.onChanged});
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: i == index ? c.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: i == index ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
                ),
                child: Text(items[i], style: TextStyle(fontSize: 13.5, fontWeight: i == index ? FontWeight.w600 : FontWeight.w500, color: i == index ? c.text : c.textSecondary)),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Fades and slides a child in the first time it appears (staggered by [index]).
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.dy = 16});
  final Widget child;
  final int index;
  final double dy;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // tiles that scroll into view while the list is moving just appear: animating each one as it arrives is what makes a fling stutter
    final moving = Scrollable.maybeOf(context)?.position.isScrollingNotifier.value ?? false;
    if (!motionOn(context) || Perf.light || moving) {
      _c.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: 30 * math.min(widget.index, 6)), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // The same widgets before, during and after the animation (no state is lost at the end), and the child is painted once and then
  // only moved and faded, not repainted every frame.
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _curve,
        child: AnimatedBuilder(
          animation: _curve,
          child: RepaintBoundary(child: widget.child),
          builder: (_, child) => Transform.translate(offset: Offset(0, (1 - _curve.value) * widget.dy), child: child),
        ),
      );
}

class Divider1 extends StatelessWidget {
  const Divider1({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(left: indent), child: Container(height: 0.6, color: context.c.separator));
}

class Empty extends StatelessWidget {
  const Empty(this.icon, this.title, this.message, {super.key});
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 54, color: c.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.4)),
        ]),
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  final c = context.c;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: c.bg, fontWeight: FontWeight.w600)),
      backgroundColor: c.text.withValues(alpha: 0.92),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      duration: const Duration(milliseconds: 1800),
    ));
}

/// Text the person can select and copy. Unlike [SelectableText] it has no scroller of its own, so a finger or touchpad drag on
/// it still scrolls the page (the app's always-scrollable physics made the text's own scroller swallow the drag).
Widget selectableText(String text, {TextStyle? style, TextAlign? textAlign}) => SelectionArea(child: Text(text, style: style, textAlign: textAlign));
