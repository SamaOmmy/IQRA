import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:window_manager/window_manager.dart';

import '../core/audio.dart';
import '../core/notify.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/updates.dart';
import 'discover/discover.dart';
import 'gradients.dart';
import 'library.dart';
import 'listen.dart';
import 'welcome.dart';
import 'player.dart';
import 'read.dart';
import 'search.dart';
import 'settings.dart';
import 'theme_wave.dart';
import 'quick_access.dart';
import 'update_banner.dart';
import 'today.dart';
import 'tools/tools.dart';
import 'window_controls.dart';
import 'widgets.dart';

/// How many readers are open: while the Qur'an is on screen on a phone, the tab bar and mini player slide away so the last lines are never covered.
final ValueNotifier<int> readerOpen = ValueNotifier(0);

enum Section { today, read, listen, discover, tools, library, search, settings }

const _meta = <Section, (String, IconData, IconData)>{
  Section.today: ('Today', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
  Section.read: ('Read', Icons.auto_stories_outlined, Icons.auto_stories_rounded),
  Section.listen: ('Listen', Icons.headphones_outlined, Icons.headphones_rounded),
  Section.discover: ('Discover', Icons.explore_outlined, Icons.explore_rounded),
  Section.tools: ('Tools', Icons.apps_outlined, Icons.apps_rounded),
  Section.library: ('Library', Icons.bookmarks_outlined, Icons.bookmarks_rounded),
  Section.search: ('Search', Icons.search_rounded, Icons.search_rounded),
  Section.settings: ('Settings', Icons.settings_outlined, Icons.settings_rounded),
};

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  static AppShellState? of(BuildContext context) => context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> with WindowListener, SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static AppShellState? current;
  BuildContext? get navContext => _keys[_section]!.currentState?.overlay?.context;
  late final AppStore _store;
  String _notifySig = '';
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    current = this;
    WidgetsBinding.instance.addObserver(this);
    _store = context.read<AppStore>();
    // reopen the section that was open last time
    final savedSection = _store.uiStr('section');
    for (final sec in const [Section.read, Section.listen, Section.discover, Section.tools, Section.library]) {
      if (sec.name == savedSection) {
        _section = sec;
        _visited.add(sec);
      }
    }
    // people who already use the app skip the welcome
    if (!_store.seenWelcome) {
      if (_store.hasStartedReading || _store.place != null) {
        _store.seenWelcome = true;
      } else {
        _showWelcome = true;
      }
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) windowManager.addListener(this);
    _store.addListener(_syncNotifications);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrayerNotifier.init().then((_) => _syncNotifications());
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted && !_showWelcome) _warm();
      });
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) context.read<UpdateChecker>().check();
      });
      // a PC app can stay open for days: look again every half hour (the check itself skips if it was done more recently)
      _updateTimer = Timer.periodic(const Duration(minutes: 30), (_) {
        if (mounted) context.read<UpdateChecker>().checkIfStale();
      });
    });
  }

  // look for an update again when the app comes back to the front
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<UpdateChecker>().checkIfStale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_syncNotifications);
    _fade.dispose();
    _warmTimer?.cancel();
    _updateTimer?.cancel();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) windowManager.removeListener(this);
    super.dispose();
  }

  // Reschedule prayer reminders whenever what they depend on changes.
  void _syncNotifications() {
    final p = _store.place;
    final sig = '${_store.notifyPrayers}|${p?.name}|${_store.prayerMethod}|${_store.hanafi}|${_store.dailyVerseAt}|${_store.adhan}|${_store.alertPrayers.join(',')}|${_store.prayerAdjust}|${p?.lat}|${todayKey()}';
    if (sig == _notifySig) return;
    _notifySig = sig;
    PrayerNotifier.reschedule(_store);
  }

  Future<void> _saveBounds() async {
    final b = await windowManager.getBounds();
    if (await windowManager.isMaximized()) return;
    _store.saveWindowRect([b.left, b.top, b.width, b.height]);
  }

  // the window brought to the front: the moment a person would notice a new version
  @override
  void onWindowFocus() => context.read<UpdateChecker>().checkIfStale();
  @override
  void onWindowMaximize() => _store.setUiInt('winMax', 1); // reopened maximised if it was left that way
  @override
  void onWindowUnmaximize() => _store.setUiInt('winMax', 0);
  @override
  void onWindowResized() => _saveBounds();
  @override
  void onWindowMoved() => _saveBounds();

  Section _section = Section.today;
  final _keys = {for (final s in Section.values) s: GlobalKey<NavigatorState>()};
  final _visited = <Section>{Section.today};

  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  Timer? _warmTimer, _updateTimer;

  /// Builds the other sections one at a time while the app is idle, so opening one later does not have to build it while it
  /// animates in (that first build is what made opening a page stutter).
  void _warm() {
    const order = [Section.read, Section.listen, Section.discover, Section.library, Section.tools, Section.search, Section.settings];
    var i = 0;
    _warmTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted || i >= order.length) {
        t.cancel();
        return;
      }
      final s = order[i++];
      if (!_visited.contains(s)) setState(() => _visited.add(s));
    });
  }

  void go(Section s) {
    if (s == _section) {
      _keys[s]!.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _section = s;
      _visited.add(s);
    });
    if (s != Section.search && s != Section.settings) _store.setUiStr('section', s.name);
    if (_store.motion) _fade.forward(from: 0);
  }

  Widget _root(Section s) => switch (s) {
        Section.today => const TodayScreen(),
        Section.read => const ReadScreen(),
        Section.listen => const ListenScreen(),
        Section.discover => const DiscoverScreen(),
        Section.tools => const ToolsScreen(),
        Section.library => const LibraryScreen(),
        Section.search => const SearchScreen(),
        Section.settings => const SettingsScreen(),
      };

  Widget _body() {
    final stack = IndexedStack(
      index: Section.values.indexOf(_section),
      children: [
        for (final s in Section.values)
          if (_visited.contains(s))
            Navigator(
              key: _keys[s],
              onGenerateRoute: (_) => PageRouteBuilder(pageBuilder: (_, __, ___) => _root(s), transitionDuration: Duration.zero),
            )
          else
            const SizedBox.shrink(),
      ],
    );
    final curve = CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(position: Tween(begin: const Offset(0, 0.012), end: Offset.zero).animate(curve), child: RepaintBoundary(child: stack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) return WelcomeFlow(onDone: () => setState(() => _showWelcome = false));
    context.watch<AppStore>(); // rebuild when the sidebar is collapsed or expanded
    final wide = MediaQuery.of(context).size.width >= 860;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[_section]!.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_section != Section.today) {
          setState(() => _section = Section.today);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final focused = FocusManager.instance.primaryFocus?.context;
          final typing = focused != null && (focused.widget is EditableText || focused.findAncestorWidgetOfExactType<EditableText>() != null);
          if (typing) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.keyB && HardwareKeyboard.instance.isControlPressed) {
            _store.sidebarCollapsed = !_store.sidebarCollapsed;
            return KeyEventResult.handled;
          }
          final audio = context.read<AudioController>();
          if (e.logicalKey == LogicalKeyboardKey.space && audio.active) {
            audio.toggle();
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
            audio.toggle();
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
            audio.next();
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
            audio.previous();
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.slash) {
            go(Section.search);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: wide ? _desktop() : _mobile(),
      ),
    );
  }

  Widget _desktop() {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: Row(children: [
        _Sidebar(current: _section, onSelect: go, collapsed: _store.sidebarCollapsed, onToggle: () => _store.sidebarCollapsed = !_store.sidebarCollapsed),
        Container(width: 0.6, color: c.separator),
        Expanded(
          child: Column(children: [
            const _TopBar(),
            Container(height: 0.6, color: c.separator),
            if (_section != Section.today) const UpdateBanner(), // Today has its own, larger one
            Expanded(child: _body()),
          ]),
        ),
      ]),
    );
  }

  Widget _mobile() {
    final c = context.c;
    const tabs = [Section.today, Section.read, Section.listen, Section.discover, Section.library];
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        Positioned.fill(child: _body()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<int>(
            valueListenable: readerOpen,
            builder: (context, open, child) => IgnorePointer(
              ignoring: open > 0,
              child: AnimatedSlide(offset: open > 0 ? const Offset(0, 1.2) : Offset.zero, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic, child: child),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_section != Section.today) const UpdateBanner(),
            const MiniPlayer(),
            Glass(
              blur: 30,
              opacity: 0.86,
              child: Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.separator, width: 0.6))),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 58,
                    child: Row(children: [
                      for (final s in tabs)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => go(s),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  _section == s ? _meta[s]!.$3 : _meta[s]!.$2,
                                  key: ValueKey(_section == s),
                                  size: 25,
                                  color: _section == s ? c.accent : c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(_meta[s]!.$1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _section == s ? c.accent : c.textSecondary)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
          ),
        ),
        Positioned.fill(child: QuickAccess(onSearch: () => go(Section.search), onHome: () => go(Section.today), onSettings: () => go(Section.settings))),
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onSelect, required this.collapsed, required this.onToggle});
  final Section current;
  final ValueChanged<Section> onSelect;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget item(Section s) {
      final sel = current == s;
      final icon = Icon(sel ? _meta[s]!.$3 : _meta[s]!.$2, size: 21, color: sel ? c.accent : c.text);
      final body = Pressable(
        onTap: () => onSelect(s),
        radius: 9,
        scale: 0.985,
        hover: !sel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 9),
          alignment: collapsed ? Alignment.center : Alignment.centerLeft,
          decoration: BoxDecoration(color: sel ? c.accent.withValues(alpha: c.dark ? 0.24 : 0.14) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
          child: collapsed
              ? icon
              : Row(children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: Text(_meta[s]!.$1, maxLines: 1, overflow: TextOverflow.clip, style: TextStyle(fontSize: 14.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? c.accent : c.text))),
                ]),
        ),
      );
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12, vertical: 1.5),
        child: collapsed ? Tooltip(message: _meta[s]!.$1, preferBelow: false, child: body) : body,
      );
    }

    final logo = GradientBox(
      width: 30,
      height: 30,
      colors: [c.accent, c.accent.withValues(alpha: 0.7)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      radius: 8,
      child: Center(child: Text('ق', style: TextStyle(fontFamily: kArabicFont, fontSize: 20, color: c.onAccent, height: 1.1))),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: collapsed ? 68 : 244,
      color: c.sidebar,
      clipBehavior: Clip.hardEdge,
      decoration: null,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        maxWidth: collapsed ? 68 : 244,
        child: Column(children: [
          const DragToMoveArea(child: SizedBox(height: 14, width: double.infinity)),
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 0 : 16, 4, collapsed ? 0 : 6, 12),
            child: collapsed
                ? Column(children: [
                    logo,
                    const SizedBox(height: 10),
                    IconButton(tooltip: 'Show sidebar', onPressed: onToggle, icon: Icon(Icons.keyboard_double_arrow_right_rounded, color: c.textSecondary, size: 22)),
                  ])
                : Row(children: [
                    logo,
                    const SizedBox(width: 10),
                    const Expanded(child: Text('IQRA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
                    IconButton(tooltip: 'Hide sidebar', onPressed: onToggle, icon: Icon(Icons.keyboard_double_arrow_left_rounded, color: c.textSecondary, size: 22)),
                  ]),
          ),
          if (collapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tooltip(
                message: 'Search',
                preferBelow: false,
                child: IconButton(onPressed: () => onSelect(Section.search), icon: Icon(Icons.search_rounded, color: c.textSecondary)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Pressable(
                onTap: () => onSelect(Section.search),
                radius: 10,
                hover: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: c.bg.withValues(alpha: c.dark ? 0.35 : 0.8), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.separator)),
                  child: Row(children: [
                    Icon(Icons.search_rounded, size: 19, color: c.textSecondary),
                    const SizedBox(width: 8),
                    Text('Search', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  ]),
                ),
              ),
            ),
          item(Section.today),
          item(Section.read),
          item(Section.listen),
          item(Section.discover),
          item(Section.tools),
          if (collapsed)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: Container(height: 0.8, color: c.separator))
          else
            const Padding(padding: EdgeInsets.fromLTRB(24, 18, 12, 6), child: Align(alignment: Alignment.centerLeft, child: _GroupLabel('Library'))),
          item(Section.library),
          const Spacer(),
          // light / dark at a press, the wave starts from here
          Padding(
            padding: EdgeInsets.only(left: collapsed ? 0 : 12, bottom: 2),
            child: Align(alignment: collapsed ? Alignment.center : Alignment.centerLeft, child: const ThemeToggleButton()),
          ),
          item(Section.settings),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: context.c.textSecondary));
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(children: [
        const Positioned.fill(child: DragToMoveArea(child: SizedBox.expand())),
        const Center(child: DesktopNowPlaying()),
        if (Platform.isWindows) const Positioned(right: 0, top: 0, child: WindowButtons()),
      ]),
    );
  }
}
