import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/content.dart';
import '../ui/discover/discover_widgets.dart';
import '../ui/discover/lists.dart';
import '../ui/downloads_screen.dart';
import '../ui/plan_screen.dart';
import '../ui/review_screen.dart';
import '../ui/share_card.dart';
import '../ui/settings.dart';
import '../ui/tools/city_picker.dart';
import '../ui/tools/prayer_screen.dart';
import '../ui/tools/qibla_screen.dart';
import '../ui/tools/tools.dart';
import '../ui/welcome.dart';
import '../ui/discover/story_screen.dart';
import '../ui/player.dart';
import '../ui/reader.dart';
import '../ui/shell.dart';
import 'package:window_manager/window_manager.dart';
import '../core/audio.dart';
import '../core/store.dart';
import 'package:provider/provider.dart';

/// Debug builds only: lets a developer script drive the app and save screenshots of the app's own pixels.
/// Commands are read (one per line) from `iqra-dev.cmd` in the system temp folder.
///   go today|read|discover|tools|library|search|settings
///   reader <surah> <ayah> mushaf|verses [page]
///   story <id>        shelf <id>     guide <id>     now
///   play <surah> <ayah>
///   shot <name>       -> iqra-<name>.png in the temp folder
///   back
class DevHook {
  // ignore: unused_field
  static Timer? _t;
  static final List<ui.FrameTiming> _frames = [];
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);

  static void start(GlobalKey repaintKey) {
    if (!kDebugMode && !kProfileMode) return;
    SchedulerBinding.instance.addTimingsCallback((t) => _frames.addAll(t));
    final dir = Directory.systemTemp.path;
    final cmd = File('$dir${Platform.pathSeparator}iqra-dev.cmd');
    _t = Timer.periodic(const Duration(milliseconds: 600), (_) async {
      if (!cmd.existsSync()) return;
      final lines = cmd.readAsLinesSync();
      cmd.deleteSync();
      for (final line in lines) {
        final p = line.trim().split(RegExp(r'\s+'));
        if (p.isEmpty || p.first.isEmpty) continue;
        try {
          await _run(p, repaintKey, dir);
        } catch (e) {
          debugPrint('DEV command failed: $line -> $e');
        }
      }
    });
  }

  static Future<void> _run(List<String> p, GlobalKey key, String dir) async {
    final shell = AppShellState.current;
    final ctx = shell?.navContext;
    switch (p[0]) {
      case 'go':
        shell?.go(Section.values.firstWhere((s) => s.name == p[1]));
      case 'reader':
        if (ctx != null) openReader(ctx, surah: int.parse(p[1]), ayah: int.parse(p[2]), mushaf: p[3] == 'mushaf', page: p.length > 4 ? int.parse(p[4]) : null);
      case 'story':
        if (ctx != null) openStory(ctx, p[1]);
      case 'shelf':
        if (ctx != null) Navigator.of(ctx).push(WidgetsPageRoute(ShelfScreen(id: p[1])));
      case 'play':
        if (ctx != null) await ctx.read<AudioController>().playVerse(int.parse(p[1]), int.parse(p[2]));
      case 'tap':
        {
          final pos = Offset(double.parse(p[1]), double.parse(p[2]));
          final id = 900 + DateTime.now().millisecond;
          GestureBinding.instance.handlePointerEvent(PointerAddedEvent(position: pos));
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(position: pos, pointer: id));
          await Future<void>.delayed(const Duration(milliseconds: 90));
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(position: pos, pointer: id));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      case 'scroll':
        {
          final pos = Offset(double.parse(p[1]), double.parse(p[2]));
          GestureBinding.instance.handlePointerEvent(PointerScrollEvent(position: pos, scrollDelta: Offset(0, double.parse(p[3]))));
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      case 'perf':
        {
          if (p[1] == 'reset') {
            _frames.clear();
          } else {
            // perf report <label>: how the frames since the last reset went (profile builds give real numbers)
            final ms = [for (final f in _frames) f.totalSpan.inMicroseconds / 1000]..sort();
            final build = [for (final f in _frames) f.buildDuration.inMicroseconds / 1000]..sort();
            final raster = [for (final f in _frames) f.rasterDuration.inMicroseconds / 1000]..sort();
            double pct(List<double> l, double q) => l.isEmpty ? 0 : l[((l.length - 1) * q).round()];
            final over = ms.where((m) => m > 16.7).length, over33 = ms.where((m) => m > 33.4).length;
            final out = 'frames=${ms.length} total avg=${ms.isEmpty ? 0 : (ms.reduce((a, b) => a + b) / ms.length).toStringAsFixed(1)} p90=${pct(ms, .9).toStringAsFixed(1)} p99=${pct(ms, .99).toStringAsFixed(1)} max=${pct(ms, 1).toStringAsFixed(1)} | build p90=${pct(build, .9).toStringAsFixed(1)} max=${pct(build, 1).toStringAsFixed(1)} | raster p90=${pct(raster, .9).toStringAsFixed(1)} max=${pct(raster, 1).toStringAsFixed(1)} | >16.7ms: $over  >33ms: $over33';
            File('$dir${Platform.pathSeparator}iqra-perf-${p.length > 2 ? p[2] : 'x'}.txt').writeAsStringSync(out);
          }
        }
      case 'fling':
        {
          // fling x y step count: a run of mouse-wheel notches 16 ms apart
          final pos = Offset(double.parse(p[1]), double.parse(p[2]));
          for (var i = 0; i < int.parse(p[4]); i++) {
            GestureBinding.instance.handlePointerEvent(PointerScrollEvent(position: pos, scrollDelta: Offset(0, double.parse(p[3]))));
            await Future<void>.delayed(const Duration(milliseconds: 30));
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      case 'drag':
        {
          // drag x1 y1 x2 y2: a finger down, moved in steps, and lifted
          final a0 = Offset(double.parse(p[1]), double.parse(p[2])), b0 = Offset(double.parse(p[3]), double.parse(p[4]));
          final id = 700 + DateTime.now().millisecond;
          GestureBinding.instance.handlePointerEvent(PointerAddedEvent(position: a0));
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(position: a0, pointer: id));
          for (var i = 1; i <= 12; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
            final pos = Offset.lerp(a0, b0, i / 12)!;
            GestureBinding.instance.handlePointerEvent(PointerMoveEvent(position: pos, pointer: id, delta: (b0 - a0) / 12));
          }
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(position: b0, pointer: id));
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
      case 'reciter':
        if (ctx != null) ctx.read<AppStore>().reciter = p[1];
      case 'bg':
        await windowManager.setBackgroundColor(Color(int.parse(p[1], radix: 16)));
      case 'flip':
        ReaderDebug.flip(int.parse(p[1]), int.parse(p[2]));
      case 'wait':
        await Future<void>.delayed(Duration(milliseconds: int.parse(p[1])));
      case 'status':
        if (ctx != null) {
          final au = ctx.read<AudioController>();
          debugPrint('DEV audio: ${au.current?.s}:${au.current?.a} connected=${au.connected} playing=${au.playing} loading=${au.loading} pos=${au.position} dur=${au.duration} err=${au.error} raw=${au.player.state.position} buffering=${au.player.state.buffering} rawdur=${au.player.state.duration} bufpos=${au.player.state.buffer}');
        }
      case 'seekverse':
        if (ctx != null) await ctx.read<AudioController>().playVerse(int.parse(p[1]), int.parse(p[2]), scope: PlayScope.continuous);
      case 'now':
        if (ctx != null) unawaited(showNowPlaying(ctx));
      case 'size':
        await windowManager.setSize(Size(double.parse(p[1]), double.parse(p[2])));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      case 'scale':
        textScale.value = double.parse(p[1]);
      case 'theme':
        if (ctx != null) ctx.read<AppStore>().theme = p[1];
      case 'accent':
        if (ctx != null) ctx.read<AppStore>().accent = int.parse(p[1]);
      case 'open':
        if (ctx != null) {
          final w = switch (p[1]) {
            'plan' => const PlanScreen(),
            'downloads' => const DownloadsScreen(),
            'prayer' => const PrayerScreen(),
            'qibla' => const QiblaScreen(),
            'nawawi' => const NawawiScreen(),
            'hadith' => const HadithScreen(),
            'settings' => const SettingsScreen(),
            'tasbih' => const TasbihScreen(),
            'calendar' => const CalendarScreen(),
            'salah' => const SalahScreen(),
            'quiz' => const QuizScreen(),
            'zakat' => const ZakatScreen(),
            'welcome' => WelcomeFlow(onDone: () => Navigator.of(ctx).maybePop()),
            _ => null,
          };
          if (w != null) Navigator.of(ctx).push(WidgetsPageRoute(w));
        }
      case 'hadithdetail':
        if (ctx != null) openHadith(ctx, Content.I.hadith[int.parse(p[1])] as Map<String, dynamic>);
      case 'citypicker':
        if (ctx != null) pickCity(ctx);
      case 'sharecard':
        if (ctx != null) showShareCard(ctx, arabic: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ', translation: '[All] praise is [due] to Allah, Lord of the worlds', reference: 'Al-Faatiha 1:2');
      case 'mem':
        if (ctx != null) ctx.read<AppStore>().toggleMemorised('${p[1]}:${p[2]}');
      case 'wbw':
        if (ctx != null) ctx.read<AppStore>().wordByWord = p[1] == 'on';
      case 'translit':
        if (ctx != null) ctx.read<AppStore>().transliteration = p[1] == 'on';
      case 'review':
        if (ctx != null) Navigator.of(ctx).push(WidgetsPageRoute(const ReviewScreen()));
      case 'pop':
        if (ctx != null) Navigator.of(ctx, rootNavigator: true).maybePop();
      case 'back':
        if (ctx != null) Navigator.of(ctx).maybePop();
      case 'shot':
        await Future<void>.delayed(const Duration(milliseconds: 900));
        final b = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (b == null) return;
        final img = await b.toImage(pixelRatio: 1.0);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dir${Platform.pathSeparator}iqra-${p[1]}.png').writeAsBytesSync(data!.buffer.asUint8List());
        debugPrint('DEV shot saved: iqra-${p[1]}.png');
    }
  }
}

class WidgetsPageRoute extends PageRouteBuilder<void> {
  WidgetsPageRoute(Widget w) : super(pageBuilder: (_, __, ___) => w, transitionDuration: const Duration(milliseconds: 200));
}
