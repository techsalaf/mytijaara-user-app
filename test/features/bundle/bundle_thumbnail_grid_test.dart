import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_thumbnail_grid_widget.dart';

/// The member-picture tile, at every count a bundle can have.
///
/// A wrong count used to mean a half-empty square or an overflowing card, so
/// each case is pinned: how many tiles are drawn, how they are shaped, and
/// whether the `+n` chip appears.
void main() {
  const double size = 200;

  // Mirrors the widget's own spacing: Dimensions.paddingSizeSmall around the
  // panel, paddingSizeExtraSmall between tiles.
  const double panelPadding = 10;
  const double gap = 5;
  const double inner = size - (panelPadding * 2);
  const double half = (inner - gap) / 2;

  /// The image fills its tile, inside the tile's 1px border.
  const double tileBorder = 1;
  Size imageOf(double tileWidth, double tileHeight) =>
      Size(tileWidth - (tileBorder * 2), tileHeight - (tileBorder * 2));

  Future<void> pumpGrid(WidgetTester tester, {required int total, int pictures = 0, Widget? action}) {
    return tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Center(child: BundleThumbnailGridWidget(
          thumbnails: List<String>.generate(pictures, (i) => ''),
          totalCount: total,
          size: size,
          action: action,
        )),
      ),
    ));
  }

  /// Measured from the render tree rather than read off the widget, so the test
  /// still holds however the tile chooses to size its image.
  List<Size> tileSizes(WidgetTester tester) {
    final int count = tester.widgetList<CustomImage>(find.byType(CustomImage)).length;
    return List<Size>.generate(count, (index) => tester.getSize(find.byType(CustomImage).at(index)));
  }

  group('tile layout by member count', () {
    testWidgets('1 member fills the square', (tester) async {
      await pumpGrid(tester, total: 1, pictures: 1);
      expect(tileSizes(tester), [imageOf(inner, inner)]);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('2 members are two full-height columns', (tester) async {
      await pumpGrid(tester, total: 2, pictures: 2);
      expect(tileSizes(tester), [imageOf(half, inner), imageOf(half, inner)]);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('3 members are two stacked and one full-height', (tester) async {
      await pumpGrid(tester, total: 3, pictures: 3);
      expect(tileSizes(tester), [
        imageOf(half, half), imageOf(half, half), imageOf(half, inner),
      ]);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('4 members are a 2x2 with no chip', (tester) async {
      await pumpGrid(tester, total: 4, pictures: 4);
      expect(tileSizes(tester), List<Size>.filled(4, imageOf(half, half)));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('7 members are a 2x2 plus a +3 chip', (tester) async {
      await pumpGrid(tester, total: 7, pictures: 7);
      expect(tileSizes(tester), List<Size>.filled(4, imageOf(half, half)));
      expect(find.text('+3'), findsOneWidget);
    });
  });

  group('the endpoints that send no pictures', () {
    testWidgets('lays out by item_count even with no thumbnails at all', (tester) async {
      /// The list endpoints send `items: null`, so a card knows the count long
      /// before it has any picture. The square must still be filled.
      await pumpGrid(tester, total: 3, pictures: 0);
      expect(tileSizes(tester), [
        imageOf(half, half), imageOf(half, half), imageOf(half, inner),
      ]);
    });

    testWidgets('a count of zero still draws one placeholder rather than nothing', (tester) async {
      await pumpGrid(tester, total: 0, pictures: 0);
      expect(tileSizes(tester), [imageOf(inner, inner)]);
    });

    testWidgets('more pictures than the count does not over-draw', (tester) async {
      await pumpGrid(tester, total: 2, pictures: 5);
      expect(tileSizes(tester), [imageOf(half, inner), imageOf(half, inner)]);
    });
  });

  testWidgets('the action floats over the bottom-right corner', (tester) async {
    await pumpGrid(tester, total: 4, pictures: 4, action: const SizedBox(key: Key('add'), height: 40, width: 40));

    final Offset gridCorner = tester.getBottomRight(find.byType(BundleThumbnailGridWidget));
    final Offset actionCorner = tester.getBottomRight(find.byKey(const Key('add')));

    /// Inset by the panel's own padding, so it lands on the bottom-right tile
    /// rather than hanging off the panel.
    expect(actionCorner.dx, moreOrLessEquals(gridCorner.dx - panelPadding, epsilon: 0.5));
    expect(actionCorner.dy, moreOrLessEquals(gridCorner.dy - panelPadding, epsilon: 0.5));

    /// It sits on top of the pictures rather than taking a cell, so all four are
    /// still drawn.
    expect(tileSizes(tester), List<Size>.filled(4, imageOf(half, half)));
  });

  testWidgets('no count overflows its square', (tester) async {
    for(final int count in <int>[0, 1, 2, 3, 4, 5, 7, 20]) {
      await pumpGrid(tester, total: count, pictures: count);
      expect(tester.takeException(), isNull, reason: 'count $count');
      expect(tester.getSize(find.byType(BundleThumbnailGridWidget)), const Size(size, size));
    }
  });
}
