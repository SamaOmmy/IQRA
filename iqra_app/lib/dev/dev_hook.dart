import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../ui/discover/lists.dart';
import '../ui/discover/story_screen.dart';
import '../ui/player.dart';
import '../ui/reader.dart';
import '../ui/shell.dart';
import '../core/audio.dart';
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
      case 'now':
        if (ctx != null) await showNowPlaying(ctx);
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
