import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:window_manager/window_manager.dart';

import 'core/audio.dart';
import 'core/content.dart';
import 'core/quran.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'core/translation.dart';
import 'dev/dev_hook.dart';
import 'ui/shell.dart';

final shotKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  tzdata.initializeTimeZones();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1240, 820),
      minimumSize: Size(420, 620),
      center: true,
      title: 'IQRA',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  DevHook.start(shotKey);
  final store = await AppStore.open();
  await Quran.I.load();
  await Content.I.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: store),
        ChangeNotifierProvider<AudioController>(create: (_) => AudioController(store)),
        ChangeNotifierProvider<TranslationModel>(create: (_) => TranslationModel(store)),
      ],
      child: const IqraApp(),
    ),
  );
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
      builder: (context, child) => RepaintBoundary(key: shotKey, child: child),
      home: const AppShell(),
    );
  }
}

class _Scroll extends MaterialScrollBehavior {
  const _Scroll();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}
