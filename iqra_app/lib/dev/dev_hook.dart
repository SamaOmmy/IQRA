import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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
  static Timer? _t;
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);

  static void start(GlobalKey repaintKey) {
    if (!kDebugMode) return;
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
      case 'flip':
        ReaderDebug.flip(int.parse(p[1]), int.parse(p[2]));
      case 'wait':
        await Future<void>.delayed(Duration(milliseconds: int.parse(p[1])));
      case 'status':
        if (ctx != null) {
          final au = ctx.read<AudioController>();
          debugPrint('DEV audio: ${au.current?.s}:${au.current?.a} connected=${au.connected} playing=${au.playing} loading=${au.loading} pos=${au.position} dur=${au.duration} err=${au.error}');
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
