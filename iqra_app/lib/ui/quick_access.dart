import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/store.dart';
import '../core/theme.dart';
import 'theme_wave.dart';

/// A small button that floats over every screen (the reader too) and opens a row of the things a person wants at any moment:
/// light/dark, search, home and settings. Drag it up or down, or to the other edge, and it stays where it is put.
class QuickAccess extends StatefulWidget {
  const QuickAccess({super.key, required this.onSearch, required this.onHome, required this.onSettings});
  final VoidCallback onSearch, onHome, onSettings;

  @override
  State<QuickAccess> createState() => _QuickAccessState();
}

class _QuickAccessState extends State<QuickAccess> {
  late double _y = context.read<AppStore>().uiInt('qaY', 62) / 100; // 0..1 down the screen
  late bool _left = context.read<AppStore>().uiInt('qaLeft', 0) == 1;
  bool _open = false, _dragging = false;
  double? _dragTop, _dragX;

  static const _size = 46.0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (store.uiInt('qa', 1) == 0) return const SizedBox.shrink();
    final c = context.c;
    return LayoutBuilder(builder: (context, box) {
      final pad = MediaQuery.of(context).padding;
      final minTop = pad.top + 70, maxTop = box.maxHeight - 210 - pad.bottom;
      final top = (_dragTop ?? (_y * box.maxHeight)).clamp(minTop, maxTop > minTop ? maxTop : minTop).toDouble();
      final toLeft = _dragX != null ? _dragX! < box.maxWidth / 2 : _left;
      void close() => setState(() => _open = false);
      void act(VoidCallback f) {
        close();
        f();
      }

      Widget icon(IconData i, String tip, VoidCallback onTap) => IconButton(tooltip: tip, onPressed: onTap, icon: Icon(i, color: c.textSecondary, size: 24));

      final pill = Material(
        color: c.surface,
        elevation: 6,
        shadowColor: Colors.black45,
        shape: StadiumBorder(side: BorderSide(color: c.separator)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const ThemeToggleButton(),
            icon(Icons.search_rounded, 'Search', () => act(widget.onSearch)),
            icon(Icons.home_rounded, 'Home', () => act(widget.onHome)),
            icon(Icons.settings_rounded, 'Settings', () => act(widget.onSettings)),
            icon(Icons.close_rounded, 'Close', close),
          ]),
        ),
      );
      final bubble = Opacity(
        opacity: _dragging ? 0.95 : 0.62,
        child: Material(
          color: c.surface,
          elevation: 4,
          shadowColor: Colors.black38,
          shape: CircleBorder(side: BorderSide(color: c.separator)),
          child: SizedBox(width: _size, height: _size, child: Icon(Icons.bolt_rounded, color: c.accent, size: 25)),
        ),
      );

      return Stack(children: [
        if (_open) Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: close, child: const SizedBox.expand())),
        AnimatedPositioned(
          duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          top: top,
          left: toLeft ? 6 : null,
          right: toLeft ? null : 6,
          child: _open
              ? pill
              : GestureDetector(
                  onTap: () => setState(() => _open = true),
                  onPanStart: (_) => setState(() => _dragging = true),
                  onPanUpdate: (d) => setState(() {
                    _dragTop = (_dragTop ?? top) + d.delta.dy;
                    _dragX = (_dragX ?? (toLeft ? 6 + _size / 2 : box.maxWidth - 6 - _size / 2)) + d.delta.dx;
                  }),
                  onPanEnd: (_) {
                    final y = ((_dragTop ?? top) / box.maxHeight).clamp(0.05, 0.95);
                    final left = (_dragX ?? 0) < box.maxWidth / 2;
                    context.read<AppStore>()
                      ..setUiInt('qaY', (y * 100).round())
                      ..setUiInt('qaLeft', left ? 1 : 0);
                    setState(() {
                      _y = y;
                      _left = left;
                      _dragging = false;
                      _dragTop = null;
                      _dragX = null;
                    });
                  },
                  child: bubble,
                ),
        ),
      ]);
    });
  }
}
