import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';

// The avatar lives in list cards, so a leaked Timer or AnimationController is
// multiplied by every card the user scrolls past. testWidgets fails the test if
// either outlives the element, which is what most of this file is guarding.
// MaterialApp has AnimatedBuilders of its own, so every finder here is scoped to
// the widget under test rather than the whole tree.
Finder flipBuilder() => find.descendant(
  of: find.byType(StoreVerifiedAvatar), matching: find.byType(AnimatedBuilder),
);

Widget harness({required bool isVerified, String? imageUrl, Duration interval = const Duration(seconds: 2)}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: StoreVerifiedAvatar(imageUrl: imageUrl, isVerified: isVerified, size: 18, interval: interval),
      ),
    ),
  );
}

void main() {
  group('StoreVerifiedAvatar', () {
    testWidgets('unverified renders a plain avatar with no animation layer', (WidgetTester tester) async {
      await tester.pumpWidget(harness(isVerified: false));

      expect(find.byType(StoreVerifiedAvatar), findsOneWidget);
      // No flip means no per-frame builder inside this widget.
      expect(flipBuilder(), findsNothing);
      // Nothing scheduled: pumping well past the interval must settle.
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('verified wraps the flip in a RepaintBoundary', (WidgetTester tester) async {
      await tester.pumpWidget(harness(isVerified: true));

      // The boundary is what stops the flip dirtying the enclosing card's layer.
      final Finder boundary = find.descendant(
        of: find.byType(StoreVerifiedAvatar), matching: find.byType(RepaintBoundary),
      );
      expect(boundary, findsWidgets);
      expect(flipBuilder(), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('disposes its timer and controller when removed mid-cycle', (WidgetTester tester) async {
      await tester.pumpWidget(harness(isVerified: true, interval: const Duration(milliseconds: 200)));

      // Land inside the scheduled delay, then tear down. A leaked Timer fails here.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('disposes cleanly while a flip is actually running', (WidgetTester tester) async {
      await tester.pumpWidget(harness(isVerified: true, interval: const Duration(milliseconds: 100)));

      // Past the delay and into the 500ms rotation, so the controller is active.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('toggling isVerified off stops the animation and cleans up', (WidgetTester tester) async {
      await tester.pumpWidget(harness(isVerified: true, interval: const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 150));

      await tester.pumpWidget(harness(isVerified: false));
      expect(flipBuilder(), findsNothing);

      // Any timer left over from the verified phase would fire in here.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('flip settles back to a resting rotation between cycles', (WidgetTester tester) async {
      await tester.pumpWidget(harness(isVerified: true, interval: const Duration(milliseconds: 100)));

      Matrix4 transformOf(WidgetTester t) => t.widget<Transform>(
        find.descendant(of: flipBuilder(), matching: find.byType(Transform)).first,
      ).transform;

      // At rest the outer rotation is identity-ish (angle 0).
      await tester.pump();
      expect(transformOf(tester).entry(0, 0), closeTo(1.0, 0.001));

      // Mid-rotation it is not.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 250));
      expect(transformOf(tester).entry(0, 0), lessThan(0.99));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
