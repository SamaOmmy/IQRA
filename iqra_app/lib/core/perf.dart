import 'dart:ui' show FrameTiming, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'store.dart';

/// Keeps the app smooth on any screen. Time-based animations already run at whatever refresh rate the screen has; this adds
/// the other half: when a device keeps missing frames (an older phone, a slow graphics chip) the costly effects (live blur,
/// staggered reveals) are dropped by themselves, and Settings can force them on or off.
class Perf {
  static AppStore? _store;
  static bool _autoLight = false;
  static int _slow = 0, _seen = 0, _badWindows = 0;
  static final _started = DateTime.now();

  /// True when the costly effects should be skipped.
  static bool get light {
    final mode = _store?.effects ?? 0; // 0 automatic, 1 full, 2 light
    return mode == 2 || (mode == 0 && _autoLight);
  }

  /// Live background blur behind bars and panels: only on a computer, and only when Settings asks for Full effects. It forces the
  /// graphics chip to re-blur everything under a bar on every frame of a scroll, which is what makes scrolling scratch on modest hardware.
  static bool get glassBlur => (_store?.effects ?? 0) == 1 && !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  static void start(AppStore store) {
    _store = store;
    if (kDebugMode) return; // debug builds are always slow; measure the real thing
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (_autoLight || DateTime.now().difference(_started).inSeconds < 8) return; // start-up is always heavy
    final hz = PlatformDispatcher.instance.views.isEmpty ? 60.0 : (PlatformDispatcher.instance.views.first.display.refreshRate.clamp(30.0, 240.0));
    final budgetMs = 1000 / hz;
    final slowMs = budgetMs * 1.5 < 20 ? 20.0 : budgetMs * 1.5;
    for (final t in timings) {
      _seen++;
      if (t.totalSpan.inMicroseconds / 1000 > slowMs) _slow++;
      if (_seen >= 120) {
        _badWindows = _slow / _seen > 0.3 ? _badWindows + 1 : 0;
        _seen = _slow = 0;
        if (_badWindows >= 3) {
          _autoLight = true; // for the rest of this session
          _store?.notifyEffects();
          return;
        }
      }
    }
  }
}
