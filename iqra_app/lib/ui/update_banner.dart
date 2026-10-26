import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/updates.dart';

/// The "new version" notice that sits above the content on every screen (not just Today), with the Update / Install button, the
/// download progress, and a close button that hides it until the next time the app is opened.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<UpdateChecker>();
    final c = context.c;
    final show = u.showBanner;
    final busy = u.downloading;
    final text = busy || u.ready || (u.installMessage?.isNotEmpty ?? false) ? (u.installMessage ?? '') : 'You have ${u.current}.';
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                decoration: BoxDecoration(color: c.dark ? Color.alphaBlend(c.accent.withValues(alpha: 0.22), c.surface) : Color.alphaBlend(c.accent.withValues(alpha: 0.14), c.bg), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.accent.withValues(alpha: 0.4))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Icon(Icons.system_update_alt_rounded, color: c.accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('IQRA ${u.latest} is available', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        if (text.isNotEmpty) Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.3)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: busy ? null : () => u.install(),
                      style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent, shape: const StadiumBorder(), visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: Text(busy ? '${(u.progress * 100).round()}%' : (u.ready ? 'Install' : (u.canInstallHere ? 'Update' : 'Download'))),
                    ),
                    if (!busy)
                      IconButton(visualDensity: VisualDensity.compact, tooltip: 'Not now', onPressed: u.dismiss, icon: Icon(Icons.close_rounded, size: 20, color: c.textSecondary))
                    else
                      const SizedBox(width: 8),
                  ]),
                  if (busy) Padding(padding: const EdgeInsets.only(top: 8, right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: u.progress == 0 ? null : u.progress, minHeight: 4, color: c.accent, backgroundColor: c.accent.withValues(alpha: 0.2)))),
                ]),
              ),
            ),
    );
  }
}
