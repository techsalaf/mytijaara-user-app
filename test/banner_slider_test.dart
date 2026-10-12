import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/dashboard/widgets/banner_slider.dart';

// The parcel path takes its banners as a parameter, so it exercises the slider
// without needing GetX controllers wired up.
List<ParcelBanner> banners(int n) => List<ParcelBanner>.generate(
  n, (int i) => ParcelBanner(id: i, imageFullUrl: ''),
);

Widget harness(int count) => MaterialApp(
  home: Scaffold(body: BannerSliderWidget(bannerList: banners(count))),
);

// Dots are AnimatedContainers; the active one is 8pt, the rest 5pt.
List<double> dotWidths(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .map((AnimatedContainer c) => (c.constraints?.maxWidth) ?? double.nan)
    .toList();

void main() {
  group('BannerSliderWidget', () {
    testWidgets('renders one dot per banner', (WidgetTester tester) async {
      await tester.pumpWidget(harness(4));
      await tester.pump();

      expect(find.byType(CarouselSlider), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('page change does NOT rebuild the CarouselSlider', (WidgetTester tester) async {
      await tester.pumpWidget(harness(3));
      await tester.pump();

      // Widget identity is the assertion: if _ParcelSlider.build re-ran, the
      // framework would hand us a new CarouselSlider instance, and carousel_slider
      // would re-invoke itemBuilder for every realized page — rebuilding each
      // slide's CustomImage. That is exactly the jank this widget used to have.
      final CarouselSlider before = tester.widget<CarouselSlider>(find.byType(CarouselSlider));

      // Drive a page change the way autoplay does.
      await tester.tap(find.byType(AnimatedContainer).last, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final CarouselSlider after = tester.widget<CarouselSlider>(find.byType(CarouselSlider));
      expect(identical(before, after), isTrue,
        reason: 'CarouselSlider was rebuilt on page change — the index leaked back into setState',
      );
    });

    testWidgets('dots still react to the page index', (WidgetTester tester) async {
      await tester.pumpWidget(harness(3));
      await tester.pump();

      // First dot active on load.
      expect(dotWidths(tester).first, 8);
      expect(dotWidths(tester)[1], 5);

      await tester.tap(find.byType(AnimatedContainer).at(2), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The notifier path has to actually move the highlight, or the optimisation
      // would have traded jank for a dead indicator.
      expect(dotWidths(tester).first, 5);
      expect(dotWidths(tester)[2], 8);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('disposes its index notifier without leaking the autoplay timer', (WidgetTester tester) async {
      await tester.pumpWidget(harness(3));
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('empty banner list renders nothing', (WidgetTester tester) async {
      await tester.pumpWidget(harness(0));
      await tester.pump();

      expect(find.byType(CarouselSlider), findsNothing);
      expect(find.byType(AnimatedContainer), findsNothing);
    });
  });
}
