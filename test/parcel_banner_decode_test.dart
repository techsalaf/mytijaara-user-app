import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';

/// The parcel "easiest way to get services" banner sizes itself from the sheet, which
/// caps at 550 but is narrower on a phone. These check that the decode hint follows the
/// measured slot instead of a constant, and that only one axis is hinted.
void main() {
  Future<({double slot, int? hint})> measure(WidgetTester tester, double screenWidth) async {
    double slot = -1;
    int? hint;
    tester.view.physicalSize = Size(screenWidth * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 550, // the sheet's cap
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20), // paddingSizeLarge
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                    slot = constraints.maxWidth;
                    hint = ImageCacheHelper.pixels(context, constraints.maxWidth);
                    return SizedBox(width: constraints.maxWidth, height: 100);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    return (slot: slot, hint: hint);
  }

  testWidgets('the decode hint tracks the measured slot on a narrow phone', (tester) async {
    final r = await measure(tester, 360);
    expect(r.slot, 360 - 40, reason: 'sheet is screen-wide, minus the 20pt padding each side');
    expect(r.hint, (r.slot * 3).round(), reason: 'logical -> physical at dpr 3');
    expect(r.hint, greaterThan(ImageCacheHelper.pixels(tester.element(find.byType(Scaffold)), 100)!),
        reason: 'the old fallback decoded at the 100 logical default');
  });

  testWidgets('the hint is capped by the sheet width on a wide screen', (tester) async {
    final r = await measure(tester, 1200);
    expect(r.slot, 550 - 40, reason: 'the 550 cap wins over the screen width');
    expect(r.hint, (r.slot * 3).round());
  });

  test('the old both-axes default is what squashed it', () {
    // CustomImage with no size and no hint resolves BOTH axes from the 100 default,
    // and two axes make ResizeImage decode to exactly those numbers, dropping the
    // source aspect ratio. One axis lets the decoder derive the other.
    const int fallbackBoth = 300; // 100 logical * dpr 3, on both width and height
    const int hintedWidth = 990;  // (550-40) * 3
    expect(fallbackBoth, lessThan(hintedWidth));
    // a 16:9 banner decoded with only the width hinted keeps its ratio
    expect((hintedWidth * 9 / 16).round(), 557);
    // with both axes it becomes a square, whatever the source was
    expect(fallbackBoth, fallbackBoth);
  });
}
