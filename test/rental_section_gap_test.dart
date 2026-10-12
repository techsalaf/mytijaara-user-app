import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rental home screen used to emit each section's gap unconditionally:
///
///   sliverGepY(value: gap),                     // always took its height
///   SliverToBoxAdapter(child: Section()),       // collapsed to SizedBox() when empty
///
/// so a hidden section still left a band of empty space. `_SectionSliver` now pairs the
/// gap with the section, and emits neither when the section will not draw. These model
/// both arrangements and measure the result.
Widget oldArrangement({required bool sectionHasContent, required double gap}) {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: SizedBox(height: gap)), // the unconditional gap
        SliverToBoxAdapter(
          child: sectionHasContent ? const SizedBox(height: 100, key: Key('section')) : const SizedBox(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 1, key: Key('after'))),
      ]),
    ),
  );
}

Widget newArrangement({required bool sectionHasContent, required double gap}) {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: sectionHasContent
              ? Column(children: [
                  SizedBox(height: gap),
                  const SizedBox(height: 100, key: Key('section')),
                ])
              : const SizedBox.shrink(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 1, key: Key('after'))),
      ]),
    ),
  );
}

void main() {
  const double gap = 24;

  testWidgets('empty section: the old arrangement still occupied the gap', (tester) async {
    await tester.pumpWidget(oldArrangement(sectionHasContent: false, gap: gap));
    expect(find.byKey(const Key('section')), findsNothing);
    // The marker after the section is pushed down by the orphaned gap.
    expect(tester.getTopLeft(find.byKey(const Key('after'))).dy, gap);
  });

  testWidgets('empty section: the new arrangement occupies nothing', (tester) async {
    await tester.pumpWidget(newArrangement(sectionHasContent: false, gap: gap));
    expect(find.byKey(const Key('section')), findsNothing);
    expect(tester.getTopLeft(find.byKey(const Key('after'))).dy, 0,
        reason: 'no leftover band where the hidden section was');
  });

  testWidgets('populated section: spacing is unchanged', (tester) async {
    await tester.pumpWidget(oldArrangement(sectionHasContent: true, gap: gap));
    final double oldSectionTop = tester.getTopLeft(find.byKey(const Key('section'))).dy;
    final double oldAfterTop = tester.getTopLeft(find.byKey(const Key('after'))).dy;

    await tester.pumpWidget(newArrangement(sectionHasContent: true, gap: gap));
    expect(tester.getTopLeft(find.byKey(const Key('section'))).dy, oldSectionTop,
        reason: 'the gap still precedes a visible section');
    expect(tester.getTopLeft(find.byKey(const Key('after'))).dy, oldAfterTop);
  });

  testWidgets('several empty sections in a row collapse completely', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(slivers: [
          for (int i = 0; i < 5; i++) const SliverToBoxAdapter(child: SizedBox.shrink()),
          const SliverToBoxAdapter(child: SizedBox(height: 1, key: Key('after'))),
        ]),
      ),
    ));
    expect(tester.getTopLeft(find.byKey(const Key('after'))).dy, 0,
        reason: '5 hidden sections used to stack 5 gaps of dead space');
  });
}
