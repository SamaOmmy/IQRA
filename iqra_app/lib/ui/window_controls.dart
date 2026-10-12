import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/theme.dart';

/// Minimise, maximise and close for the frameless Windows window.
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget btn(IconData icon, VoidCallback onTap, {bool close = false}) => WinBtn(icon: icon, onTap: onTap, close: close, color: color ?? c.text);
    return Row(children: [
      btn(Icons.remove_rounded, () => windowManager.minimize()),
      btn(Icons.crop_square_rounded, () async => await windowManager.isMaximized() ? windowManager.unmaximize() : windowManager.maximize()),
      btn(Icons.close_rounded, () => windowManager.close(), close: true),
    ]);
  }
}

class WinBtn extends StatefulWidget {
  const WinBtn({required this.icon, required this.onTap, required this.close, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final bool close;
  final Color color;

  @override
  State<WinBtn> createState() => WinBtnState();
}

class WinBtnState extends State<WinBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 34,
          color: _h ? (widget.close ? const Color(0xFFE81123) : widget.color.withValues(alpha: 0.1)) : Colors.transparent,
          child: Icon(widget.icon, size: 17, color: _h && widget.close ? Colors.white : widget.color),
        ),
      ),
    );
  }
}
