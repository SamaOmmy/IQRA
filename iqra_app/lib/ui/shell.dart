import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';
import 'package:window_manager/window_manager.dart';

import '../core/theme.dart';
import 'discover/discover.dart';
import 'library.dart';
import 'player.dart';
import 'read.dart';
import 'search.dart';
import 'settings.dart';
import 'today.dart';
import 'tools/tools.dart';
import 'window_controls.dart';
import 'widgets.dart';

enum Section { today, read, discover, tools, library, search, settings }

const _meta = <Section, (String, IconData, IconData)>{
  Section.today: ('Today', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
  Section.read: ('Read', Icons.auto_stories_outlined, Icons.auto_stories_rounded),
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

class AppShellState extends State<AppShell> {
  static AppShellState? current;
  BuildContext? get navContext => _keys[_section]!.currentState?.overlay?.context;

  @override
  void initState() {
    super.initState();
    current = this;
  }

  Section _section = Section.today;
  final _keys = {for (final s in Section.values) s: GlobalKey<NavigatorState>()};
  final _visited = <Section>{Section.today};

  void go(Section s) {
    if (s == _section) {
      _keys[s]!.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _section = s;
      _visited.add(s);
    });
  }

  Widget _root(Section s) => switch (s) {
        Section.today => const TodayScreen(),
        Section.read => const ReadScreen(),
        Section.discover => const DiscoverScreen(),
        Section.tools => const ToolsScreen(),
        Section.library => const LibraryScreen(),
        Section.search => const SearchScreen(),
        Section.settings => const SettingsScreen(),
      };

  Widget _body() {
    return IndexedStack(
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
  }

  @override
  Widget build(BuildContext context) {
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
        _Sidebar(current: _section, onSelect: go),
        Container(width: 0.6, color: c.separator),
        Expanded(
          child: Column(children: [
            const _TopBar(),
            Container(height: 0.6, color: c.separator),
            Expanded(child: _body()),
          ]),
        ),
      ]),
    );
  }

  Widget _mobile() {
    final c = context.c;
    const tabs = [Section.today, Section.read, Section.discover, Section.library, Section.search];
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        Positioned.fill(child: _body()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onSelect});
  final Section current;
  final ValueChanged<Section> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget item(Section s, {int index = 0}) {
      final sel = current == s;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1.5),
        child: Pressable(
          onTap: () => onSelect(s),
          radius: 9,
          scale: 0.985,
          hover: !sel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: sel ? c.accent.withValues(alpha: c.dark ? 0.24 : 0.14) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
            child: Row(children: [
              Icon(sel ? _meta[s]!.$3 : _meta[s]!.$2, size: 21, color: sel ? c.accent : c.text),
              const SizedBox(width: 12),
              Text(_meta[s]!.$1, style: TextStyle(fontSize: 14.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? c.accent : c.text)),
            ]),
          ),
        ),
      );
    }

    return Container(
      width: 244,
      color: c.sidebar,
      child: Column(children: [
        const DragToMoveArea(child: SizedBox(height: 14, width: double.infinity)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.accent, c.accent.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text('ق', style: TextStyle(fontFamily: kArabicFont, fontSize: 20, color: c.onAccent, height: 1.1)),
            ),
            const SizedBox(width: 10),
            const Text('IQRA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ]),
        ),
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
        item(Section.discover),
        item(Section.tools),
        const Padding(padding: EdgeInsets.fromLTRB(24, 18, 12, 6), child: Align(alignment: Alignment.centerLeft, child: _GroupLabel('Library'))),
        item(Section.library),
        const Spacer(),
        item(Section.settings),
        const SizedBox(height: 12),
      ]),
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
