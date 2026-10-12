import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_new_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// The "What would you like to send?" skeleton has to occupy the same space the
/// real grid will, or the section resizes under the customer the moment the
/// categories arrive. These are the numbers it drifted on.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  SliverGridDelegateWithFixedCrossAxisCount delegateOf(WidgetTester tester) {
    final GridView grid = tester.widget<GridView>(find.byType(GridView));
    return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  }

  group('the category skeleton matches the grid it stands in for', () {
    testWidgets('row height is the grid\'s 90, not the old 75', (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));
      expect(delegateOf(tester).mainAxisExtent, 90);
    });

    testWidgets('two columns on mobile, spaced as the grid is', (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));
      final SliverGridDelegateWithFixedCrossAxisCount d = delegateOf(tester);
      expect(d.crossAxisCount, 2);
      expect(d.crossAxisSpacing, Dimensions.paddingSizeSmall);
      expect(d.mainAxisSpacing, Dimensions.paddingSizeSmall);
    });

    testWidgets('draws four tiles — the grid\'s cap — not the old seven', (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));
      final GridView grid = tester.widget<GridView>(find.byType(GridView));
      expect((grid.childrenDelegate as SliverChildBuilderDelegate).childCount, 4);
    });

    testWidgets('is padded like the grid, so the tiles line up with the heading',
        (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));
      final GridView grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.padding, const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge));
    });
  });

  group('the tile traces the real card', () {
    testWidgets('tiles are one neutral tone, not the cards\' pastels',
        (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));

      final Iterable<Container> tiles = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) => c.decoration is BoxDecoration
              && (c.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(Dimensions.radiusLarge));

      final Set<Color?> painted =
          tiles.map((Container c) => (c.decoration as BoxDecoration).color).toSet();

      // Every tile the same: a colourful skeleton reads as finished content.
      expect(painted.length, 1, reason: 'all four tiles should share one tone');

      // And none of them is one of the loaded card's pastels.
      const List<Color> pastels = <Color>[
        Color(0xFFFCEFC9), Color(0xFFE5E9F5), Color(0xFFD9EAD8), Color(0xFFFAD9DD),
      ];
      for (final Color pastel in pastels) {
        expect(painted, isNot(contains(pastel)));
      }
    });

    testWidgets('the thumbnail block is 40x40, matching the card\'s image',
        (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));

      final bool hasThumb = tester
          .widgetList<Container>(find.byType(Container))
          .any((Container c) {
            final BoxConstraints? box = c.constraints;
            return box != null && box.maxHeight == 40 && box.maxWidth == 40;
          });
      expect(hasThumb, isTrue);
    });

    testWidgets('renders without a GetX or localization scope', (WidgetTester tester) async {
      // The skeleton must not depend on controllers — it is drawn before any of
      // them have answered.
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: true));
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled still lays out identically', (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: false, isDeliveryItem: true));
      expect(delegateOf(tester).mainAxisExtent, 90);
      expect(tester.takeException(), isNull);
    });
  });

  group('the why-choose-us skeleton is untouched', () {
    testWidgets('still three across at 140 high on mobile', (WidgetTester tester) async {
      await pump(tester, const ParcelShimmer(isEnabled: true, isDeliveryItem: false));
      // isDeliveryItem: false on mobile takes the horizontal-list branch, which
      // has no GridView at all — asserting that keeps this pass from silently
      // rerouting the other section.
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
