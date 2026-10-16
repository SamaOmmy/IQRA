import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'settings.dart';
import 'shell.dart';
import 'widgets.dart';

/// A scrolling page with a large title that collapses into a frosted bar: the Apple Music screen pattern.
class LargePage extends StatelessWidget {
  const LargePage({super.key, required this.title, required this.slivers, this.subtitle, this.actions = const [], this.leading, this.bottomPadding = 150, this.maxWidth = 1100, this.controller});

  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Widget? leading;
  final double bottomPadding, maxWidth;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: CustomScrollView(
            controller: controller,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _TitleDelegate(
                  title: title,
                  subtitle: subtitle,
                  actions: [
                    ...actions,
                    if (!canPop && AppShell.of(context) != null)
                      IconButton(
                        onPressed: () => AppShell.of(context)?.go(Section.search),
                        icon: Icon(Icons.search_rounded, color: c.accent),
                        tooltip: 'Search',
                      ),
                    if (!canPop && AppShell.of(context) != null && MediaQuery.of(context).size.width < 860)
                      IconButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        icon: Icon(Icons.settings_rounded, color: c.accent),
                        tooltip: 'Settings',
                      ),
                  ],
                  leading: leading ?? (canPop ? const _BackButton() : null),
                  top: MediaQuery.of(context).padding.top,
                  colors: c,
                ),
              ),
              ...slivers,
              SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => Navigator.of(context).maybePop(),
    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.c.accent),
  );
}

class _TitleDelegate extends SliverPersistentHeaderDelegate {
  _TitleDelegate({required this.title, required this.subtitle, required this.actions, required this.leading, required this.top, required this.colors});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final double top;
  final IqraColors colors;

  static const _small = 52.0;
  static const _large = 104.0;

  @override
  double get minExtent => _small + top;
  @override
  double get maxExtent => _large + top + (subtitle == null ? 0 : (subtitle!.length > 38 ? 40 : 20));

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final c = colors;
    final largeOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.12,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: t > 0.85 ? 1 : t * 0.9,
              child: Glass(
                blur: 30,
                opacity: 0.85,
                color: c.bg,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.separator, width: 0.6)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 4,
            right: 4,
            height: _small,
            child: Row(
              children: [
                if (leading != null) leading!,
                Expanded(
                  child: Opacity(
                    opacity: ((t - 0.55) * 3).clamp(0.0, 1.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                ...actions,
                if (leading != null && actions.isEmpty) const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 10,
            child: Opacity(
              opacity: largeOpacity,
              child: Transform.translate(
                offset: Offset(0, -shrinkOffset * 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: math.max(26, 34 - t * 6), fontWeight: FontWeight.w800, letterSpacing: -0.9, color: c.text),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.5, color: c.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TitleDelegate old) => old.title != title || old.subtitle != subtitle || old.colors != colors || old.top != top || old.actions != actions;
}
