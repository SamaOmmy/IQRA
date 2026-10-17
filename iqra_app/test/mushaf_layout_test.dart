import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iqra/core/quran.dart';
import 'package:iqra/core/theme.dart';
import 'package:iqra/ui/mushaf.dart';

var _loaded = false;
Future<void> _load(WidgetTester tester) async {
  if (_loaded) return;
  _loaded = true;
  await tester.runAsync(() => Quran.I.load());
}

/// Pages must lay out inside their own box, including a page that starts a surah (banner and bismillah rows).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> check(WidgetTester tester, int page) async {
    await _load(tester);
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
  dataOrderTests();
}

/// The page data must read in order: lines never run backwards inside a page, and each page continues where the last one ended.
void dataOrderTests() {
  testWidgets('page data is in reading order', (tester) async {
    await _load(tester);
    for (var p = 1; p <= 604; p++) {
      final ws = Quran.I.pageWords(p);
      for (var k = 1; k < ws.length; k++) {
        expect(ws[k].line >= ws[k - 1].line, isTrue, reason: 'page $p: line ${ws[k].line} after ${ws[k - 1].line} at word $k');
      }
      if (p > 1) {
        final prev = Quran.I.pageWords(p - 1).last, first = ws.first;
        expect(first.surah * 1000 + first.ayah >= prev.surah * 1000 + prev.ayah, isTrue, reason: 'page $p starts before page ${p - 1} ends');
      }
    }
    final g = Quran.I.pageGlyphs(583);
    if (g != null) expect(g.length, Quran.I.pageWords(583).length);
  });
}
