import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';

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
    Widget w = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (color ?? c.bg).withValues(alpha: opacity),
          borderRadius: radius,
          border: border ? Border.all(color: c.separator.withValues(alpha: 0.7)) : null,
        ),
        child: child,
      ),
    );
    w = radius != null ? ClipRRect(borderRadius: radius!, child: w) : ClipRect(child: w);
    return w;
  }
}

/// Scales slightly while pressed and lifts a hover tint on desktop.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.radius = 14, this.scale = 0.97, this.hover = true});
  final Widget child;
  final VoidCallback? onTap, onLongPress;
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

class _StarPainter extends CustomPainter {
  _StarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.width / 90);
    final cx = size.width * 0.82, cy = size.height * 0.2;
    for (var ring = 0; ring < 4; ring++) {
      final r = size.width * (0.18 + ring * 0.13);
      for (var k = 0; k < 2; k++) {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = math.pi / 4 * k + i * math.pi / 2;
          final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}

/// A surah's "album cover": gradient, geometric star, number and calligraphy.
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? size * 0.1),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
        boxShadow: [BoxShadow(color: a.withValues(alpha: 0.28), blurRadius: size * 0.12, offset: Offset(0, size * 0.05))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * 0.1),
        child: CustomPaint(
          painter: _StarPainter(Colors.white.withValues(alpha: 0.2)),
          child: Stack(children: [
            Positioned(
              left: size * 0.09,
              top: size * 0.07,
              child: Text('$surah', style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w700, fontSize: size * 0.13)),
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
          ]),
        ),
      ),
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? 18),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius ?? 18), child: CustomPaint(painter: _StarPainter(Colors.white.withValues(alpha: 0.16)), child: child)),
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

/// Inline segmented control in the iOS / Apple Music style.
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.index, required this.onChanged});
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
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
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionOn(context)) {
      _c.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: 40 * math.min(widget.index, 8)), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(offset: Offset(0, (1 - curve.value) * widget.dy), child: child),
      ),
    );
  }
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
