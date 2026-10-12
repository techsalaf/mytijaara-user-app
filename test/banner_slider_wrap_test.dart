import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/dashboard/widgets/banner_slider.dart';

// Drives the real widget through autoplay to observe what the wrap from the last
// banner back to the first actually does, rather than reasoning about it.
List<ParcelBanner> banners(int n) => List<ParcelBanner>.generate(
  n, (int i) => ParcelBanner(id: i, imageFullUrl: ''),
);

Widget harness(int count) => MaterialApp(
  home: Scaffold(body: BannerSliderWidget(bannerList: banners(count))),
);

Finder dots() => find.byType(AnimatedContainer);

int? activeDot(WidgetTester tester) {
  final List<AnimatedContainer> all = tester.widgetList<AnimatedContainer>(dots()).toList();
  for (int i = 0; i < all.length; i++) {
    if (all[i].constraints?.maxWidth == 8) return i;
  }
  return null; // nothing highlighted
}

// One autoplay cycle: 5s interval + 800ms transition, per CarouselOptions here.
Future<void> advanceOnePage(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  group('BannerSliderWidget autoplay + wrap', () {
    testWidgets('advances 0 -> 1 -> 2 and wraps back to 0', (WidgetTester tester) async {
      await tester.pumpWidget(harness(3));
      await tester.pump();

      final List<int?> seen = <int?>[activeDot(tester)];
      for (int i = 0; i < 3; i++) {
        await advanceOnePage(tester);
        seen.add(activeDot(tester));
      }

      expect(seen, <int?>[0, 1, 2, 0], reason: 'autoplay should cycle and wrap cleanly');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('keeps wrapping past the first full cycle', (WidgetTester tester) async {
      await tester.pumpWidget(harness(2));
      await tester.pump();

      final List<int?> seen = <int?>[activeDot(tester)];
      for (int i = 0; i < 5; i++) {
        await advanceOnePage(tester);
        seen.add(activeDot(tester));
      }

      expect(seen, <int?>[0, 1, 0, 1, 0, 1]);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a SINGLE banner does not autoplay or infinite-scroll', (WidgetTester tester) async {
      await tester.pumpWidget(harness(1));
      await tester.pump();

      expect(dots(), findsOneWidget);

      // With one banner there is nothing to advance to. Leaving these on gave
      // PageView a null itemCount and let the timer slide endlessly between
      // identical copies of the same image.
      final CarouselSlider slider = tester.widget<CarouselSlider>(find.byType(CarouselSlider));
      expect(slider.options.enableInfiniteScroll, isFalse);
      expect(slider.options.autoPlay, isFalse);

      await advanceOnePage(tester);
      expect(activeDot(tester), 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('two or more banners keep autoplay and infinite scroll on', (WidgetTester tester) async {
      await tester.pumpWidget(harness(2));
      await tester.pump();

      final CarouselSlider slider = tester.widget<CarouselSlider>(find.byType(CarouselSlider));
      expect(slider.options.enableInfiniteScroll, isTrue);
      expect(slider.options.autoPlay, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shrinking the banner list still highlights a dot', (WidgetTester tester) async {
      await tester.pumpWidget(harness(5));
      await tester.pump();

      // Advance to index 3, then shrink the list to 3 entries as a refresh would.
      await advanceOnePage(tester);
      await advanceOnePage(tester);
      await advanceOnePage(tester);
      expect(activeDot(tester), 3);

      await tester.pumpWidget(harness(3));
      await tester.pump();

      expect(dots(), findsNWidgets(3));
      // _currentIndex still holds 3, which maps to no dot in the shorter list —
      // the indicator falls back to the first dot instead of going blank.
      expect(activeDot(tester), 0,
        reason: 'a stale index must not leave the indicator with nothing highlighted',
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
