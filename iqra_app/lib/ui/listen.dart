import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio.dart';
import '../core/audio_cache.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'page_scaffold.dart';
import 'reader.dart';
import 'gradients.dart';
import 'widgets.dart';

class _Playlist {
  const _Playlist(this.title, this.ar, this.blurb, this.surahs, this.seed);
  final String title, ar, blurb;
  final List<int> surahs;
  final int seed;
}

final _playlists = <_Playlist>[
  _Playlist('Juz’ ‘Amma', 'جزء عم', 'The last part of the Qur’an, surah by surah', [78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114], 3),
  _Playlist('Before sleep', 'قبل النوم', 'Al-Mulk, As-Sajdah and the three Quls', [67, 32, 112, 113, 114], 7),
  _Playlist('Friday', 'الجمعة', 'Surah al-Kahf, recommended every Friday', [18], 1),
  _Playlist('Heart softeners', 'تلين القلوب', 'Reminders of mercy and the Hereafter', [55, 56, 67, 75, 78, 81, 82, 99, 101], 5),
  _Playlist('Stories of the prophets', 'قصص الأنبياء', 'Yusuf, Maryam, Ibrahim, Nuh, Al-Anbiya', [12, 19, 14, 71, 21], 9),
  _Playlist('Short surahs for prayer', 'قصار السور', 'Easy to memorise and recite in prayer', [112, 113, 114, 108, 110, 103, 105, 106, 107, 109, 111], 11),
  _Playlist('The Qur’an from the start', 'المصحف كاملا', 'All 114 surahs, in order', [for (var i = 1; i <= 114; i++) i], 2),
];

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  Map<int, int> _cached = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await AudioCache.root();
    final reciter = context.read<AppStore>().reciter;
    final m = <int, int>{for (final s in Quran.I.surahs) s.n: AudioCache.cachedCount(reciter, s.n)};
    if (mounted) setState(() => _cached = m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final audio = context.watch<AudioController>();
    final recent = store.recentSurahs;
    final reciter = store.reciter;
    return LargePage(
      title: 'Listen',
      subtitle: reciterName(reciter),
      slivers: [
        if (audio.active)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _NowCard(audio: audio),
            ),
          ),
        const SliverToBoxAdapter(child: SectionHeader('Playlists')),
        SliverToBoxAdapter(
          child: Shelf(height: 176, gap: 14, children: [
            for (final p in _playlists)
              Pressable(
                onTap: () => audio.playQueue(p.surahs, title: p.title),
                radius: 20,
                scale: 0.97,
                hover: false,
                child: ColorTile(
                  seed: p.seed,
                  width: 230,
                  height: 176,
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black87),
                        ),
                        const Spacer(),
                        Directionality(textDirection: TextDirection.rtl, child: Text(p.ar, style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 19))),
                      ]),
                      const Spacer(),
                      Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.15)),
                      const SizedBox(height: 3),
                      Text('${p.surahs.length} surah${p.surahs.length == 1 ? '' : 's'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        if (recent.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHeader('Recently played')),
          SliverToBoxAdapter(
            child: Shelf(height: 196, gap: 14, children: [
              for (final n in recent)
                SizedBox(
                  width: 140,
                  child: ArtTile(
                    surah: n,
                    onOpen: () => openReader(context, surah: n, mushaf: false),
                    onPlay: () => audio.playVerse(n, 1, scope: PlayScope.surah),
                  ),
                ),
            ]),
          ),
        ],
        const SliverToBoxAdapter(child: SectionHeader('Reciters')),
        SliverToBoxAdapter(
          child: Shelf(height: 138, gap: 16, children: [
            for (var i = 0; i < kReciters.length; i++)
              _ReciterChip(
                index: i,
                id: kReciters[i].$1,
                name: kReciters[i].$2,
                selected: kReciters[i].$1 == reciter,
                onTap: () {
                  store.reciter = kReciters[i].$1;
                  _refresh();
                  showToast(context, '${kReciters[i].$2} selected');
                },
              ),
          ]),
        ),
        const SliverToBoxAdapter(child: SectionHeader('All surahs')),
        SliverList.builder(
          itemCount: 114,
          itemBuilder: (context, i) {
            final s = Quran.I.surah(i + 1);
            final cached = _cached[s.n] ?? 0;
            final full = cached >= s.ayahs.length;
            final playing = audio.current?.s == s.n && audio.playing;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Pressable(
                onTap: () => audio.playVerse(s.n, 1, scope: PlayScope.surah),
                radius: 14,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  child: Row(children: [
                    SurahArt(surah: s.n, size: 52, showName: false, radius: 10),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.en, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: playing ? c.accent : c.text)),
                        Text('${s.meaning} · ${s.ayahs.length} verses', style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
                      ]),
                    ),
                    if (full) Icon(Icons.download_done_rounded, size: 19, color: c.textSecondary) else if (cached > 0) Text('$cached/${s.ayahs.length}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                    const SizedBox(width: 10),
                    Icon(playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded, color: playing ? c.accent : c.textSecondary),
                  ]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.audio});
  final AudioController audio;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final v = audio.current!;
    final s = Quran.I.surah(v.s);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        SurahArt(surah: v.s, size: 64, showName: false, radius: 14),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(audio.queueTitle != null ? 'PLAYLIST · ${audio.queueTitle}' : 'NOW PLAYING', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            Text(s.en, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Verse ${v.a} of ${s.ayahs.length}', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          ]),
        ),
        IconButton(onPressed: audio.previousSurah, icon: const Icon(Icons.skip_previous_rounded, size: 28)),
        IconButton(onPressed: audio.toggle, icon: Icon(audio.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 40, color: c.accent)),
        IconButton(onPressed: audio.nextSurah, icon: const Icon(Icons.skip_next_rounded, size: 28)),
      ]),
    );
  }
}

class _ReciterChip extends StatelessWidget {
  const _ReciterChip({required this.index, required this.id, required this.name, required this.selected, required this.onTap});
  final int index;
  final String id, name;
  final bool selected;
  final VoidCallback onTap;

  String get _initials {
    final parts = name.replaceAll(RegExp(r'\(.*\)'), '').trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (a, b) = artColors(index * 7 + 3);
    return Pressable(
      onTap: onTap,
      radius: 70,
      scale: 0.95,
      hover: false,
      child: SizedBox(
        width: 100,
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? c.accent : Colors.transparent, width: 3),
              boxShadow: [BoxShadow(color: a.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: CustomPaint(painter: GradientPainter.linear([a, b], radius: 40))),
              selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 36) : Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 8),
          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? c.accent : c.text, height: 1.2)),
        ]),
      ),
    );
  }
}
