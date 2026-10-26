import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/store.dart';
import '../../core/theme.dart';
import '../page_scaffold.dart';
import '../share_card.dart';
import '../widgets.dart';

/// One hadith with its Arabic text, a plain summary and, when available, the in-depth explanation.
class HadithDetailScreen extends StatelessWidget {
  const HadithDetailScreen({super.key, required this.title, required this.arabic, required this.summary, this.source, this.explain, this.favKey, this.number});
  final String title, arabic, summary;
  final String? source, favKey;
  final int? number;
  final Map<String, dynamic>? explain;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final setting = ((explain?['s'] as List?) ?? const []).cast<String>();
    final meaning = ((explain?['m'] as List?) ?? const []).cast<String>();
    final lessons = ((explain?['l'] as List?) ?? const []).cast<String>();
    final share = '$arabic\n\n$summary\n\n— ${source ?? title}';

    Widget heading(String text, IconData icon) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
          child: Row(children: [
            Icon(icon, color: c.accent, size: 22),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ]),
        );

    return LargePage(
      title: number != null ? 'Hadith $number' : title,
      subtitle: number != null ? title : source,
      maxWidth: 820,
      actions: [
        if (favKey != null) IconButton(onPressed: () => store.toggleFav(favKey!), icon: Icon(store.isFav(favKey!) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: c.accent)),
        IconButton(onPressed: () => showShareCard(context, arabic: arabic, translation: summary, reference: source ?? title), icon: Icon(Icons.image_rounded, color: c.accent)),
        IconButton(onPressed: () => SharePlus.instance.share(ShareParams(text: share)), icon: Icon(Icons.ios_share_rounded, color: c.accent)),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Directionality(textDirection: TextDirection.rtl, child: selectableText(arabic, textAlign: TextAlign.center, style: TextStyle(fontFamily: kArabicFont, fontSize: 28, height: 2, color: c.text))),
                const SizedBox(height: 16),
                Container(height: 0.8, color: c.separator),
                const SizedBox(height: 16),
                Text('TRANSLATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.accent)),
                const SizedBox(height: 6),
                selectableText(summary, style: const TextStyle(fontSize: 17, height: 1.6)),
                if (source != null) ...[
                  const SizedBox(height: 12),
                  Text(source!, style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13.5)),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: share));
                      showToast(context, 'Copied');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
              ]),
            ),
          ),
        ),
        if (setting.isNotEmpty) ...[
          SliverToBoxAdapter(child: heading('The setting', Icons.history_edu_rounded)),
          SliverToBoxAdapter(child: _Paras(setting)),
        ],
        if (meaning.isNotEmpty) ...[
          SliverToBoxAdapter(child: heading('Understanding it', Icons.lightbulb_rounded)),
          SliverToBoxAdapter(child: _Paras(meaning)),
        ],
        if (lessons.isNotEmpty) ...[
          SliverToBoxAdapter(child: heading('Living by it', Icons.favorite_rounded)),
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
        if (explain == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('A fuller explanation of this hadith is being written.', style: TextStyle(color: c.textSecondary)),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Text('Written for IQRA from the classical commentaries. Please review it with a scholar before relying on it for rulings.', style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.45)),
          ),
        ),
      ],
    );
  }
}

class _Paras extends StatelessWidget {
  const _Paras(this.paras);
  final List<String> paras;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final p in paras) Padding(padding: const EdgeInsets.only(bottom: 14), child: selectableText(p, style: const TextStyle(fontSize: 16.5, height: 1.65))),
      ]),
    );
  }
}
