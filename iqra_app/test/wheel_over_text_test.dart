import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iqra/ui/smooth_scroll.dart';
import 'package:iqra/ui/widgets.dart';

class _Behavior extends MaterialScrollBehavior {
  const _Behavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}

void main() {
  // SelectableText has a scroller of its own that swallowed touch drags under the app's always-scrollable physics; selectableText() must not.
  for (final selectable in [false]) {
    for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
      testWidgets('${kind.name} over ${selectable ? 'SelectableText' : 'selectable()'} scrolls the page', (t) async {
        final ctl = SmoothScrollController();
        final text = List.filled(300, 'word').join(' ');
        await t.pumpWidget(MaterialApp(
          scrollBehavior: const _Behavior(),
          home: Scaffold(
            body: CustomScrollView(controller: ctl, slivers: [
              SliverToBoxAdapter(child: selectable ? SelectableText(text) : selectableText(text)),
              const SliverToBoxAdapter(child: SizedBox(height: 3000)),
            ]),
          ),
        ));
        if (kind == PointerDeviceKind.mouse) {
          final mouse = TestPointer(1, PointerDeviceKind.mouse);
          mouse.hover(const Offset(300, 200));
          await t.sendEventToBinding(mouse.scroll(const Offset(0, 300)));
          await t.pumpAndSettle();
        } else {
          await t.dragFrom(const Offset(300, 300), const Offset(0, -250));
          await t.pumpAndSettle();
        }
        expect(ctl.offset, greaterThan(0), reason: 'the page did not move');
      });
    }
  }
}
