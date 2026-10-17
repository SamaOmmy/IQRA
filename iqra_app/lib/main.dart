import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:window_manager/window_manager.dart';

import 'core/audio.dart';
import 'core/content.dart';
import 'core/downloads.dart';
import 'core/quran.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'core/translation.dart';
import 'core/media_session.dart';
import 'core/updates.dart';
import 'dev/dev_hook.dart';
import 'ui/shell.dart';

final shotKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  tzdata.initializeTimeZones();

  final store = await AppStore.open();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    // reopen where the window was last, if that still makes sense
    final r = store.windowRect;
    final sane = r != null && r.length == 4 && r[2] >= 360 && r[3] >= 540 && r[2] < 8000 && r[3] < 5000 && r[0] > -4000 && r[1] > -2000;
    final options = WindowOptions(
      size: sane ? Size(r[2], r[3]) : const Size(1240, 820),
      minimumSize: const Size(340, 520),
      center: !sane,
      title: 'IQRA',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      if (sane) await windowManager.setPosition(Offset(r[0], r[1]));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  DevHook.start(shotKey);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('IQRA error: ${details.exceptionAsString()}');
  };
  runApp(Bootstrap(store: store));
}

/// Shows a calm splash while the Qur'an and content load, then the app.
class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key, required this.store});
  final AppStore store;

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late final Future<void> _ready = () async {
    await Quran.I.load();
    await Content.I.load();
  }();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _Splash(store: widget.store);
        if (snap.hasError) {
          return MaterialApp(home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('IQRA could not load its data: ${snap.error}')))));
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStore>.value(value: widget.store),
            ChangeNotifierProvider<AudioController>(
              create: (_) {
                final audio = AudioController(widget.store);
                IqraMediaSession.start(audio); // the notification and lock-screen controls on Android
                return audio;
              },
            ),
            ChangeNotifierProvider<TranslationModel>(create: (_) => TranslationModel(widget.store)),
            ChangeNotifierProvider<DownloadManager>(create: (_) => DownloadManager()),
            ChangeNotifierProvider<UpdateChecker>(create: (_) => UpdateChecker()),
          ],
          child: const IqraApp(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final system = MediaQuery.platformBrightnessOf(context);
    final colors = resolveTheme(store.theme, system).colors.withAccent(store.accent == 0 ? null : Color(store.accent));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: colors.bg,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.accent, colors.accent.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(24)),
              alignment: Alignment.center,
              child: Text('ق', style: TextStyle(fontFamily: 'OldMadina', fontSize: 56, color: colors.onAccent, height: 1.25, decoration: TextDecoration.none)),
            ),
            const SizedBox(height: 18),
            Text('IQRA', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4, color: colors.text, decoration: TextDecoration.none)),
          ]),
        ),
      ),
    );
  }
}

class IqraApp extends StatelessWidget {
  const IqraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final system = MediaQuery.platformBrightnessOf(context);
    final def = resolveTheme(store.theme, system);
    final colors = def.colors.withAccent(store.accent == 0 ? null : Color(store.accent));
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: colors.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: colors.bg,
      systemNavigationBarIconBrightness: colors.dark ? Brightness.light : Brightness.dark,
    ));
    return MaterialApp(
      title: 'IQRA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(colors),
      themeAnimationDuration: store.motion ? const Duration(milliseconds: 380) : Duration.zero,
      themeAnimationCurve: Curves.easeOut,
      scrollBehavior: const _Scroll(),
      builder: (context, child) => ValueListenableBuilder<double>(
        valueListenable: DevHook.textScale,
        builder: (context, scale, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // very large system fonts are capped so that fixed-size cards and rows keep their shape
            textScaler: TextScaler.linear((scale != 1 ? scale : MediaQuery.textScalerOf(context).scale(1.0)).clamp(0.85, 1.25).toDouble()),
          ),
          child: RepaintBoundary(key: shotKey, child: child),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class _Scroll extends MaterialScrollBehavior {
  const _Scroll();

  // the same soft, springy scrolling on every platform, and no stretch glow or scrollbars on phones
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => Platform.isAndroid ? child : super.buildScrollbar(context, child, details);
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}
