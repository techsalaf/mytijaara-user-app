import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/dashboard/widgets/banner_slider.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// The banner skeleton stands in for the whole slider section — slide, gap and
/// dot strip. The parcel home used to hand-roll a full-bleed `radiusDefault`
/// rectangle at a hardcoded 150 with no dots.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: BannerSliderShimmer())),
    ));
    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: BannerSliderShimmer())),
    ));
  }

  double screenWidth(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  testWidgets('the slide is the carousel\'s own height (width * 0.8 * 0.5)',
      (WidgetTester tester) async {
    await pump(tester);
    final double expected = screenWidth(tester) * 0.8 * 0.5;

    final bool hasSlide = tester
        .widgetList<Container>(find.byType(Container))
        .any((Container c) => ((c.constraints?.maxHeight ?? -1) - expected).abs() < 0.5);
    expect(hasSlide, isTrue, reason: 'slide should match _sliderHeight, not a hardcoded 150');
  });

  testWidgets('the slide uses radiusLarge, as the real slides do', (WidgetTester tester) async {
    await pump(tester);
    final bool rounded = tester
        .widgetList<Container>(find.byType(Container))
        .any((Container c) {
          final Object? d = c.decoration;
          return d is BoxDecoration
              && d.borderRadius == BorderRadius.circular(Dimensions.radiusLarge);
        });
    expect(rounded, isTrue);
  });

  testWidgets('the slide is inset from the left like the carousel items',
      (WidgetTester tester) async {
    await pump(tester);
    final bool inset = tester
        .widgetList<Container>(find.byType(Container))
        .any((Container c) =>
            c.margin is EdgeInsets
            && (c.margin as EdgeInsets).left == Dimensions.paddingSizeDefault);
    expect(inset, isTrue);
  });

  testWidgets('draws the dot strip both sliders close with', (WidgetTester tester) async {
    await pump(tester);
    // The real _DotIndicator is a 10px-high box; dots are 8 active / 5 inactive.
    final Iterable<SizedBox> boxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(boxes.any((SizedBox s) => s.height == 10), isTrue, reason: 'dot strip box');

    final Iterable<Container> containers = tester.widgetList<Container>(find.byType(Container));
    expect(containers.where((Container c) => c.constraints?.maxHeight == 5).length, 2);
    expect(containers.where((Container c) => c.constraints?.maxHeight == 8).length, 1);
  });

  testWidgets('occupies real space rather than collapsing', (WidgetTester tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(BannerSliderShimmer)).height, greaterThan(50));
  });

  testWidgets('draws before any controller exists', (WidgetTester tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
  });
}
