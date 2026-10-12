import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The conversation list's scroll structure, before and after.
///
/// Before: `SingleChildScrollView` wrapping a `shrinkWrap: true` +
/// `NeverScrollableScrollPhysics` ListView. shrinkWrap makes the ListView measure its
/// whole extent, so every row is built on the first frame and nothing is ever culled.
///
/// After: a `CustomScrollView` + `SliverList`, which builds only the rows near the
/// viewport.
Widget _row(int i, Set<int> built) {
  built.add(i);
  return SizedBox(height: 88, child: Text('conversation $i'));
}

Widget _before(ScrollController c, int count, Set<int> built) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      controller: c,
      child: Column(children: [
        ListView.builder(
          itemCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, i) => _row(i, built),
        ),
      ]),
    ),
  ),
);

Widget _after(ScrollController c, int count, Set<int> built) => MaterialApp(
  home: Scaffold(
    body: CustomScrollView(
      controller: c,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverList.separated(
          itemCount: count,
          itemBuilder: (context, i) => _row(i, built),
          separatorBuilder: (context, i) => const SizedBox(height: 8),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    ),
  ),
);

void main() {
  const int count = 200;

  testWidgets('old structure builds every conversation on the first frame', (tester) async {
    final Set<int> built = <int>{};
    final ScrollController c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_before(c, count, built));
    expect(built.length, count,
        reason: 'shrinkWrap forces a full-extent measure, so all $count rows are built');
  });

  testWidgets('new structure builds only what the viewport needs', (tester) async {
    final Set<int> built = <int>{};
    final ScrollController c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_after(c, count, built));
    expect(built.length, lessThan(count),
        reason: 'a SliverList builds lazily');
    // 600px tall test viewport / 96px per row ≈ 7 visible, plus the cache extent.
    expect(built.length, lessThan(30));
  });

  testWidgets('new structure keeps scrolling to the end and paginating reachable', (tester) async {
    final Set<int> built = <int>{};
    final ScrollController c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_after(c, count, built));

    // `maxScrollExtent` is an estimate that gets refined as the sliver lays out more
    // children, so jump repeatedly until it stops moving.
    double previous = -1;
    for (int i = 0; i < 60 && previous != c.position.maxScrollExtent; i++) {
      previous = c.position.maxScrollExtent;
      c.jumpTo(previous);
      await tester.pump();
    }
    // Reaching the bottom is what PaginatedListView's scroll listener watches for.
    expect(c.position.pixels, closeTo(c.position.maxScrollExtent, 0.5));
    expect(built, contains(count - 1), reason: 'the last row builds when scrolled to');
  });

  testWidgets('pull-to-refresh works even when the list is shorter than the viewport', (tester) async {
    // AlwaysScrollableScrollPhysics is what makes this possible; without it a short
    // list is unscrollable and RefreshIndicator never fires.
    bool refreshed = false;
    final ScrollController c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async => refreshed = true,
          child: CustomScrollView(
            controller: c,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverList.separated(
                itemCount: 1,
                itemBuilder: (context, i) => const SizedBox(height: 88, child: Text('only one')),
                separatorBuilder: (context, i) => const SizedBox(height: 8),
              ),
            ],
          ),
        ),
      ),
    ));

    await tester.fling(find.text('only one'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(refreshed, isTrue);
  });
}
