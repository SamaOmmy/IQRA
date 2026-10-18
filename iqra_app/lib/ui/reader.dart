import 'dart:async';
import 'dart:math' as math;

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
import 'book_flip.dart';
import 'mushaf.dart';
import 'live_verse.dart';
import 'share_card.dart';
import 'shell.dart';
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
  final _book = GlobalKey<BookFlipState>();
  final _items = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  int? _visibleAyah; // verse view: the verse at the top of the screen
  late int _startAyah = widget.ayah; // verse view: the verse the list opens at
  Timer? _scrollTimer;
  final _openedAt = DateTime.now();
  final _focus = FocusNode();
  Timer? _markTimer;
  late final AudioController _audio;

  bool _wide = false;
  bool _ready = false; // the open animation is over: the page itself is built after it, not during it
  bool _routeWatched = false;

  /// dev hook: the reader on screen
  static _ReaderScreenState? debugCurrent;
  void debugFlip(int toPage, int ms) => _book.currentState?.turnTo(_wide ? (toPage - 1) ~/ 2 : toPage - 1, duration: Duration(milliseconds: ms), curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    debugCurrent = this;
    Future.microtask(() => readerOpen.value++);
    final store = context.read<AppStore>();
    _mushaf = widget.mushaf ?? store.mushafView;
    _surah = widget.surah;
    _page = widget.page ?? Quran.I.ayah(widget.surah, widget.ayah).page;
    _selected = widget.page == null ? VerseRef(widget.surah, widget.ayah) : null;
    _scheduleMark();
    _prefetchFonts(_page);
    _positions.itemPositions.addListener(_onVersePositions);
    _audio = context.read<AudioController>();
    final playing = _audio.current;
    if (playing != null) _followed = playing.s * 1000 + playing.a; // follow changes from here, not where it already was
    _audio.addListener(_followAudio);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeWatched) return;
    _routeWatched = true;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted || !context.read<AppStore>().motion) {
      _ready = true;
      return;
    }
    void done(AnimationStatus st) {
      if (st != AnimationStatus.completed) return;
      anim.removeStatusListener(done);
      if (mounted && !_ready) setState(() => _ready = true);
    }

    anim.addStatusListener(done);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_ready) setState(() => _ready = true);
    });
  }

  /// Verse view: where the person has read to is remembered (Continue reading) and the page counts as read after a few seconds,
  /// as it does when turning mushaf pages.
  void _onVersePositions() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _mushaf) return;
      if (DateTime.now().difference(_openedAt) < const Duration(milliseconds: 1600)) return; // the first layout is not the person reading
      final n = Quran.I.surah(_surah).ayahs.length;
      final shown = _positions.itemPositions.value.where((p) => p.index >= 1 && p.index <= n && p.itemTrailingEdge > 0.15);
      if (shown.isEmpty) return;
      final top = shown.reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);
      final ay = Quran.I.ayah(_surah, top.index);
      _visibleAyah = ay.n;
      final newPage = ay.page != _page;
      _page = ay.page;
      context.read<AppStore>().setLast(_surah, ay.n, ay.page);
      if (newPage || _markTimer == null || !_markTimer!.isActive) _scheduleMark();
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _positions.itemPositions.removeListener(_onVersePositions);
    if (debugCurrent == this) debugCurrent = null;
    Future.microtask(() => readerOpen.value--);
    _markTimer?.cancel();
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

  void _goToPage(int p, {bool animate = true}) {
    p = p.clamp(1, 604);
    final idx = _wide ? (p - 1) ~/ 2 : p - 1;
    final b = _book.currentState;
    if (b == null) {
      setState(() => _page = p);
      return;
    }
    animate ? b.turnTo(idx) : b.jumpTo(idx);
  }

  /// Turns by whole sheets (a spread on wide windows, otherwise one page); +1 is forward.
  void _turnBy(int delta) {
    final b = _book.currentState;
    if (b != null) b.turnTo(b.target + delta);
  }

  int _recorded = 0;
  int _followed = -1;

  /// The book settled on a sheet: remember the place.
  void _onSheet(int idx) {
    final p = _wide ? idx * 2 + 1 : idx + 1;
    if (p != _page) setState(() => _page = p);
    if (p == _recorded) return;
    _recorded = p;
    final first = Quran.I.pageWords(p).first;
    context.read<AppStore>().setLast(first.surah, first.ayah, p);
    _scheduleMark();
    HapticFeedback.selectionClick();
    _prefetchFonts(p);
  }

  /// Loads the fonts of the pages around this one so that turning to them shows the right letters at once.
  Future<void> _prefetchFonts(int p) async {
    for (final q in [p, p + 1, p - 1, p + 2, p - 2, p + 3, p + 4, p - 3]) {
      if (!mounted) return;
      if (q < 1 || q > 604) continue;
      await MushafPage.prepare(q);
      await Future<void>.delayed(const Duration(milliseconds: 30)); // one page per gap, so no single frame is held up
    }
  }

  void _followAudio() {
    if (!mounted) return;
    final cur = _audio.current;
    if (cur == null) return;
    // only when the verse changes: the audio reports its position many times a second, and the reader may be paging by hand
    final key = cur.s * 1000 + cur.a;
    if (key == _followed) return;
    _followed = key;
    final ay = Quran.I.ayah(cur.s, cur.a);
    if (_mushaf) {
      final b = _book.currentState;
      if (b == null) return;
      final target = _wide ? (ay.page - 1) ~/ 2 : ay.page - 1;
      if (target != b.target) {
        b.turnTo(target, duration: const Duration(milliseconds: 800));
        if (context.read<AppStore>().mushafZoom > 1) b.scrollToFraction(_verseFraction(ay), animate: false);
      } else if (context.read<AppStore>().mushafZoom > 1) {
        // a tall page: keep the verse being recited in view
        b.scrollToFraction(_verseFraction(ay));
      }
    } else if (cur.s == _surah && _items.isAttached) {
      _items.scrollTo(index: cur.a, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic, alignment: 0.15);
    }
  }

  /// Roughly how far down its page a verse starts (0 top .. 1 bottom), from the words before it.
  double _verseFraction(Ayah ay) {
    final words = Quran.I.pageWords(ay.page);
    final i = words.indexWhere((w) => w.surah == ay.surah && w.ayah == ay.n);
    if (i <= 0 || words.isEmpty) return 0;
    return i / words.length;
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
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      // one step back at a time: the verse panel, then compact reading, then the reader itself
      if (_panel != null) {
        setState(() {
          _panel = null;
          _selected = null;
        });
      } else if (_mushaf && context.read<AppStore>().readerFocus) {
        context.read<AppStore>().readerFocus = false;
      } else {
        Navigator.of(context).maybePop();
      }
      return KeyEventResult.handled;
    }
    if (!_mushaf) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.space) {
      // play / pause what is being recited, or start from the top of this page
      if (_audio.current != null) {
        _audio.toggle();
      } else {
        final first = Quran.I.pageWords(_page).first;
        _audio.playVerse(first.surah, first.ayah, scope: PlayScope.continuous);
      }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyF && !HardwareKeyboard.instance.isControlPressed) {
      final st = context.read<AppStore>();
      st.readerFocus = !st.readerFocus;
      return KeyEventResult.handled;
    }
    // pages run right to left: the left arrow turns forward
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _turnBy(1);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _turnBy(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final audio = context.watch<AudioController>();
    final pageWordsNow = Quran.I.pageWords(_page);
    final midNow = pageWordsNow[pageWordsNow.length ~/ 2]; // the verse in the middle of the page names it, as on the page itself
    final surahForPage = midNow.surah;
    final headerSurah = _mushaf ? surahForPage : _surah;
    final sr = Quran.I.surah(headerSurah);
    final focus = store.readerFocus && _mushaf;
    final top = MediaQuery.of(context).padding.top;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: c.bg,
        body: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: top + (focus ? 2 : 56), bottom: MediaQuery.of(context).padding.bottom),
              child: Row(children: [
                Expanded(child: !_ready ? const SizedBox.expand() : (_mushaf ? _buildMushaf(store, audio) : _buildVerses(store, audio))),
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
            child: IgnorePointer(
              ignoring: focus,
              child: AnimatedSlide(
                offset: focus ? const Offset(0, -1.2) : Offset.zero,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
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
                        Text(_mushaf ? 'Page $_page · Juz ${Quran.I.ayah(midNow.surah, midNow.ayah).juz}' : '${sr.meaning} · ${sr.ayahs.length} verses',
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
                        // verse view: from the chosen verse if it is still on screen, otherwise from the verse at the top
                        final sel = _selected?.a, vis = _visibleAyah;
                        final a = _mushaf ? first!.ayah : ((sel != null && (vis == null || (sel - vis).abs() < 8)) ? sel : (vis ?? sel ?? 1));
                        audio.playVerse(s, a, scope: PlayScope.continuous);
                      },
                      icon: Icon(Icons.play_circle_fill_rounded, color: c.accent, size: 30),
                    ),
                    if (_mushaf) IconButton(onPressed: () => store.readerFocus = true, tooltip: 'Focus: hide this bar (F)', icon: const Icon(Icons.fullscreen_rounded)),
                    IconButton(onPressed: () => _readerSettings(context), icon: const Icon(Icons.text_fields_rounded)),
                    const SizedBox(width: 4),
                  ]),
                ),
              ),
            ),
              ),
            ),
          ),
          // while the bar is hidden, a small way back
          Positioned(
            top: top + 6,
            left: 8,
            child: AnimatedOpacity(
              opacity: focus ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !focus,
                child: Column(children: [
                  _chip(Icons.arrow_back_ios_new_rounded, 'Back', () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 8),
                  _chip(Icons.fullscreen_exit_rounded, 'Show the bar (F)', () => store.readerFocus = false),
                  const SizedBox(height: 8),
                  _chip(Icons.text_fields_rounded, 'Reading settings', () => _readerSettings(context)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String tip, VoidCallback onTap) {
    final c = context.c;
    return Tooltip(
      message: tip,
      child: Pressable(
        onTap: onTap,
        radius: 100,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.88), shape: BoxShape.circle, border: Border.all(color: c.separator, width: 0.6)),
          child: Icon(icon, size: 18, color: c.text),
        ),
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
        // to verse view: at the verse in the middle of the page being read (or the chosen verse, if it is on this page)
        final words = Quran.I.pageWords(_page);
        final mid = words[words.length ~/ 2];
        _surah = mid.surah;
        final sel = _selected;
        _startAyah = (sel != null && sel.s == mid.surah && Quran.I.ayah(sel.s, sel.a).page == _page) ? sel.a : words.first.surah == mid.surah ? words.first.ayah : mid.ayah;
        _visibleAyah = _startAyah;
      } else {
        // to mushaf: the page of the chosen verse, or of the verse that was at the top of the screen
        _page = _selected != null
            ? Quran.I.ayah(_selected!.s, _selected!.a).page
            : (_visibleAyah != null ? Quran.I.ayah(_surah, _visibleAyah!).page : Quran.I.ayah(_surah, _startAyah).page);
      }
      _mushaf = mushaf;
    });
  }

  // ---------------- mushaf ----------------
  Widget _buildMushaf(AppStore store, AudioController audio) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 1000 && store.mushafView;
      _wide = wide;
      final availH = box.maxHeight - 6;
      final side = box.maxWidth > 700 ? 64.0 : 8.0; // room for the paging arrows
      final slotW = wide ? (box.maxWidth - 2 * side) / 2 : box.maxWidth - 2 * side;
      // a page that fits the window, as printed ...
      var pageH = availH;
      var pageW = math.max(200.0, math.min(pageH * (wide ? 0.78 : 0.72), slotW));
      // ... or larger when there is room to the sides (the window then scrolls it up and down)
      final zoom = store.mushafZoom;
      if (zoom > 1) {
        pageH = math.min(availH * zoom, math.max(availH, slotW / 0.76));
        pageW = math.max(200.0, math.min(pageH * 0.76, slotW));
      }
      final index = wide ? (_page - 1) ~/ 2 : _page - 1;
      return Stack(children: [
        KeyedSubtree(
          // a new layout starts a new book, on the page being read
          key: ValueKey('book-$wide'),
          child: BookFlip(
          key: _book,
          index: index,
          count: wide ? 302 : 604,
          spread: wide,
          pageW: pageW,
          pageH: pageH,
          viewH: availH,
          motion: store.motion,
          onChanged: _onSheet,
          page: (p) => MushafPage(
            page: p,
            flat: !wide && box.maxWidth < 700,
            playing: audio.current,
            selected: _selected,
            fontScale: 1,
            onVerseTap: _tapVerse,
          ),
        )),
        if (box.maxWidth > 700) ...[
          Positioned(left: 8, top: 0, bottom: 0, child: Center(child: _arrow(Icons.chevron_left_rounded, () => _turnBy(1)))),
          Positioned(right: 8, top: 0, bottom: 0, child: Center(child: _arrow(Icons.chevron_right_rounded, () => _turnBy(-1)))),
        ],
      ]);
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
          itemPositionsListener: _positions,
          initialScrollIndex: _startAyah.clamp(1, sr.ayahs.length),
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
      isScrollControlled: true,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(ctx).size.height * 0.88),
          child: Glass(
            blur: 40,
            opacity: 0.94,
            radius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Consumer<AppStore>(
              builder: (_, store, __) => SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Reading', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (_mushaf)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Compact reading'),
                        subtitle: const Text('Hides the top bar so the whole page is as big as it can be (F)'),
                        value: store.readerFocus,
                        onChanged: (v) => store.readerFocus = v,
                      ),
                    if (_mushaf && MediaQuery.of(ctx).size.width > 700) ...[
                      Text('Page size', style: TextStyle(color: c.textSecondary)),
                      const SizedBox(height: 6),
                      Segmented(
                        items: const ['Fit', 'Large', 'Extra large'],
                        index: store.mushafZoom >= 1.4 ? 2 : (store.mushafZoom > 1.05 ? 1 : 0),
                        onChanged: (i) => store.mushafZoom = const [1.0, 1.25, 1.5][i],
                      ),
                      const SizedBox(height: 14),
                    ],
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
                  ])),
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

/// Debug builds only: lets the dev hook turn the mushaf page.
class ReaderDebug {
  static void flip(int toPage, int ms) => _ReaderScreenState.debugCurrent?.debugFlip(toPage, ms);
}
