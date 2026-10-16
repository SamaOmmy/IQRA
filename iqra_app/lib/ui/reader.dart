import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/audio.dart';
import '../core/content.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/translation.dart';
import 'mushaf.dart';
import 'live_verse.dart';
import 'share_card.dart';
import 'study.dart';
import 'word_grid.dart';
import 'widgets.dart';

Future<void> openReader(BuildContext context, {required int surah, int ayah = 1, int? page, bool? mushaf}) {
  return Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => ReaderScreen(surah: surah, ayah: ayah, page: page, mushaf: mushaf),
    transitionsBuilder: (_, a, __, child) {
      final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curve), child: child),
      );
    },
  ));
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.surah, this.ayah = 1, this.page, this.mushaf});
  final int surah, ayah;
  final int? page;
  final bool? mushaf;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late bool _mushaf;
  late int _page;
  late int _surah;
  VerseRef? _selected;
  PageController? _pager;
  final _items = ItemScrollController();
  final _focus = FocusNode();
  Timer? _markTimer;
  late final AudioController _audio;

  bool _wide = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _mushaf = widget.mushaf ?? store.mushafView;
    _surah = widget.surah;
    _page = widget.page ?? Quran.I.ayah(widget.surah, widget.ayah).page;
    _selected = widget.page == null ? VerseRef(widget.surah, widget.ayah) : null;
    _scheduleMark();
    _audio = context.read<AudioController>();
    _audio.addListener(_followAudio);
  }

  @override
  void dispose() {
    _markTimer?.cancel();
    _pager?.dispose();
    _focus.dispose();
    _audio.removeListener(_followAudio);
    super.dispose();
  }

  void _scheduleMark() {
    _markTimer?.cancel();
    final store = context.read<AppStore>();
    _markTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      store.markPageRead(_page);
    });
  }

  int get _spreadIndex => (_page - 1) ~/ 2;

  void _goToPage(int p, {bool animate = true}) {
    p = p.clamp(1, 604);
    if (_pager != null && _pager!.hasClients) {
      final idx = _wide ? (p - 1) ~/ 2 : p - 1;
      animate ? _pager!.animateToPage(idx, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic) : _pager!.jumpToPage(idx);
    }
    setState(() => _page = p);
  }

  void _onPageChanged(int idx) {
    final p = _wide ? idx * 2 + 1 : idx + 1;
    if (p == _page) return;
    setState(() => _page = p);
    final first = Quran.I.pageWords(p).first;
    context.read<AppStore>().setLast(first.surah, first.ayah, p);
    _scheduleMark();
    HapticFeedback.selectionClick();
  }

  void _followAudio() {
    if (!mounted) return;
    final cur = _audio.current;
    if (cur == null) return;
    final ay = Quran.I.ayah(cur.s, cur.a);
    if (_mushaf) {
      final target = _wide ? (ay.page - 1) ~/ 2 : ay.page - 1;
      final shown = _wide ? _spreadIndex : _page - 1;
      if (target != shown && _pager != null && _pager!.hasClients && context.read<AppStore>().motion) {
        _pager!.animateToPage(target, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
        setState(() => _page = _wide ? target * 2 + 1 : target + 1);
      }
    } else if (cur.s == _surah && _items.isAttached) {
      _items.scrollTo(index: cur.a, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic, alignment: 0.15);
    }
  }

  VerseRef? _panel; // the verse shown in the side panel (wide windows)

  bool get _dock => MediaQuery.of(context).size.width >= 1240;

  /// A verse was chosen: on wide windows it opens in the side panel, elsewhere in a sheet.
  void _openVerse(int s, int a, int page) {
    setState(() => _selected = VerseRef(s, a));
    if (_dock) {
      setState(() => _panel = VerseRef(s, a));
      return;
    }
    showVerseSheet(context, s, a, page: page).then((_) {
      if (mounted) setState(() => _selected = null);
    });
  }

  void _tapVerse(int s, int a, int page) => _openVerse(s, a, page);

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent || !_mushaf) return KeyEventResult.ignored;
    // pages run right to left: the left arrow turns forward
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPage(_page + (_wide ? 2 : 1));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToPage(_page - (_wide ? 2 : 1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final audio = context.watch<AudioController>();
    final surahForPage = Quran.I.pageWords(_page).first.surah;
    final headerSurah = _mushaf ? surahForPage : _surah;
    final sr = Quran.I.surah(headerSurah);
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: c.bg,
        body: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56),
              child: Row(children: [
                Expanded(child: _mushaf ? _buildMushaf(store, audio) : _buildVerses(store, audio)),
                if (_dock && _panel != null)
                  _SidePanel(
                    key: ValueKey('panel-${_panel!.key}'),
                    ref: _panel!,
                    onClose: () => setState(() {
                      _panel = null;
                      _selected = null;
                    }),
                  ),
              ]),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Glass(
              blur: 30,
              opacity: 0.8,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Row(children: [
                    const SizedBox(width: 6),
                    IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _mushaf ? _askPage : null,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(sr.en, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                        Text(_mushaf ? 'Page $_page · Juz ${Quran.I.ayah(Quran.I.pageWords(_page).first.surah, Quran.I.pageWords(_page).first.ayah).juz}' : '${sr.meaning} · ${sr.ayahs.length} verses',
                            style: TextStyle(fontSize: 12, color: c.textSecondary)),
                        ]),
                      ),
                    ),
                    if (MediaQuery.of(context).size.width < 520)
                      IconButton(
                        onPressed: () => _switchMode(!_mushaf),
                        tooltip: _mushaf ? 'Verse by verse' : 'Mushaf pages',
                        icon: Icon(_mushaf ? Icons.view_agenda_outlined : Icons.menu_book_rounded),
                      )
                    else
                      Segmented(items: const ['Mushaf', 'Verses'], index: _mushaf ? 0 : 1, onChanged: (i) => _switchMode(i == 0)),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () {
                        final first = _mushaf ? Quran.I.pageWords(_page).first : null;
                        final s = _mushaf ? first!.surah : _surah;
                        final a = _mushaf ? first!.ayah : (_selected?.a ?? 1);
                        audio.playVerse(s, a, scope: PlayScope.continuous);
                      },
                      icon: Icon(Icons.play_circle_fill_rounded, color: c.accent, size: 30),
                    ),
                    IconButton(onPressed: () => _readerSettings(context), icon: const Icon(Icons.text_fields_rounded)),
                    const SizedBox(width: 4),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _askPage() {
    final ctl = TextEditingController(text: '$_page');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(controller: ctl, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '1 – 604'), onSubmitted: (_) {
          final p = int.tryParse(ctl.text.trim());
          Navigator.pop(ctx);
          if (p != null && p >= 1 && p <= 604) _goToPage(p, animate: false);
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(ctl.text.trim());
              Navigator.pop(ctx);
              if (p != null && p >= 1 && p <= 604) _goToPage(p, animate: false);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _switchMode(bool mushaf) {
    final store = context.read<AppStore>();
    store.mushafView = mushaf;
    setState(() {
      if (!mushaf) {
        final first = Quran.I.pageWords(_page).first;
        _surah = first.surah;
      } else {
        _page = _selected != null ? Quran.I.ayah(_selected!.s, _selected!.a).page : Quran.I.surah(_surah).firstPage;
      }
      _mushaf = mushaf;
      _pager?.dispose();
      _pager = null;
    });
  }

  // ---------------- mushaf ----------------
  Widget _buildMushaf(AppStore store, AudioController audio) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 1000 && store.mushafView;
      if (wide != _wide || _pager == null) {
        _wide = wide;
        _pager?.dispose();
        _pager = PageController(initialPage: wide ? (_page - 1) ~/ 2 : _page - 1);
      }
      final availH = box.maxHeight - 24;
      final onePageW = (availH * 0.72).clamp(260.0, box.maxWidth - 16);
      final pageW = _wide ? ((box.maxWidth - 40) / 2).clamp(260.0, availH * 0.78) : onePageW;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(children: [
          PageView.builder(
            controller: _pager,
            itemCount: _wide ? 302 : 604,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              Widget pageFor(int p) => SizedBox(
                    width: pageW,
                    height: availH,
                    child: MushafPage(
                      page: p,
                      playing: audio.current,
                      selected: _selected,
                      fontScale: store.arabicSize > 0 ? 1 : 1,
                      onVerseTap: _tapVerse,
                    ),
                  );
              return Center(
                child: _wide
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        pageFor(i * 2 + 1),
                        const SizedBox(width: 14),
                        if (i * 2 + 2 <= 604) pageFor(i * 2 + 2),
                      ])
                    : pageFor(i + 1),
              );
            },
          ),
          // desktop paging arrows
          if (box.maxWidth > 700) ...[
            Positioned(left: 8, top: 0, bottom: 0, child: Center(child: _arrow(Icons.chevron_left_rounded, () => _goToPage(_page + (_wide ? 2 : 1))))),
            Positioned(right: 8, top: 0, bottom: 0, child: Center(child: _arrow(Icons.chevron_right_rounded, () => _goToPage(_page - (_wide ? 2 : 1))))),
          ],
        ]),
      );
    });
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      radius: 100,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.85), shape: BoxShape.circle),
        child: Icon(icon, size: 28, color: c.text),
      ),
    );
  }

  // ---------------- verses ----------------
  Widget _buildVerses(AppStore store, AudioController audio) {
    final c = context.c;
    final sr = Quran.I.surah(_surah);
    final tr = context.watch<TranslationModel>();
    final showBism = _surah != 1 && _surah != 9;
    final intro = Content.I.surahIntro(_surah);
    final count = sr.ayahs.length + 1; // header + verses
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ScrollablePositionedList.builder(
          itemScrollController: _items,
          initialScrollIndex: widget.ayah.clamp(1, sr.ayahs.length),
          itemCount: count + 1,
          padding: const EdgeInsets.only(bottom: 160),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(children: [
                  Reveal(child: SurahArt(surah: _surah, size: 168)),
                  const SizedBox(height: 16),
                  Text(sr.en, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text('${sr.meaning} · ${sr.meccan ? 'Meccan' : 'Medinan'} · ${sr.ayahs.length} verses', style: TextStyle(color: c.textSecondary, fontSize: 14.5)),
                  if (intro.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(intro, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 14.5, height: 1.5)),
                  ],
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FilledButton.icon(
                      onPressed: () => audio.playVerse(_surah, 1, scope: PlayScope.surah),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                      style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14)),
                    ),
                  ]),
                  if (showBism)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Text(Quran.I.bismillah, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: kArabicFont, fontSize: store.arabicSize + 4, color: c.text)),
                    ),
                ]),
              );
            }
            if (index > sr.ayahs.length) return const SizedBox(height: 24);
            final ay = sr.ayahs[index - 1];
            return _VerseTile(
              ayah: ay,
              translation: store.showTranslation ? tr.text(ay) : '',
              playing: audio.current != null && audio.current!.s == ay.surah && audio.current!.a == ay.n,
              selected: _selected != null && _selected!.s == ay.surah && _selected!.a == ay.n,
              onTap: () {
                store.setLast(ay.surah, ay.n, ay.page);
                _openVerse(ay.surah, ay.n, ay.page);
              },
              onPlay: () => audio.playVerse(ay.surah, ay.n, scope: PlayScope.surah),
            );
          },
        ),
      ),
    );
  }

  void _readerSettings(BuildContext context) {
    final c = context.c;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Glass(
            blur: 40,
            opacity: 0.94,
            radius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Consumer<AppStore>(
              builder: (_, store, __) => SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Reading', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text('Arabic size', style: TextStyle(color: c.textSecondary)),
                    Slider(min: 22, max: 48, value: store.arabicSize.clamp(22, 48), onChanged: (v) => store.arabicSize = v),
                    Text('Translation size', style: TextStyle(color: c.textSecondary)),
                    Slider(min: 13, max: 26, value: store.translationSize.clamp(13, 26), onChanged: (v) => store.translationSize = v),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show translation'),
                      value: store.showTranslation,
                      onChanged: (v) => store.showTranslation = v,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Word by word'),
                      subtitle: const Text('Meaning and transliteration under every word'),
                      value: store.wordByWord,
                      onChanged: (v) => store.wordByWord = v,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Transliteration'),
                      subtitle: const Text('Read the verse in Latin letters'),
                      value: store.transliteration,
                      onChanged: (v) => store.transliteration = v,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Memorisation mode'),
                      subtitle: const Text('Hides the Arabic until you tap it'),
                      value: store.hifzMode,
                      onChanged: (v) => store.hifzMode = v,
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseTile extends StatefulWidget {
  const _VerseTile({required this.ayah, required this.translation, required this.playing, required this.selected, required this.onTap, required this.onPlay});
  final Ayah ayah;
  final String translation;
  final bool playing, selected;
  final VoidCallback onTap, onPlay;

  @override
  State<_VerseTile> createState() => _VerseTileState();
}

class _VerseTileState extends State<_VerseTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final ay = widget.ayah;
    final hidden = store.hifzMode && !_revealed;
    final active = widget.playing || widget.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        decoration: BoxDecoration(
          color: widget.playing ? c.accent.withValues(alpha: 0.1) : (widget.selected ? c.surface : Colors.transparent),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Pressable(
          onTap: widget.onTap,
          onSecondaryTap: widget.onTap,
          radius: 18,
          scale: 0.99,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: active ? c.accent : c.surface, shape: BoxShape.circle),
                  child: Text('${ay.n}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? c.onAccent : c.textSecondary)),
                ),
                const Spacer(),
                if (store.memorised.contains('${ay.surah}:${ay.n}')) Icon(Icons.check_circle_rounded, size: 18, color: c.accent),
                if (store.isBookmarked(ay.surah, ay.n)) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.bookmark_rounded, size: 18, color: c.accent)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onPlay,
                  icon: Icon(widget.playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded, color: widget.playing ? c.accent : c.textSecondary),
                ),
              ]),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: hidden ? () => setState(() => _revealed = true) : widget.onTap,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: hidden
                        ? Container(
                            key: const ValueKey('hidden'),
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
                            child: Text('Tap to reveal', style: TextStyle(color: c.textSecondary)),
                          )
                        : (store.wordByWord
                            ? WordGrid(key: const ValueKey('wbw'), ayah: ay, fontSize: store.arabicSize)
                            : LiveVerse(key: const ValueKey('shown'), ayah: ay, fontSize: store.arabicSize, height: 1.95, align: WrapAlignment.start)),
                  ),
                ),
              ),
              if (store.transliteration && !hidden) Transliteration(ayah: ay),
              if (widget.translation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(widget.translation, style: TextStyle(fontSize: store.translationSize, height: 1.5, color: c.textSecondary)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}


/// The study panel docked beside the reader on wide windows: actions on top, then translation, words, tafsir and notes.
class _SidePanel extends StatelessWidget {
  const _SidePanel({super.key, required this.ref, required this.onClose});
  final VerseRef ref;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final audio = context.read<AudioController>();
    final key = ref.key;
    Widget act(IconData icon, String tip, VoidCallback onTap, {bool on = false}) => IconButton(
          tooltip: tip,
          onPressed: onTap,
          icon: Icon(icon, size: 22, color: on ? c.accent : c.text),
        );
    return Container(
      width: 400,
      decoration: BoxDecoration(color: c.bg, border: Border(left: BorderSide(color: c.separator, width: 0.8))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
          child: Row(children: [
            act(Icons.play_arrow_rounded, 'Play from here', () => audio.playVerse(ref.s, ref.a, scope: PlayScope.continuous)),
            act(Icons.loop_rounded, 'Loop a range', () => showLoopDialog(context, ref.s, ref.a)),
            act(store.isBookmarked(ref.s, ref.a) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 'Bookmark', () => store.toggleBookmark(ref.s, ref.a), on: store.isBookmarked(ref.s, ref.a)),
            act(store.isFav(key) ? Icons.favorite_rounded : Icons.favorite_border_rounded, 'Favourite', () => store.toggleFav(key), on: store.isFav(key)),
            act(store.memorised.contains(key) ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, 'Memorised', () => store.toggleMemorised(key), on: store.memorised.contains(key)),
            act(Icons.image_rounded, 'Share as image', () {
              final a = Quran.I.ayah(ref.s, ref.a);
              showShareCard(context, arabic: a.ar, translation: context.read<TranslationModel>().text(a), reference: '${Quran.I.surah(ref.s).en} $key');
            }),
            const Spacer(),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          ]),
        ),
        Expanded(child: StudyPanel(s: ref.s, a: ref.a)),
      ]),
    );
  }
}
