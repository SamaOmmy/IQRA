import 'dart:io' show Platform;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/audio.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'reader.dart';
import 'window_controls.dart';
import 'widgets.dart';

String _fmt(Duration d) {
  final m = d.inMinutes, s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// The floating bar (phones) shown above the tab bar while something is loaded.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final c = context.c;
    final v = audio.current;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: FadeTransition(opacity: a, child: child)),
      child: v == null
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Padding(
              key: const ValueKey('mini'),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Pressable(
                onTap: () => showNowPlaying(context),
                radius: 18,
                scale: 0.985,
                hover: false,
                child: Glass(
                  radius: BorderRadius.circular(18),
                  color: c.surface,
                  opacity: 0.82,
                  border: true,
                  child: SizedBox(
                    height: 64,
                    child: Stack(children: [
                      Row(children: [
                        const SizedBox(width: 10),
                        SurahArt(surah: v.s, size: 44, showName: false, radius: 9),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(Quran.I.surah(v.s).en, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(audio.error ?? 'Verse ${v.a} · ${reciterName(context.read<AppStore>().reciter)}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: audio.error != null ? Colors.redAccent : c.textSecondary, fontSize: 12.5)),
                          ]),
                        ),
                        _PlayPause(audio: audio, size: 30),
                        IconButton(onPressed: audio.next, icon: const Icon(Icons.skip_next_rounded, size: 28)),
                        const SizedBox(width: 4),
                      ]),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(value: audio.progress, minHeight: 2.5, backgroundColor: Colors.transparent, color: c.accent),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PlayPause extends StatelessWidget {
  const _PlayPause({required this.audio, this.size = 36});
  final AudioController audio;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (audio.loading) {
      return Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: size * 0.7, height: size * 0.7, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.text)));
    }
    return IconButton(
      onPressed: audio.toggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (ch, a) => ScaleTransition(scale: a, child: ch),
        child: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, key: ValueKey(audio.playing), size: size, color: c.text),
      ),
    );
  }
}

/// The pill in the desktop top bar: transport controls and the current verse, like Apple Music's centre display.
class DesktopNowPlaying extends StatelessWidget {
  const DesktopNowPlaying({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final c = context.c;
    final v = audio.current;
    final ay = audio.ayah;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(onPressed: v == null ? null : audio.previous, icon: const Icon(Icons.skip_previous_rounded, size: 26)),
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        child: audio.active ? _PlayPause(audio: audio, size: 26) : IconButton(onPressed: null, icon: const Icon(Icons.play_arrow_rounded, size: 26)),
      ),
      IconButton(onPressed: v == null ? null : audio.next, icon: const Icon(Icons.skip_next_rounded, size: 26)),
      const SizedBox(width: 10),
      Pressable(
        onTap: v == null ? null : () => showNowPlaying(context),
        radius: 10,
        scale: 0.99,
        child: Container(
          width: 430,
          height: 52,
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: v == null
              ? Center(child: Text('IQRA', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 4)))
              : Stack(children: [
                  Row(children: [
                    SurahArt(surah: v.s, size: 52, showName: false, radius: 0),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${Quran.I.surah(v.s).en} · verse ${v.a}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text(audio.error ?? (ay == null ? '' : ay.ar), maxLines: 1, overflow: TextOverflow.ellipsis,
                            textDirection: audio.error != null ? TextDirection.ltr : TextDirection.rtl,
                            style: TextStyle(color: audio.error != null ? Colors.redAccent : c.textSecondary, fontSize: 13, fontFamily: audio.error != null ? null : kArabicFont)),
                      ]),
                    ),
                    Padding(padding: const EdgeInsets.only(right: 12), child: Text(_fmt(audio.position), style: TextStyle(color: c.textSecondary, fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()]))),
                  ]),
                  Positioned(left: 0, right: 0, bottom: 0, child: LinearProgressIndicator(value: audio.progress, minHeight: 2.5, backgroundColor: Colors.transparent, color: c.accent)),
                ]),
        ),
      ),
    ]);
  }
}

Future<void> showNowPlaying(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (_, __, ___) => const NowPlayingScreen(),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic)),
      child: child,
    ),
  ));
}

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _lyrics = false;
  final _items = ItemScrollController();
  int _lastShown = -1;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioController>();
    final store = context.watch<AppStore>();
    final c = context.c;
    final v = audio.current;
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).maybePop());
      return const SizedBox.shrink();
    }
    final sr = Quran.I.surah(v.s);
    final ay = Quran.I.ayah(v.s, v.a);
    final tr = context.watch<TranslationModel>();
    final (g1, g2) = artColors(v.s * 5 + 2);
    final wide = MediaQuery.of(context).size.width > 820;

    if (_lyrics && _lastShown != v.a && _items.isAttached) {
      _lastShown = v.a;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_items.isAttached) _items.scrollTo(index: v.a - 1, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, alignment: 0.3);
      });
    }

    final controls = _Controls(audio: audio, store: store);
    final artwork = Hero(tag: 'art', child: SurahArt(surah: v.s, size: wide ? 360 : 300, radius: 24));
    final text = _VerseCard(ayah: ay, translation: tr.text(ay), surahName: sr.en);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(g1, Colors.black, c.dark ? 0.45 : 0.1)!, Color.lerp(g2, Colors.black, c.dark ? 0.7 : 0.35)!],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34, color: Colors.white)),
                Expanded(
                  child: Column(children: [
                    Text('NOW PLAYING', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
                    Text(reciterName(store.reciter), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
                IconButton(
                  onPressed: () => setState(() => _lyrics = !_lyrics),
                  icon: Icon(_lyrics ? Icons.format_quote_rounded : Icons.format_align_center_rounded, color: Colors.white),
                  tooltip: 'Follow along',
                ),
                if (Platform.isWindows) const WindowButtons(color: Colors.white),
              ]),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _lyrics
                    ? _Lyrics(key: const ValueKey('l'), surah: v.s, current: v.a, controller: _items, tr: tr, store: store, onPick: (a) => audio.playVerse(v.s, a, scope: audio.scope))
                    : (wide
                        ? Row(key: const ValueKey('w'), mainAxisAlignment: MainAxisAlignment.center, children: [
                            artwork,
                            const SizedBox(width: 56),
                            Flexible(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: text)),
                          ])
                        : SingleChildScrollView(
                            key: const ValueKey('n'),
                            padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                            child: Column(children: [artwork, const SizedBox(height: 22), text]),
                          )),
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(26, 0, 26, 14), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: controls)),
          ]),
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.ayah, required this.translation, required this.surahName});
  final Ayah ayah;
  final String translation, surahName;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$surahName · ${ayah.surah}:${ayah.n}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      const SizedBox(height: 14),
      Directionality(
        textDirection: TextDirection.rtl,
        child: Text(ayah.ar, textAlign: TextAlign.center, style: const TextStyle(fontFamily: kArabicFont, fontSize: 30, height: 1.9, color: Colors.white)),
      ),
      if (translation.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(translation, textAlign: TextAlign.center, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 15.5, height: 1.45)),
      ],
    ]);
  }
}

class _Lyrics extends StatelessWidget {
  const _Lyrics({super.key, required this.surah, required this.current, required this.controller, required this.tr, required this.store, required this.onPick});
  final int surah, current;
  final ItemScrollController controller;
  final TranslationModel tr;
  final AppStore store;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final sr = Quran.I.surah(surah);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ScrollablePositionedList.builder(
          itemScrollController: controller,
          initialScrollIndex: current - 1,
          initialAlignment: 0.3,
          itemCount: sr.ayahs.length,
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
          itemBuilder: (_, i) {
            final a = sr.ayahs[i];
            final on = a.n == current;
            return GestureDetector(
              onTap: () => onPick(a.n),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: on ? 1 : 0.42,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  scale: on ? 1 : 0.94,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(children: [
                      Directionality(textDirection: TextDirection.rtl, child: Text(a.ar, textAlign: TextAlign.center, style: const TextStyle(fontFamily: kArabicFont, fontSize: 32, height: 1.9, color: Colors.white))),
                      if (store.showTranslation) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr.text(a), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.audio, required this.store});
  final AudioController audio;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.7);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          overlayShape: SliderComponentShape.noOverlay,
          activeTrackColor: white,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.28),
          thumbColor: white,
        ),
        child: Slider(value: audio.progress.clamp(0, 1), onChanged: audio.active ? audio.seekFraction : null),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmt(audio.position), style: TextStyle(color: dim, fontSize: 12)),
          Text('-${_fmt(audio.duration - audio.position)}', style: TextStyle(color: dim, fontSize: 12)),
        ]),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(onPressed: audio.previous, icon: const Icon(Icons.skip_previous_rounded, size: 42, color: white)),
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: audio.loading
              ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black87))
              : IconButton(onPressed: audio.toggle, icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 42, color: Colors.black87)),
        ),
        IconButton(onPressed: audio.next, icon: const Icon(Icons.skip_next_rounded, size: 42, color: white)),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _chip(context, Icons.speed_rounded, '${store.speed}×', () => _speedSheet(context)),
        _chip(context, Icons.repeat_rounded, audio.repeatEach > 1 ? '${audio.repeatEach}×' : 'Repeat', () => _repeatSheet(context)),
        _chip(context, Icons.record_voice_over_rounded, 'Reciter', () => _reciterSheet(context)),
        _chip(context, Icons.bedtime_rounded, audio.sleepAt == null ? 'Sleep' : 'On', () => _sleepSheet(context)),
        _chip(context, Icons.menu_book_rounded, 'Open', () {
          final v = audio.current!;
          Navigator.of(context).pop();
          openReader(context, surah: v.s, ayah: v.a);
        }),
      ]),
      if (audio.error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(audio.error!, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
    ]);
  }

  Widget _chip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _pick<T>(BuildContext context, String title, List<(String, T)> items, T? selected, ValueChanged<T> onPick) {
    final c = context.c;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Glass(
            blur: 40,
            opacity: 0.96,
            color: c.bg,
            radius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 8), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)))),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final it in items)
                      ListTile(
                        title: Text(it.$1),
                        trailing: it.$2 == selected ? Icon(Icons.check_rounded, color: c.accent) : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          onPick(it.$2);
                        },
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _speedSheet(BuildContext context) => _pick<double>(context, 'Speed', [for (final s in [0.6, 0.75, 0.9, 1.0, 1.15, 1.25, 1.5, 2.0]) ('$s×', s)], store.speed, audio.setSpeed);
  void _repeatSheet(BuildContext context) => _pick<int>(context, 'Repeat each verse', [for (final n in [1, 2, 3, 5, 7, 10]) (n == 1 ? 'Off' : '$n times', n)], audio.repeatEach, audio.setRepeat);
  void _reciterSheet(BuildContext context) => _pick<String>(context, 'Reciter', [for (final r in kReciters) (r.$2, r.$1)], store.reciter, (id) {
        store.reciter = id;
        final v = audio.current;
        if (v != null) audio.playVerse(v.s, v.a);
      });
  void _sleepSheet(BuildContext context) => _pick<int>(context, 'Sleep timer', [('Off', 0), ('10 minutes', 10), ('20 minutes', 20), ('30 minutes', 30), ('45 minutes', 45), ('1 hour', 60)], null, audio.sleepIn);
}
