import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/content.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../widgets.dart';
import 'discover_widgets.dart';

Future<void> openStory(BuildContext context, String id) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryScreen(id: id)));
}

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final story = Content.I.story(id);
    if (story == null) return const LargePage(title: 'Story', slivers: [SliverToBoxAdapter(child: Empty(Icons.search_off_rounded, 'Not found', 'This story could not be found.'))]);
    final deep = Content.I.deep(id);
    final paras = (story['p'] as List).cast<String>();
    final lessons = ((story['l'] as List?) ?? const []).cast<String>();
    final verses = ((story['v'] as List?) ?? const []).map((e) => (e as List).cast<int>()).toList();
    final facts = deep == null ? const [] : (deep['facts'] as List);
    final sections = deep == null ? const [] : (deep['s'] as List);
    final key = 'story:$id';
    final mins = Content.I.readingMinutes(story);
    final shelf = Content.I.shelves.firstWhere((s) => s['id'] == story['shelf'], orElse: () => <String, dynamic>{});
    final all = Content.I.storiesOf(story['shelf'] as String);
    final idx = all.indexWhere((s) => s['id'] == id);
    final prev = idx > 0 ? all[idx - 1] : null;
    final next = idx >= 0 && idx < all.length - 1 ? all[idx + 1] : null;
    final wide = MediaQuery.of(context).size.width > 700;

    Widget section(String title, {String? ar}) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4))),
            if (ar != null) Text(ar, style: TextStyle(fontFamily: kArabicFont, color: c.textSecondary, fontSize: 18)),
          ]),
        );

    return LargePage(
      title: story['title'] as String,
      subtitle: '${shelf['title'] ?? ''} · $mins min read',
      maxWidth: 820,
      actions: [
        IconButton(onPressed: () => store.toggleFav(key), icon: Icon(store.isFav(key) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: c.accent)),
        IconButton(
          onPressed: () => SharePlus.instance.share(ShareParams(text: '${story['title']}\n\n${paras.join('\n\n')}\n\n${story['src'] ?? ''}')),
          icon: Icon(Icons.ios_share_rounded, color: c.accent),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ColorTile(
              seed: story['id'].toString().codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0xFFFF),
              height: wide ? 190 : 150,
              radius: 24,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(children: [
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (story['era'] != null) Text(story['era'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(story['title'] as String, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5)),
                    ]),
                  ),
                  Directionality(textDirection: TextDirection.rtl, child: Text((story['ar'] as String?) ?? '', style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 38))),
                ]),
              ),
            ),
          ),
        ),
        if (facts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  for (var i = 0; i < facts.length; i++) ...[
                    if (i > 0) const Divider1(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 110, child: Text((facts[i] as List)[0] as String, style: TextStyle(color: c.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w600))),
                        Expanded(child: Text((facts[i] as List)[1] as String, style: const TextStyle(fontSize: 14.5, height: 1.35))),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        SliverToBoxAdapter(child: section('The story')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final p in paras) Padding(padding: const EdgeInsets.only(bottom: 14), child: SelectableText(p, style: const TextStyle(fontSize: 17, height: 1.62))),
            ]),
          ),
        ),
        if (sections.isNotEmpty) ...[
          SliverToBoxAdapter(child: section('In depth', ar: 'بالتفصيل')),
          SliverList.builder(
            itemCount: sections.length,
            itemBuilder: (context, i) {
              final s = sections[i] as Map<String, dynamic>;
              return Reveal(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 4, height: 22, decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s['h'] as String, style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.w800, letterSpacing: -0.3))),
                    ]),
                    const SizedBox(height: 10),
                    for (final t in (s['t'] as List)) Padding(padding: const EdgeInsets.only(bottom: 12), child: SelectableText(t as String, style: const TextStyle(fontSize: 16.5, height: 1.62))),
                  ]),
                ),
              );
            },
          ),
        ],
        if (lessons.isNotEmpty) ...[
          SliverToBoxAdapter(child: section('What it teaches')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.accent.withValues(alpha: c.dark ? 0.16 : 0.09), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final l in lessons)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(padding: const EdgeInsets.only(top: 4, right: 12), child: Icon(Icons.auto_awesome_rounded, size: 17, color: c.accent)),
                        Expanded(child: Text(l, style: const TextStyle(fontSize: 15.5, height: 1.5))),
                      ]),
                    ),
                ]),
              ),
            ),
          ),
        ],
        if (verses.isNotEmpty) ...[
          SliverToBoxAdapter(child: section('From the Qur’an')),
          SliverList.separated(
            itemCount: verses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final v = verses[i];
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: VerseBlock(s: v[0], a: v[1], b: v.length > 2 ? v[2] : null));
            },
          ),
        ],
        if (story['src'] != null)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 0), child: Text('Source: ${story['src']}', style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.45)))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: Row(children: [
              Expanded(child: prev == null ? const SizedBox() : _NavBtn(label: prev['title'] as String, icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StoryScreen(id: prev['id'] as String))))),
              const SizedBox(width: 12),
              Expanded(child: next == null ? const SizedBox() : _NavBtn(label: next['title'] as String, icon: Icons.chevron_right_rounded, right: true, onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StoryScreen(id: next['id'] as String))))),
            ]),
          ),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.label, required this.icon, required this.onTap, this.right = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      radius: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: right ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
          if (!right) Icon(icon, color: c.accent),
          Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: right ? TextAlign.right : TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          if (right) Icon(icon, color: c.accent),
        ]),
      ),
    );
  }
}
