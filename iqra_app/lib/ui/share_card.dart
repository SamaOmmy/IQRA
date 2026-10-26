import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/share_targets.dart';
import '../core/store.dart';
import 'widgets.dart';

/// Opens the share screen for a verse or hadith, in the style of Apple Music's "share lyrics": a picture card to swipe through the
/// looks of, and a row of apps below it to send it straight to (WhatsApp status, Instagram…), or to save.
/// [surah] and [subtitle] (for example the reciter) fill the small cover line at the foot of the card.
Future<void> showShareCard(BuildContext context, {required String arabic, required String translation, required String reference, int? surah, String? subtitle}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => _ShareSheet(arabic: arabic, translation: translation, reference: reference, surah: surah, subtitle: subtitle),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child),
    ),
  );
}

class _Look {
  const _Look(this.name, this.a, this.b, this.text, {this.light = false});
  final String name;
  final Color a, b, text;
  final bool light;
}

Color _c(int v) => Color(v);

final _looks = <_Look>[
  for (final s in const [('Emerald', 0), ('Ocean', 1), ('Violet', 2), ('Rose', 3), ('Dusk', 11), ('Pine', 9)])
    _Look(s.$1, artColors(s.$2 * 5 + 2).$1, artColors(s.$2 * 5 + 2).$2, Colors.white),
  _Look('Paper', _c(0xFFF7F1E3), _c(0xFFEADFC4), _c(0xFF2A2418), light: true),
  _Look('Night', _c(0xFF0A0E13), _c(0xFF1C2631), Colors.white),
];

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.arabic, required this.translation, required this.reference, this.surah, this.subtitle});
  final String arabic, translation, reference;
  final int? surah;
  final String? subtitle;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _keys = List.generate(_looks.length, (_) => GlobalKey());
  late int _look = context.read<AppStore>().uiInt('shareStyle', 0).clamp(0, _looks.length - 1);
  late int _format = context.read<AppStore>().uiInt('shareFormat', 1); // 0 post (4:5), 1 story (9:16: WhatsApp status, Instagram stories)
  late final PageController _pager = PageController(initialPage: _look, viewportFraction: 0.8);
  List<ShareApp> _apps = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ShareTargets.installed().then((a) {
      if (mounted) setState(() => _apps = a);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  String get _caption => '${widget.reference}  ·  IQRA';

  Future<File> _render() async {
    final b = _keys[_look].currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}${Platform.pathSeparator}iqra-share-${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(data!.buffer.asUint8List());
    return f;
  }

  String get _fileName => 'IQRA-${widget.reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.png';

  Future<void> _run(Future<void> Function(File f) job, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job(await _render());
    } catch (_) {
      if (mounted) showToast(context, failure);
    }
    if (mounted) setState(() => _busy = false);
  }

  void _toApp(ShareApp app) => _run((f) async {
        final ok = await ShareTargets.send(f.path, pkg: app.pkg, text: _caption);
        if (!ok && mounted) showToast(context, 'Could not open ${app.label}');
      }, 'Could not share the image');

  void _system() => _run((f) async {
        if (Platform.isAndroid && await ShareTargets.send(f.path, text: _caption)) return;
        await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: _caption));
      }, 'Could not share the image');

  void _save() => _run((f) async {
        if (await ShareTargets.saveToGallery(f.path, _fileName)) {
          if (mounted) showToast(context, 'Saved to your gallery (Pictures/IQRA)');
          return;
        }
        Directory? target;
        try {
          target = await getDownloadsDirectory();
        } catch (_) {}
        target ??= await getApplicationDocumentsDirectory();
        final out = File('${target.path}${Platform.pathSeparator}$_fileName');
        await f.copy(out.path);
        if (mounted) showToast(context, 'Saved to ${out.path}');
      }, 'Could not save the image');

  /// Windows: puts the picture on the clipboard, ready to paste into WhatsApp Web / Desktop, a document or a message.
  void _copy() => _run((f) async {
        final r = await Process.run('powershell', [
          '-NoProfile',
          '-STA',
          '-Command',
          "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; \$i=[System.Drawing.Image]::FromFile('${f.path}'); [System.Windows.Forms.Clipboard]::SetImage(\$i); \$i.Dispose()",
        ]);
        if (r.exitCode != 0) throw StateError('clipboard');
        if (mounted) showToast(context, 'Picture copied: paste it into WhatsApp or anywhere');
      }, 'Could not copy the image');

  IconData _icon(String pkg) => switch (pkg) {
        'com.instagram.android' => Icons.camera_alt_rounded,
        'org.telegram.messenger' => Icons.send_rounded,
        'com.facebook.katana' => Icons.facebook_rounded,
        'com.snapchat.android' => Icons.camera_rounded,
        'com.twitter.android' => Icons.alternate_email_rounded,
        _ => Icons.chat_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final aspect = _format == 0 ? 4 / 5 : 9 / 16;
    final targets = <Widget>[
      for (final a in _apps) _Target(icon: _icon(a.pkg), label: a.label, color: Color(a.color), dark: a.pkg == 'com.snapchat.android', onTap: _busy ? null : () => _toApp(a)),
      if (Platform.isWindows) _Target(icon: Icons.content_copy_rounded, label: 'Copy image', color: const Color(0xFF3A3A3C), onTap: _busy ? null : _copy),
      _Target(icon: Icons.ios_share_rounded, label: 'More…', color: const Color(0xFF3A3A3C), onTap: _busy ? null : _system),
      _Target(icon: Icons.download_rounded, label: 'Save', color: const Color(0xFF3A3A3C), onTap: _busy ? null : _save),
    ];
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
                  child: Row(children: [
                    const Expanded(child: Text('Share', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                  ]),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    itemCount: _looks.length,
                    onPageChanged: (i) {
                      setState(() => _look = i);
                      context.read<AppStore>().setUiInt('shareStyle', i);
                    },
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _pager,
                      builder: (context, child) {
                        final page = _pager.hasClients && _pager.position.haveDimensions ? (_pager.page ?? _look.toDouble()) : _look.toDouble();
                        final near = (1 - (page - i).abs()).clamp(0.0, 1.0);
                        return Transform.scale(scale: 0.9 + 0.1 * near, child: Opacity(opacity: 0.55 + 0.45 * near, child: child));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: aspect,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: RepaintBoundary(
                                  key: _keys[i],
                                  child: SizedBox(
                                    width: 360,
                                    height: 360 / aspect,
                                    child: _Card(look: _looks[i], arabic: widget.arabic, translation: widget.translation, reference: widget.reference, surah: widget.surah, subtitle: widget.subtitle),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < _looks.length; i++)
                    GestureDetector(
                      onTap: () => _pager.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _look ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: i == _look ? 0.95 : 0.35), borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(_looks[_look].name, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _FormatChip('Story', Icons.smartphone_rounded, _format == 1, () {
                    setState(() => _format = 1);
                    context.read<AppStore>().setUiInt('shareFormat', 1);
                  }),
                  const SizedBox(width: 10),
                  _FormatChip('Post', Icons.crop_portrait_rounded, _format == 0, () {
                    setState(() => _format = 0);
                    context.read<AppStore>().setUiInt('shareFormat', 0);
                  }),
                ]),
                const SizedBox(height: 18),
                SizedBox(
                  height: 92,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: targets,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip(this.label, this.icon, this.on, this.onTap);
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: on ? Colors.white : Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(30)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: on ? Colors.black87 : Colors.white),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? Colors.black87 : Colors.white)),
          ]),
        ),
      );
}

class _Target extends StatelessWidget {
  const _Target({required this.icon, required this.label, required this.color, required this.onTap, this.dark = false});
  final IconData icon;
  final String label;
  final Color color;
  final bool dark; // a light brand colour that needs a dark glyph
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: SizedBox(
              width: 74,
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: dark ? Colors.black87 : Colors.white, size: 28),
                ),
                const SizedBox(height: 7),
                Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.15)),
              ]),
            ),
          ),
        ),
      );
}

/// The picture itself, laid out like a shared lyric: the words large and bold, and a small cover line (surah, reference, reciter) below.
class _Card extends StatelessWidget {
  const _Card({required this.look, required this.arabic, required this.translation, required this.reference, this.surah, this.subtitle});
  final _Look look;
  final String arabic, translation, reference;
  final int? surah;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final n = arabic.length;
    final arSize = n < 60 ? 36.0 : (n < 140 ? 30.0 : (n < 300 ? 24.0 : 19.0));
    final trSize = n < 140 ? 16.5 : (n < 300 ? 14.5 : 12.5);
    final text = look.text;
    final soft = text.withValues(alpha: look.light ? 0.74 : 0.88);
    final tile = artColors((surah ?? 1) * 5 + 2);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [look.a, look.b])),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _CardPattern(text.withValues(alpha: look.light ? 0.07 : 0.10)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 304,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(arabic, textAlign: TextAlign.right, style: TextStyle(fontFamily: kArabicFont, color: text, fontSize: arSize, height: 1.95, fontWeight: FontWeight.w700)),
                      ),
                      if (translation.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(translation, textAlign: TextAlign.left, style: TextStyle(color: soft, fontSize: trSize, height: 1.42, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tile.$1, tile.$2])),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: ArtPatternPainter(surah ?? 1, const Color(0x40FFFFFF)))),
                    Center(
                      child: surah == null
                          ? const Text('اقرأ', style: TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 20, height: 1.2))
                          : Text('$surah', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(reference, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle ?? 'Qur’an', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text.withValues(alpha: 0.65), fontSize: 12.5, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 10),
              Text('IQRA', style: TextStyle(color: text.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _CardPattern extends CustomPainter {
  _CardPattern(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final cx = size.width * 0.9, cy = size.height * 0.08;
    for (var ring = 1; ring <= 7; ring++) {
      final r = size.width * 0.15 * ring;
      for (var k = 0; k < 2; k++) {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = (math.pi / 4) * k + i * math.pi / 2;
          final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardPattern old) => old.color != color;
}
