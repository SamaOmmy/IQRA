import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import 'widgets.dart';

/// Opens a preview of a shareable picture card for a verse or hadith; the person can save it or share it.
Future<void> showShareCard(BuildContext context, {required String arabic, required String translation, required String reference}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _ShareCardDialog(arabic: arabic, translation: translation, reference: reference),
  );
}

const _styles = <(String, int)>[('Emerald', 0), ('Ocean', 1), ('Violet', 2), ('Rose', 3), ('Dusk', 11), ('Pine', 9)];

class _ShareCardDialog extends StatefulWidget {
  const _ShareCardDialog({required this.arabic, required this.translation, required this.reference});
  final String arabic, translation, reference;

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog> {
  final _key = GlobalKey();
  int _style = 0;
  int _format = 0; // 0 post (4:5), 1 story (9:16, for WhatsApp status and Instagram stories)
  bool _busy = false;

  Future<File> _render() async {
    final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}${Platform.pathSeparator}iqra-${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(data!.buffer.asUint8List());
    return f;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final f = await _render();
      Directory? target;
      try {
        target = await getDownloadsDirectory();
      } catch (_) {}
      target ??= await getApplicationDocumentsDirectory();
      final out = File('${target.path}${Platform.pathSeparator}IQRA-${widget.reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.png');
      await f.copy(out.path);
      if (mounted) showToast(context, 'Saved to ${out.path}');
    } catch (e) {
      if (mounted) showToast(context, 'Could not save the image');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final f = await _render();
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: '${widget.reference}  ·  IQRA'));
    } catch (e) {
      if (mounted) showToast(context, 'Could not share the image');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dialog(
      backgroundColor: c.bg,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(child: Text('Share as image', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RepaintBoundary(
                key: _key,
                child: _Card(arabic: widget.arabic, translation: widget.translation, reference: widget.reference, seed: _styles[_style].$2, aspect: _format == 0 ? 4 / 5 : 9 / 16),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Pill('Post', selected: _format == 0, onTap: () => setState(() => _format = 0)),
              Pill('Story / status', selected: _format == 1, onTap: () => setState(() => _format = 1)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _styles.length; i++) Pill(_styles[i].$1, selected: _style == i, onTap: () => setState(() => _style = i)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.download_rounded), label: const Text('Save'))),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.arabic, required this.translation, required this.reference, required this.seed, this.aspect = 4 / 5});
  final String arabic, translation, reference;
  final int seed;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final (a, b) = artColors(seed * 5 + 2);
    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _CardPattern(Colors.white.withValues(alpha: 0.12)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
            child: Column(children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 300,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(arabic, textAlign: TextAlign.center, style: const TextStyle(fontFamily: kArabicFont, color: Colors.white, fontSize: 30, height: 1.9)),
                        ),
                        if (translation.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(translation, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14.5, height: 1.5)),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, width: 56, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(reference, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('IQRA', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 3)),
            ]),
          ),
        ]),
      ),
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
    final cx = size.width / 2, cy = size.height * 0.46;
    for (var ring = 1; ring <= 6; ring++) {
      final r = size.width * 0.14 * ring;
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
