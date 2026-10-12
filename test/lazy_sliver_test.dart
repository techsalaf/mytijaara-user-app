import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/common/widgets/lazy_sliver.dart';

// Section heights are chosen so that only the first few fit in the 600px test
// viewport plus its 250px cache extent.
const double _sectionHeight = 400;
const int _sectionCount = 10;

void main() {
  setUp(() {
    // The epoch is a static shared across tests; reset it so counts start clean.
    LazyRefreshNotifier.epoch.value = 0;
  });

  Widget buildHarness({
    required List<int> revealed,
    ScrollController? controller,
    double sectionHeight = _sectionHeight,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          slivers: List<Widget>.generate(_sectionCount, (int index) {
            return LazySliver(
              onReveal: () => revealed.add(index),
              sliver: SliverToBoxAdapter(child: SizedBox(height: sectionHeight)),
            );
          }),
        ),
      ),
    );
  }

  testWidgets('only sections within the viewport and cache extent fetch on first frame', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final List<int> revealed = <int>[];
    await tester.pumpWidget(buildHarness(revealed: revealed));
    await tester.pump();

    // 600px viewport + 250px trailing cache extent over 400px sections: sections 0
    // and 1 are on screen, section 2 falls inside the cache extent.
    expect(revealed, <int>[0, 1, 2]);
  });

  testWidgets('scrolling reveals further sections one at a time', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final List<int> revealed = <int>[];
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildHarness(revealed: revealed, controller: controller));
    await tester.pump();
    expect(revealed, <int>[0, 1, 2]);

    controller.jumpTo(400);
    await tester.pump();
    await tester.pump();
    expect(revealed, <int>[0, 1, 2, 3]);

    controller.jumpTo(1200);
    await tester.pump();
    await tester.pump();
    expect(revealed, <int>[0, 1, 2, 3, 4, 5]);
  });

  testWidgets('a revealed section does not refetch on an unrelated relayout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final List<int> revealed = <int>[];
    await tester.pumpWidget(buildHarness(revealed: revealed));
    await tester.pump();
    expect(revealed, <int>[0, 1, 2]);

    await tester.pumpWidget(buildHarness(revealed: revealed));
    await tester.pump();
    expect(revealed, <int>[0, 1, 2], reason: 'rebuilding must not re-trigger a fetch');
  });

  testWidgets('bump refetches on-screen sections only', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final List<int> revealed = <int>[];
    await tester.pumpWidget(buildHarness(revealed: revealed));
    await tester.pump();
    expect(revealed, <int>[0, 1, 2]);

    revealed.clear();
    LazyRefreshNotifier.bump();
    await tester.pump();
    await tester.pump();

    expect(revealed, <int>[0, 1, 2], reason: 'off-screen sections must stay lazy across a refresh');
  });

  testWidgets('zero-height unloaded sections defeat the deferral', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final List<int> revealed = <int>[];
    await tester.pumpWidget(buildHarness(revealed: revealed, sectionHeight: 0));
    await tester.pump();

    // Documents why section placeholders must keep their height: with no height,
    // nothing consumes the cache extent and every section fetches at once.
    expect(revealed.length, _sectionCount);
  });
}
