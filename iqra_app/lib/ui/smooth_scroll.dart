import 'package:flutter/material.dart';

/// A scroll controller whose mouse-wheel steps glide to their destination instead of jumping, and add up when the wheel is
/// turned quickly. Dragging and touch scrolling are untouched.
class SmoothScrollController extends ScrollController {
  SmoothScrollController({super.initialScrollOffset, super.keepScrollOffset, super.debugLabel});

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return _SmoothPosition(physics: physics, context: context, initialPixels: initialScrollOffset, keepScrollOffset: keepScrollOffset, oldPosition: oldPosition, debugLabel: debugLabel);
  }
}

class _SmoothPosition extends ScrollPositionWithSingleContext {
  _SmoothPosition({required super.physics, required super.context, super.initialPixels, super.keepScrollOffset, super.oldPosition, super.debugLabel});

  double? _goal;

  @override
  void pointerScroll(double delta) {
    if (delta == 0) {
      goBallistic(0);
      return;
    }
    final goal = ((_goal ?? pixels) + delta).clamp(minScrollExtent, maxScrollExtent).toDouble();
    if (goal == pixels) {
      _goal = null;
      return;
    }
    _goal = goal;
    animateTo(goal, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic).whenComplete(() => _goal = null);
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    // anything but our own glide (a drag, a fling) takes over
    if (newActivity is! DrivenScrollActivity) _goal = null;
    super.beginActivity(newActivity);
  }
}
