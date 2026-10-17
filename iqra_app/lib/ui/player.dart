import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:window_manager/window_manager.dart';

import '../core/audio.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'live_verse.dart';
import 'reader.dart';
import 'share_card.dart';
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
  bool _lyrics = false; // phones: show the verses instead of the artwork
  bool _lyricsWide = true; // PCs: the verses sit beside the artwork, like synced lyrics
  bool _full = false;
  bool _selecting = false; // choosing verses to share as a picture
  final Set<int> _picked = {};
  final _items = ItemScrollController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    if (_full && !Platform.isAndroid) windowManager.setFullScreen(false);
    super.dispose();
  }

  Future<void> _toggleFull() async {
    if (Platform.isAndroid) return;
    _full = !_full;
    await windowManager.setFullScreen(_full);
    if (mounted) setState(() {});
  }

  /// The chosen verses as one picture (Arabic and translation, with the reference), ready for a status or a chat.
  void _shareVerses(int surah) {
    final sr = Quran.I.surah(surah);
    final tr = context.read<TranslationModel>();
    final list = _picked.toList()..sort();
    final ayahs = [for (final n in list) sr.ayahs[n - 1]];
    var consecutive = true;
    for (var i = 1; i < list.length; i++) {
      if (list[i] != list[i - 1] + 1) consecutive = false;
    }
    final ref = list.length == 1 ? '${sr.en} $surah:${list.first}' : (consecutive ? '${sr.en} $surah:${list.first}–${list.last}' : '${sr.en} $surah:${list.join(', ')}');
    showShareCard(context, arabic: ayahs.map((a) => a.ar).join(' '), translation: ayahs.map((a) => tr.text(a)).join(' '), reference: ref);
  }

  KeyEventResult _key(FocusNode n, KeyEvent e, AudioController audio) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      audio.toggle();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowDown) {
      audio.next();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp) {
      audio.previous();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyF) {
      _toggleFull();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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
    final size = MediaQuery.of(context).size;
    final wide = size.width > 900;
    final showLyrics = wide ? _lyricsWide : _lyrics;

    final controls = _Controls(audio: audio, store: store);
    final art = (size.height - 470).clamp(220.0, 380.0);
    final artwork = Hero(tag: 'art', child: SurahArt(surah: v.s, size: wide ? art : 300, radius: 24));
    final text = _VerseCard(ayah: ay, translation: tr.text(ay), surahName: sr.en);
    final lyricsView = _Lyrics(
      key: const ValueKey('l'),
      surah: v.s,
      current: v.a,
      controller: _items,
      tr: tr,
      store: store,
      big: wide,
      selecting: _selecting,
      selected: _picked,
      onPick: (a) {
        if (_selecting) {
          setState(() => _picked.contains(a) ? _picked.remove(a) : _picked.add(a));
        } else {
          audio.playVerse(v.s, a, scope: audio.scope);
        }
      },
    );

    Widget body;
    if (wide) {
      body = Row(children: [
        SizedBox(
          width: math.min(480, size.width * 0.4),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(36, 8, 24, 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                artwork,
                const SizedBox(height: 20),
                Text(sr.en, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text('${sr.meaning} · verse ${v.a} of ${sr.ayahs.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 14)),
                const SizedBox(height: 14),
                controls,
              ]),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: showLyrics ? lyricsView : Center(key: const ValueKey('t'), child: Padding(padding: const EdgeInsets.all(40), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: text))),
          ),
        ),
      ]);
    } else {
      body = Column(children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: showLyrics
                ? lyricsView
                : SingleChildScrollView(
                    key: const ValueKey('n'),
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                    child: Column(children: [artwork, const SizedBox(height: 22), text]),
                  ),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(26, 0, 26, 14), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: controls)),
      ]);
    }

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (n, e) => _key(n, e, audio),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(g1, Colors.black, c.dark ? 0.45 : 0.1)!, Color.lerp(g2, Colors.black, c.dark ? 0.72 : 0.4)!],
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
                      Text(audio.queueTitle != null ? 'PLAYLIST · ${audio.queueTitle!.toUpperCase()}' : (audio.scope == PlayScope.range ? 'LOOPING ${audio.rangeFrom}–${audio.rangeTo}' : 'NOW PLAYING'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
                      Text(reciterName(store.reciter), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  IconButton(
                    onPressed: () => setState(() => wide ? _lyricsWide = !_lyricsWide : _lyrics = !_lyrics),
                    icon: Icon(showLyrics ? Icons.lyrics_rounded : Icons.lyrics_outlined, color: Colors.white),
                    tooltip: showLyrics ? 'Hide the verses' : 'Follow the verses',
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _selecting = !_selecting;
                      _picked.clear();
                      if (_selecting) {
                        _picked.add(v.a);
                        if (wide) {
                          _lyricsWide = true;
                        } else {
                          _lyrics = true;
                        }
                      }
                    }),
                    icon: Icon(_selecting ? Icons.close_rounded : Icons.ios_share_rounded, color: Colors.white),
                    tooltip: _selecting ? 'Cancel' : 'Share verses as a picture',
                  ),
                  if (!Platform.isAndroid)
                    IconButton(onPressed: _toggleFull, icon: Icon(_full ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white), tooltip: _full ? 'Leave full screen (F)' : 'Full screen (F)'),
                  if (Platform.isWindows && !_full) const WindowButtons(color: Colors.white),
                ]),
              ),
              Expanded(
                child: Stack(children: [
                  Positioned.fill(child: body),
                  if (_selecting)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: wide ? 24 : 232, // above the controls on a phone
                      child: Center(
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          elevation: 6,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(40),
                            onTap: _picked.isEmpty ? null : () => _shareVerses(v.s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.ios_share_rounded, size: 20, color: _picked.isEmpty ? Colors.black38 : Colors.black87),
                                const SizedBox(width: 10),
                                Text(_picked.isEmpty ? 'Tap the verses to share' : 'Share ${_picked.length} verse${_picked.length == 1 ? '' : 's'}', style: TextStyle(color: _picked.isEmpty ? Colors.black45 : Colors.black87, fontWeight: FontWeight.w800, fontSize: 15)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
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
      LiveVerse(ayah: ayah, fontSize: 30, color: Colors.white, activeColor: Colors.white),
      if (translation.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(translation, textAlign: TextAlign.center, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 15.5, height: 1.45)),
      ],
    ]);
  }
}

/// Reports the size of its child after layout.
class _Measure extends SingleChildRenderObjectWidget {
  const _Measure({required this.onSize, required super.child});
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _MeasureBox(onSize);

  @override
  void updateRenderObject(BuildContext context, covariant _MeasureBox renderObject) => renderObject.onSize = onSize;
}

class _MeasureBox extends RenderProxyBox {
  _MeasureBox(this.onSize);
  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (_last != size) {
      _last = size;
      onSize(size);
    }
  }
}

/// The verses as synced lyrics: the playing verse is large and bright, the rest sit back, blurred. When the recitation moves
/// to the next verse the list shifts and the lines follow one after another with a small delay, like a wave.
class _Lyrics extends StatefulWidget {
  const _Lyrics({super.key, required this.surah, required this.current, required this.controller, required this.tr, required this.store, required this.onPick, this.big = false, this.selecting = false, this.selected = const {}});
  final bool selecting;
  final Set<int> selected;
  final int surah, current;
  final ItemScrollController controller;
  final TranslationModel tr;
  final AppStore store;
  final ValueChanged<int> onPick;
  final bool big;

  @override
  State<_Lyrics> createState() => _LyricsState();
}

class _LyricsState extends State<_Lyrics> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000), value: 1);
  final Map<int, double> _heights = {};
  double _shift = 0; // how far the lines have to travel (positive: they were lower)
  int _focus = 0; // the verse the wave is travelling towards

  double get _align => widget.big ? 0.36 : 0.3;

  @override
  void initState() {
    super.initState();
    _focus = widget.current;
  }

  @override
  void didUpdateWidget(covariant _Lyrics old) {
    super.didUpdateWidget(old);
    if (old.current == widget.current && old.surah == widget.surah) return;
    final c = widget.controller;
    if (!c.isAttached) return;
    final step = widget.current - old.current;
    if (old.surah == widget.surah && step.abs() == 1 && widget.store.motion) {
      // the list moves at once and every line starts from where it was, then glides into place in turn
      final h = ((_heights[old.current] ?? 120) + (_heights[widget.current] ?? 120)) / 2;
      _shift = step * h;
      _focus = widget.current;
      c.jumpTo(index: widget.current - 1, alignment: _align);
      _wave.forward(from: 0);
    } else if (widget.store.motion) {
      _shift = 0;
      c.scrollTo(index: widget.current - 1, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic, alignment: _align);
    } else {
      c.jumpTo(index: widget.current - 1, alignment: _align);
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sr = Quran.I.surah(widget.surah);
    final motion = widget.store.motion;
    final big = widget.big;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: big ? 760 : 680),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent], stops: [0, 0.1, 0.9, 1]).createShader(r),
          child: ScrollablePositionedList.builder(
            itemScrollController: widget.controller,
            initialScrollIndex: widget.current - 1,
            initialAlignment: _align,
            itemCount: sr.ayahs.length,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.symmetric(vertical: big ? 160 : 80, horizontal: 24),
            itemBuilder: (_, i) {
              final a = sr.ayahs[i];
              final on = a.n == widget.current;
              final picked = widget.selecting && widget.selected.contains(a.n);
              Widget line = _Measure(
                onSize: (z) => _heights[a.n] = z.height,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.symmetric(vertical: big ? 14 : 10, horizontal: 10),
                  decoration: BoxDecoration(color: picked ? Colors.white.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                  child: Column(children: [
                    LiveVerse(ayah: a, fontSize: big ? 40 : 32, color: Colors.white, activeColor: Colors.white, dimmed: true),
                    if (widget.store.showTranslation) Padding(padding: const EdgeInsets.only(top: 8), child: Text(widget.tr.text(a), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: on ? 0.95 : 0.8), fontSize: big ? 17 : 15, height: 1.45))),
                  ]),
                ),
              );
              if (motion) {
                line = TweenAnimationBuilder<double>(
                  tween: Tween(end: (on || widget.selecting) ? 0 : 2.2),
                  duration: const Duration(milliseconds: 350),
                  builder: (_, sigma, child) => sigma < 0.05 ? child! : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal), child: child),
                  child: line,
                );
              }
              Widget item = MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onPick(a.n),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: (on || widget.selecting) ? 1 : 0.4,
                    child: AnimatedScale(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, scale: (on || widget.selecting) ? 1 : 0.92, child: line),
                  ),
                ),
              );
              if (!motion) return item;
              return AnimatedBuilder(
                animation: _wave,
                child: item,
                builder: (_, child) {
                  if (_wave.value >= 1 || _shift == 0) return child!;
                  // lines above the playing verse set off first; the playing verse and those below follow, each a little later
                  final behind = (a.n - _focus).clamp(0, 8);
                  final delay = behind * 0.05;
                  final p = Curves.easeInOutCubic.transform(((_wave.value - delay) / (1 - delay)).clamp(0.0, 1.0));
                  return Transform.translate(offset: Offset(0, _shift * (1 - p)), child: child);
                },
              );
            },
          ),
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
        IconButton(onPressed: audio.previousSurah, tooltip: 'Previous surah', icon: const Icon(Icons.fast_rewind_rounded, size: 30, color: white)),
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
        IconButton(onPressed: audio.nextSurah, tooltip: 'Next surah', icon: const Icon(Icons.fast_forward_rounded, size: 30, color: white)),
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
