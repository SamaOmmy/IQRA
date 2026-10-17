import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'gradients.dart';

/// The mushaf as a book. A turning leaf swings about the spine with perspective and shading, and shows its back while it
/// lands, like paper. On wide windows two pages lie open side by side (the odd page on the right, as in an Arabic book);
/// on narrow ones a single page lifts from its left edge to reveal the next.
///
/// A "sheet" is one spread (pages 2i+1 and 2i+2) when [spread] is set, otherwise one page (page i+1).
/// Pages taller than the window scroll up and down inside the book (see the page size setting).
class BookFlip extends StatefulWidget {
  const BookFlip({
    super.key,
    required this.index,
    required this.count,
    required this.spread,
    required this.pageW,
    required this.pageH,
    required this.viewH,
    required this.page,
    required this.onChanged,
    this.motion = true,
  });

  final int index, count;
  final bool spread;
  final double pageW, pageH, viewH;

  /// Builds one page (1-based page number) at [pageW] x [pageH].
  final Widget Function(int page) page;
  final ValueChanged<int> onChanged;
  final bool motion;

  @override
  State<BookFlip> createState() => BookFlipState();
}

class BookFlipState extends State<BookFlip> with SingleTickerProviderStateMixin {
  late int _idx = widget.index;
  late int _to = widget.index; // the sheet being turned to (equal to _idx when still)
  late final AnimationController _ac = AnimationController(vsync: this);
  double _vy = 0;
  bool _drag = false;
  Axis? _axis;
  double _sx = 0, _sy = 0;
  AnimationController? _scroller;

  bool get _turning => _to != _idx;

  /// The sheet shown, or the one being turned to.
  int get target => _to;
  int get index => _idx;

  @override
  void didUpdateWidget(covariant BookFlip old) {
    super.didUpdateWidget(old);
    if (!_turning && !_drag && widget.index != _idx) {
      _idx = _to = widget.index.clamp(0, widget.count - 1);
      _vy = 0;
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    _scroller?.dispose();
    super.dispose();
  }

  double get _maxVy => math.max(0.0, widget.pageH - widget.viewH);

  /// Turns to [index] with the page-turn animation.
  void turnTo(int index, {Duration duration = const Duration(milliseconds: 700), Curve curve = Curves.easeInOutCubic}) {
    index = index.clamp(0, widget.count - 1);
    if (_turning) _finish();
    if (index == _idx) return;
    if (!widget.motion) {
      jumpTo(index);
      return;
    }
    setState(() => _to = index);
    _ac.value = 0;
    _ac.animateTo(1, duration: duration, curve: curve).whenComplete(() {
      if (mounted && !_drag && _turning) _finish();
    });
  }

  /// Shows [index] at once.
  void jumpTo(int index) {
    index = index.clamp(0, widget.count - 1);
    _ac.stop();
    final changed = index != _idx;
    setState(() {
      _idx = _to = index;
      _ac.value = 0;
      if (changed) _vy = 0;
    });
    if (changed) widget.onChanged(index);
  }

  void _finish() {
    final to = _to;
    _ac.stop();
    setState(() {
      _idx = to;
      _ac.value = 0;
      _vy = 0;
    });
    widget.onChanged(to);
  }

  /// Scrolls a tall page so that the given fraction (0 top .. 1 bottom) of it sits a little above the middle of the window.
  void scrollToFraction(double f, {bool animate = true}) {
    final max = _maxVy;
    if (max <= 0) return;
    final goal = (f * widget.pageH - widget.viewH * 0.4).clamp(0.0, max);
    if (!animate || !widget.motion) {
      setState(() => _vy = goal);
      return;
    }
    _scroller?.dispose();
    final from = _vy;
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scroller = c;
    final curve = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    curve.addListener(() {
      if (mounted) setState(() => _vy = from + (goal - from) * curve.value);
    });
    c.forward();
  }

  // ---------------- gestures ----------------
  void _onStart(DragStartDetails d) {
    _axis = null;
    _sx = _sy = 0;
    _scroller?.stop();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_turning && !_drag) return; // an animated turn is on its way
    _sx += d.delta.dx;
    _sy += d.delta.dy;
    if (_axis == null) {
      if (_sx.abs() + _sy.abs() < 10) return;
      _axis = _sx.abs() > _sy.abs() ? Axis.horizontal : Axis.vertical;
      if (_axis == Axis.vertical && _maxVy <= 0) return;
    }
    if (_axis == Axis.vertical) {
      setState(() => _vy = (_vy - d.delta.dy).clamp(0.0, _maxVy));
      return;
    }
    // dragging to the right turns forward (pages run right to left)
    final dir = _sx > 0 ? 1 : -1;
    final to = _idx + dir;
    if (to < 0 || to >= widget.count) {
      if (_turning) setState(() => _to = _idx);
      return;
    }
    final travel = widget.pageW * (widget.spread ? 1.5 : 0.9);
    _drag = true;
    setState(() {
      _to = to;
      _ac.value = (_sx.abs() / travel).clamp(0.0, 1.0);
    });
  }

  void _onEnd(DragEndDetails d) {
    final axis = _axis;
    _axis = null;
    if (axis != Axis.horizontal || !_drag) return;
    _drag = false;
    if (!_turning) return;
    final fwd = _to > _idx;
    final v = d.velocity.pixelsPerSecond.dx * (fwd ? 1 : -1);
    final done = v > 600 || (_ac.value > 0.4 && v > -600);
    final left = done ? 1 - _ac.value : _ac.value;
    final ms = (140 + 420 * left).round();
    if (done) {
      _ac.animateTo(1, duration: Duration(milliseconds: ms), curve: Curves.easeOutCubic).whenComplete(() {
        if (mounted && _turning) _finish();
      });
    } else {
      _ac.animateTo(0, duration: Duration(milliseconds: ms), curve: Curves.easeOutCubic).whenComplete(() {
        if (mounted) setState(() => _to = _idx);
      });
    }
  }

  void _onSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent && _maxVy > 0 && !_turning) {
      setState(() => _vy = (_vy + e.scrollDelta.dy).clamp(0.0, _maxVy));
    }
  }

  // ---------------- drawing ----------------
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final W = w.pageW, H = w.pageH;
    Widget pg(int p) => RepaintBoundary(
          child: (p >= 1 && p <= 604) ? SizedBox(width: W, height: H, child: w.page(p)) : SizedBox(width: W, height: H),
        );

    final cur = _idx, to = _to;
    final pages = <String, Widget>{};
    if (w.spread) {
      pages['cr'] = pg(cur * 2 + 1);
      pages['cl'] = pg(cur * 2 + 2);
      if (_turning) {
        pages['tr'] = pg(to * 2 + 1);
        pages['tl'] = pg(to * 2 + 2);
      }
    } else {
      pages['c'] = pg(cur + 1);
      if (_turning) pages['t'] = pg(to + 1);
    }

    final bookW = w.spread ? W * 2 : W;
    final maxVy = _maxVy;
    final vy = _vy.clamp(0.0, maxVy);

    final book = Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) => _book(pages, W, H),
      ),
    );

    return Listener(
      onPointerSignal: _onSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onStart,
        onPanUpdate: _onUpdate,
        onPanEnd: _onEnd,
        child: SizedBox.expand(
          child: Center(
            child: ClipRect(
              child: SizedBox(
                width: bookW,
                height: w.viewH,
                child: Stack(children: [
                  Positioned.fill(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: H,
                      maxHeight: H,
                      minWidth: bookW,
                      maxWidth: bookW,
                      child: Transform.translate(offset: Offset(0, -vy), child: IgnorePointer(ignoring: _turning, child: book)),
                    ),
                  ),
                  if (maxVy > 0)
                    Positioned(
                      right: 3,
                      top: 6 + (w.viewH - 12 - _thumb(w)) * (vy / maxVy),
                      child: IgnorePointer(child: Container(width: 4, height: _thumb(w), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(4)))),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _thumb(BookFlip w) => math.max(36.0, (w.viewH - 12) * w.viewH / w.pageH);

  Widget _shade(double a) => Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: a.clamp(0.0, 1.0)))));

  Widget _book(Map<String, Widget> p, double W, double H) {
    final perspective = 0.32 / W;
    Matrix4 turn(double angle) => Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateY(angle);
    Widget leaf({required Widget front, required Widget back, required double theta, required bool fromLeft, required double slot}) {
      final showBack = theta > math.pi / 2;
      final s = math.sin(theta);
      final face = showBack ? Transform.flip(flipX: true, child: Stack(fit: StackFit.passthrough, children: [back, _shade(0.30 * s)])) : Stack(fit: StackFit.passthrough, children: [front, _shade(0.38 * s)]);
      return Positioned(
        left: slot,
        top: 0,
        width: W,
        height: H,
        child: Transform(
          alignment: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
          transform: turn(fromLeft ? -theta : theta),
          child: face,
        ),
      );
    }

    // a soft shadow along the spine
    Widget spine() => Positioned(
          left: W - 14,
          top: 0,
          width: 28,
          height: H,
          child: IgnorePointer(
            child: CustomPaint(
              painter: GradientPainter.linear([Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            ),
          ),
        );

    final t = _ac.value;
    if (widget.spread) {
      if (!_turning) {
        return Stack(children: [
          Positioned(left: 0, top: 0, child: p['cl']!),
          Positioned(left: W, top: 0, child: p['cr']!),
          spine(),
        ]);
      }
      final fwd = _to > _idx;
      final theta = math.pi * t;
      final s = math.sin(theta);
      if (fwd) {
        // the left page lifts over the spine and lands on the right: its back is the new right page
        return Stack(children: [
          Positioned(left: 0, top: 0, child: p['tl']!),
          Positioned(left: W, top: 0, child: p['cr']!),
          _under(W, H, left: W, alpha: 0.28 * s),
          leaf(front: p['cl']!, back: p['tr']!, theta: theta, fromLeft: true, slot: 0),
          spine(),
        ]);
      }
      return Stack(children: [
        Positioned(left: 0, top: 0, child: p['cl']!),
        Positioned(left: W, top: 0, child: p['tr']!),
        _under(W, H, left: 0, alpha: 0.28 * s),
        leaf(front: p['cr']!, back: p['tl']!, theta: theta, fromLeft: false, slot: W),
        spine(),
      ]);
    }

    // a single page: it lifts from its left edge about the spine on the right, and the next page is beneath
    if (!_turning) return Stack(children: [Positioned(left: 0, top: 0, child: p['c']!)]);
    final fwd = _to > _idx;
    final theta = (math.pi / 2) * (fwd ? t : 1 - t);
    return Stack(children: [
      Positioned(left: 0, top: 0, child: fwd ? p['t']! : p['c']!),
      _under(W, H, left: 0, alpha: 0.30 * math.sin(theta)),
      leaf(front: fwd ? p['c']! : p['t']!, back: const SizedBox(), theta: theta, fromLeft: true, slot: 0),
    ]);
  }

  /// The shadow cast by the turning leaf on the page below it.
  Widget _under(double W, double H, {required double left, required double alpha}) => Positioned(
        left: left,
        top: 0,
        width: W,
        height: H,
        child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: alpha.clamp(0.0, 1.0)))),
      );
}
