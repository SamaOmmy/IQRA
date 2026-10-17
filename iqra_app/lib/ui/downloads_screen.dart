import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_cache.dart';
import '../core/downloads.dart';
import '../core/quran.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'page_scaffold.dart';
import 'widgets.dart';

String _mb(int bytes) => bytes > 1e9 ? '${(bytes / 1e9).toStringAsFixed(2)} GB' : '${(bytes / 1e6).toStringAsFixed(1)} MB';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  int _bytes = 0;
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
    final b = await AudioCache.totalBytes();
    if (mounted) {
      setState(() {
        _cached = m;
        _bytes = b;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = context.watch<AppStore>();
    final dl = context.watch<DownloadManager>();
    final reciter = store.reciter;
    final tafsir = Quran.I.tafsirs.firstWhere((t) => t.id == store.tafsirId, orElse: () => Quran.I.tafsirs.first);

    Widget card(List<Widget> children) => Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
          child: Material(type: MaterialType.transparency, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        );

    final fullSurahs = [for (final s in Quran.I.surahs) if ((_cached[s.n] ?? 0) >= s.ayahs.length) s.n];

    return LargePage(
      title: 'Downloads',
      subtitle: '${_mb(_bytes)} on this device',
      maxWidth: 760,
      slivers: [
        SliverToBoxAdapter(
          child: card([
            Text('Recitation · ${reciterName(reciter)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text('${fullSurahs.length} of 114 surahs are fully available offline for this reciter. Change the reciter in Listen.', style: TextStyle(color: c.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.tonalIcon(
                onPressed: dl.busy ? null : () async {
                  await dl.downloadSurahs([for (var i = 78; i <= 114; i++) i], reciter);
                  _refresh();
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Juz’ ‘Amma'),
              ),
              FilledButton.tonalIcon(
                onPressed: dl.busy ? null : () async {
                  await dl.downloadSurahs([for (var i = 1; i <= 114; i++) i], reciter);
                  _refresh();
                },
                icon: const Icon(Icons.cloud_download_rounded),
                label: const Text('Whole Qur’an (large)'),
              ),
              if (dl.busy) OutlinedButton.icon(onPressed: dl.cancel, icon: const Icon(Icons.stop_rounded), label: const Text('Stop')),
              OutlinedButton.icon(
                onPressed: dl.busy ? null : () async {
                  await AudioCache.clear();
                  _refresh();
                  if (mounted) showToast(context, 'Downloaded recitations removed');
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove all'),
              ),
            ]),
            if (dl.error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(dl.error!, style: const TextStyle(color: Colors.redAccent))),
          ]),
        ),
        SliverToBoxAdapter(
          child: card([
            Text('Tafsir · ${tafsir.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text('Tafsir downloads one surah at a time as you read. Download the whole book to use it offline.', style: TextStyle(color: c.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            if (dl.tafsirProgress != null) ...[
              LinearProgressIndicator(value: dl.tafsirProgress, color: c.accent, backgroundColor: c.bg, minHeight: 6, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 6),
              Text('${(dl.tafsirProgress! * 100).round()}%', style: TextStyle(color: c.textSecondary)),
            ] else
              FilledButton.tonalIcon(
                onPressed: dl.busy ? null : () => dl.downloadTafsir(tafsir.id, tafsir.name),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download this tafsir'),
              ),
          ]),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Surahs')),
        SliverList.builder(
          itemCount: 114,
          itemBuilder: (context, i) {
            final s = Quran.I.surah(i + 1);
            final have = _cached[s.n] ?? 0;
            final full = have >= s.ayahs.length;
            final prog = dl.audioProgress[s.n];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Row(children: [
                SizedBox(width: 34, child: Text('${s.n}', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700))),
                Expanded(child: Text(s.en, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                if (prog != null)
                  SizedBox(width: 90, child: LinearProgressIndicator(value: prog, color: c.accent, backgroundColor: c.surface, minHeight: 5, borderRadius: BorderRadius.circular(3)))
                else if (full)
                  Icon(Icons.download_done_rounded, color: c.accent, size: 22)
                else ...[
                  if (have > 0) Text('$have/${s.ayahs.length}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  IconButton(
                    onPressed: dl.busy ? null : () async {
                      await dl.downloadSurahs([s.n], reciter);
                      _refresh();
                    },
                    icon: Icon(Icons.download_rounded, color: c.textSecondary, size: 22),
                  ),
                ],
              ]),
            );
          },
        ),
      ],
    );
  }
}
