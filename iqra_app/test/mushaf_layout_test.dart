import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iqra/core/quran.dart';
import 'package:iqra/core/theme.dart';
import 'package:iqra/ui/mushaf.dart';

/// Pages must lay out inside their own box, including a page that starts a surah (banner and bismillah rows).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var loaded = false;
  Future<void> check(WidgetTester tester, int page) async {
    if (!loaded) {
      loaded = true;
      await tester.runAsync(() => Quran.I.load());
    }
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(kThemes.first.colors),
      home: Scaffold(
        body: Center(child: SizedBox(width: 700, height: 900, child: MushafPage(page: page))),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    final pageBox = tester.getRect(find.byType(MushafPage));
    // every printed line stays within the page
    final lines = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_MushafLine');
    expect(lines, findsWidgets);
    for (final e in lines.evaluate()) {
      final r = e.renderObject as RenderBox;
      final rect = r.localToGlobal(Offset.zero) & r.size;
      expect(rect.left >= pageBox.left - 0.5 && rect.right <= pageBox.right + 0.5, isTrue, reason: 'page $page: a line is $rect but the page is $pageBox');
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('a plain page lays out inside its box', (tester) => check(tester, 42));
  testWidgets('a page that starts a surah lays out inside its box', (tester) => check(tester, 50));
  testWidgets('the first pages lay out inside their box', (tester) => check(tester, 1));
}
