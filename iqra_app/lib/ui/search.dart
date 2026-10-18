import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/content.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'discover/discover_widgets.dart';
import 'discover/lists.dart';
import 'reader.dart';
import 'widgets.dart';

String normalizeArabic(String s) {
  return s
      .replaceAll(RegExp('[ً-ْٰـۖ-ۭ]'), '')
      .replaceAll(RegExp('[آأإٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ی', 'ي');
}

bool _isArabic(String s) => RegExp('[؀-ۿ]').hasMatch(s);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctl = TextEditingController();
  Timer? _debounce;
  String _q = '';
  List<String>? _normAr;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => setState(() => _q = v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final tr = context.watch<TranslationModel>();
    final top = MediaQuery.of(context).padding.top;
    final q = _q;
    final lower = q.toLowerCase();

    List<Widget> results = [];
    if (q.length >= 2) {
      final content = Content.I;
      // surahs
      final surahs = [
        for (final s in Quran.I.surahs)
          if (s.en.toLowerCase().contains(lower) || s.meaning.toLowerCase().contains(lower) || normalizeArabic(s.ar).contains(normalizeArabic(q)) || '${s.n}' == q) s,
      ].take(8).toList();
      // verses
      final verses = <Ayah>[];
      final ref = RegExp(r'^(\d{1,3})\s*[:.]\s*(\d{1,3})$').firstMatch(q);
      if (ref != null) {
        final s = int.parse(ref[1]!), a = int.parse(ref[2]!);
        if (s >= 1 && s <= 114 && a >= 1 && a <= Quran.I.surah(s).ayahs.length) verses.add(Quran.I.ayah(s, a));
      } else if (_isArabic(q)) {
        _normAr ??= [for (final a in Quran.I.allAyahs) normalizeArabic(a.ar)];
        final nq = normalizeArabic(q);
        final all = Quran.I.allAyahs;
        for (var i = 0; i < all.length && verses.length < 40; i++) {
          if (_normAr![i].contains(nq)) verses.add(all[i]);
        }
      } else {
        final all = Quran.I.allAyahs;
        for (var i = 0; i < all.length && verses.length < 40; i++) {
          if (tr.text(all[i]).toLowerCase().contains(lower)) verses.add(all[i]);
        }
      }
      final stories = content.stories.where((s) => (s['title'] as String).toLowerCase().contains(lower) || ((s['p'] as List).first as String).toLowerCase().contains(lower)).take(8).toList();
      final hadith = content.hadith.cast<Map<String, dynamic>>().where((h) => '${h['title']} ${h['en']}'.toLowerCase().contains(lower) || normalizeArabic(h['ar'] as String).contains(normalizeArabic(q))).take(6).toList();
      final collections = content.collections.where((x) => '${x['title']} ${x['blurb']}'.toLowerCase().contains(lower)).take(5).toList();
      final guides = content.guides.where((x) => '${x['title']} ${x['blurb']}'.toLowerCase().contains(lower)).take(5).toList();
      final hisn = <int>[
        for (var i = 0; i < content.hisn.length; i++)
          if ((content.hisn[i] as Map)['en'].toString().toLowerCase().contains(lower)) i,
      ].take(6).toList();
      final names = content.names.where((n) => (n[1] as String).toLowerCase().contains(lower) || (n[2] as String).toLowerCase().contains(lower) || normalizeArabic(n[0] as String).contains(normalizeArabic(q))).take(6).toList();

      Widget header(String t) => SectionHeader(t, padding: const EdgeInsets.fromLTRB(24, 22, 24, 6));
      if (surahs.isNotEmpty) {
        results.add(header('Surahs'));
        for (final s in surahs) {
          results.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Pressable(
              onTap: () => openReader(context, surah: s.n),
              radius: 14,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  SurahArt(surah: s.n, size: 48, showName: false, radius: 10),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.en, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)), Text('${s.meaning} · ${s.ayahs.length} verses', style: TextStyle(color: c.textSecondary, fontSize: 13))])),
                  Text(s.ar, style: TextStyle(fontFamily: kArabicFont, fontSize: 19, color: c.textSecondary)),
                ]),
              ),
            ),
          ));
        }
      }
      if (verses.isNotEmpty) {
        results.add(header('Verses'));
        for (final a in verses) {
          results.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Pressable(
              onTap: () {
                store.addSearch(q);
                openReader(context, surah: a.surah, ayah: a.n);
              },
              radius: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Directionality(textDirection: TextDirection.rtl, child: Text(a.ar, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: kArabicFont, fontSize: 22, height: 1.8, color: c.text))),
                  const SizedBox(height: 4),
                  Text(tr.text(a), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text('${Quran.I.surah(a.surah).en} ${a.surah}:${a.n}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
            ),
          ));
        }
      }
      if (stories.isNotEmpty) {
        results.add(header('Stories'));
        for (final s in stories) {
          results.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: StoryRow(story: s)));
        }
      }
      if (hadith.isNotEmpty) {
        results.add(header('Hadith'));
        for (final h in hadith) {
          results.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: HadithCard(h: h)));
        }
      }
      void row(String title, String sub, VoidCallback onTap) => results.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Pressable(
              onTap: onTap,
              radius: 14,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)), if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13))])),
                  Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                ]),
              ),
            ),
          ));
      if (collections.isNotEmpty || guides.isNotEmpty || hisn.isNotEmpty) results.add(header('More'));
      for (final x in collections) {
        row(x['title'] as String, 'Collection', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CollectionScreen(id: x['id'] as String))));
      }
      for (final g in guides) {
        row(g['title'] as String, 'Guide', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GuideScreen(id: g['id'] as String))));
      }
      for (final i in hisn) {
        row((content.hisn[i] as Map)['en'] as String, 'Hisn al-Muslim', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HisnChapterScreen(index: i))));
      }
      if (names.isNotEmpty) {
        results.add(header('Names of Allah'));
        for (final n in names) {
          row('${n[1]}  ·  ${n[0]}', n[2] as String, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NamesScreen())));
        }
      }
      if (results.isEmpty) {
        results = [const Padding(padding: EdgeInsets.only(top: 80), child: Empty(Icons.search_off_rounded, 'No results', 'Try another word, an Arabic word, or a verse like 2:255.'))];
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: EdgeInsets.only(top: top + 10, bottom: 160),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                child: Text('Search', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.9, color: c.text)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _ctl,
                  autofocus: false,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Verses, surahs, stories, hadith, duas…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _ctl.text.isEmpty ? null : IconButton(onPressed: () => setState(() { _ctl.clear(); _q = ''; }), icon: const Icon(Icons.close_rounded)),
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              if (q.length < 2) ...[
                if (store.recentSearches.isNotEmpty) ...[
                  const SectionHeader('Recent'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final r in store.recentSearches) Pill(r, onTap: () => setState(() { _ctl.text = r; _q = r; })),
                    ]),
                  ),
                ],
                const SectionHeader('Try'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final t in const ['patience', 'mercy', 'Yusuf', 'travel', '2:255', 'الصبر', 'forgiveness', 'prayer'])
                      Pill(t, onTap: () => setState(() { _ctl.text = t; _q = t; })),
                  ]),
                ),
              ] else
                ...results,
            ],
          ),
        ),
      ),
    );
  }
}
