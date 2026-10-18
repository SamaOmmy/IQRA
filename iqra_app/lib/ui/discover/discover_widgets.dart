import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/content.dart';
import '../../core/quran.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../core/translation.dart';
import '../widgets.dart';
import '../reader.dart';
import '../share_card.dart';
import 'hadith_detail.dart';
import 'story_screen.dart';

int _seedOf(String s) => s.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0xFFFF);

/// A story as a coloured cover with its Arabic title: used in shelves.
class StoryTile extends StatelessWidget {
  const StoryTile({super.key, required this.story, this.width = 170, this.height});
  final J story;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final id = story['id'] as String;
    final mins = Content.I.readingMinutes(story);
    return Pressable(
      onTap: () => openStory(context, id),
      radius: 20,
      scale: 0.97,
      hover: false,
      child: SizedBox(
        width: width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ColorTile(
            seed: _seedOf(id),
            width: width,
            height: height ?? width * 0.98,
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$mins min', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, fontWeight: FontWeight.w700)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      alignment: Alignment.centerRight,
                      fit: BoxFit.scaleDown,
                      child: Text((story['ar'] as String?) ?? '', style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 26, height: 1.3)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(story['title'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.25)),
        ]),
      ),
    );
  }
}

/// A wider list row for a story, with the first lines of the text.
class StoryRow extends StatelessWidget {
  const StoryRow({super.key, required this.story, this.index});
  final J story;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final id = story['id'] as String;
    final first = ((story['p'] as List).first as String).replaceAll(RegExp(r'\s+'), ' ');
    final mins = Content.I.readingMinutes(story);
    final era = story['era'] as String?;
    return Pressable(
      onTap: () => openStory(context, id),
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ColorTile(
            seed: _seedOf(id),
            width: 64,
            height: 64,
            radius: 14,
            child: Center(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text((story['ar'] as String?) ?? '', style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 19))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${index != null ? '$index. ' : ''}${story['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.25)),
              const SizedBox(height: 2),
              Text('${era != null ? '$era · ' : ''}$mins min read', style: TextStyle(color: c.accent, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(first, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.35)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class HadithCard extends StatelessWidget {
  const HadithCard({super.key, required this.h});
  final Map<String, dynamic> h;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final key = 'hadith:${h['id']}';
    final text = '${h['ar']}\n\n${h['en']}\n\n— ${h['src']}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(h['title'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
        const SizedBox(height: 12),
        Directionality(textDirection: TextDirection.rtl, child: Text(h['ar'] as String, style: TextStyle(fontFamily: kArabicFont, fontSize: 26, height: 1.9, color: c.text))),
        const SizedBox(height: 10),
        Text('TRANSLATION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.accent)),
        const SizedBox(height: 4),
        Text(h['en'] as String, style: TextStyle(fontSize: 15.5, height: 1.5, color: c.text)),
        const SizedBox(height: 8),
        Text(h['src'] as String, style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 6),
        if (h['x'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: FilledButton.tonalIcon(
              onPressed: () => openHadith(context, h),
              icon: const Icon(Icons.auto_stories_rounded, size: 18),
              label: const Text('Read the explanation'),
            ),
          ),
        Wrap(children: [
          _ActBtn(store.isFav(key) ? Icons.favorite_rounded : Icons.favorite_border_rounded, store.isFav(key) ? 'Saved' : 'Save', () => store.toggleFav(key), on: store.isFav(key)),
          _ActBtn(Icons.copy_rounded, 'Copy', () {
            Clipboard.setData(ClipboardData(text: text));
            showToast(context, 'Copied');
          }),
          _ActBtn(Icons.image_rounded, 'Image', () => showShareCard(context, arabic: h['ar'] as String, translation: h['en'] as String, reference: h['src'] as String)),
          _ActBtn(Icons.ios_share_rounded, 'Share', () => SharePlus.instance.share(ShareParams(text: text))),
        ]),
      ]),
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn(this.icon, this.label, this.onTap, {this.on = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      radius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(children: [
          Icon(icon, size: 19, color: on ? c.accent : c.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: on ? c.accent : c.textSecondary)),
        ]),
      ),
    );
  }
}

/// A verse or range from the Qur'an with its translation, tap to open in the reader.
class VerseBlock extends StatelessWidget {
  const VerseBlock({super.key, required this.s, required this.a, this.b});
  final int s, a;
  final int? b;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tr = context.watch<TranslationModel>();
    final last = (b ?? a).clamp(a, Quran.I.surah(s).ayahs.length);
    final ayahs = [for (var i = a; i <= last; i++) Quran.I.ayah(s, i)];
    return Pressable(
      onTap: () => openReader(context, surah: s, ayah: a),
      radius: 18,
      scale: 0.99,
      hover: false,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(ayahs.map((x) => x.ar).join(' '), style: TextStyle(fontFamily: kArabicFont, fontSize: 27, height: 1.9, color: c.text)),
          ),
          const SizedBox(height: 8),
          Text(ayahs.map(tr.text).join(' '), style: TextStyle(fontSize: 15.5, height: 1.5, color: c.textSecondary)),
          const SizedBox(height: 8),
          Text('${Quran.I.surah(s).en} ${last == a ? '$s:$a' : '$s:$a–$last'}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ]),
      ),
    );
  }
}

/// A dua or dhikr with an optional repeat counter.
class DuaBlock extends StatefulWidget {
  const DuaBlock({super.key, required this.ar, this.en, this.tl, this.count = 1, this.note, this.source, this.favKey});
  final String ar;
  final String? en, tl, note, source, favKey;
  final int count;

  @override
  State<DuaBlock> createState() => _DuaBlockState();
}

class _DuaBlockState extends State<DuaBlock> {
  int _done = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final fin = _done >= widget.count;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: fin ? c.accent.withValues(alpha: 0.12) : c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Directionality(textDirection: TextDirection.rtl, child: Text(widget.ar, style: TextStyle(fontFamily: kArabicFont, fontSize: 25, height: 1.9, color: c.text))),
        if (widget.tl != null && widget.tl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.tl!, style: TextStyle(color: c.accent, fontStyle: FontStyle.italic, height: 1.4, fontSize: 14.5)),
        ],
        if (widget.en != null && widget.en!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.en!, style: TextStyle(fontSize: 15.5, height: 1.5, color: c.text)),
        ],
        if (widget.note != null && widget.note!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.note!, style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.45)),
        ],
        if (widget.source != null && widget.source!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.source!, style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.4)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          if (widget.count > 1)
            Pressable(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _done = fin ? 0 : _done + 1);
              },
              radius: 100,
              scale: 0.93,
              hover: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: fin ? c.accent : c.bg, borderRadius: BorderRadius.circular(100), border: Border.all(color: c.accent)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(fin ? Icons.check_rounded : Icons.touch_app_rounded, size: 18, color: fin ? c.onAccent : c.accent),
                  const SizedBox(width: 8),
                  Text(fin ? 'Done · tap to reset' : '$_done / ${widget.count}', style: TextStyle(fontWeight: FontWeight.w700, color: fin ? c.onAccent : c.accent)),
                ]),
              ),
            ),
          const Spacer(),
          if (widget.favKey != null) _ActBtn(store.isFav(widget.favKey!) ? Icons.favorite_rounded : Icons.favorite_border_rounded, '', () => store.toggleFav(widget.favKey!), on: store.isFav(widget.favKey!)),
          _ActBtn(Icons.copy_rounded, '', () {
            Clipboard.setData(ClipboardData(text: '${widget.ar}\n\n${widget.en ?? ''}'));
            showToast(context, 'Copied');
          }),
        ]),
      ]),
    );
  }
}


void openHadith(BuildContext context, Map<String, dynamic> h) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => HadithDetailScreen(
      title: h['title'] as String,
      arabic: h['ar'] as String,
      summary: h['en'] as String,
      source: h['src'] as String?,
      explain: (h['x'] as Map?)?.cast<String, dynamic>(),
      favKey: 'hadith:${h['id']}',
    ),
  ));
}
