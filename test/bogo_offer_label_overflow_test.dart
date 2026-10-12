import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The BOGO offer-label row used to be built as
///
///   Row(mainAxisAlignment: spaceBetween, children: [
///     Text(offerLabel),                  // no Flexible/Expanded, no maxLines
///     Text('$validUntilLabel : $date'),  // no Flexible/Expanded, no maxLines
///   ])
///
/// A Row hands its non-flex children unbounded width, so neither Text ever receives a
/// wrap constraint: long content runs past the row edge as a RenderFlex overflow
/// instead of truncating with an ellipsis. It shows up under localisation because a
/// translated "Valid until" is longer than the English one, so a row that fits in
/// English overflows in bn / ar / es.
///
/// Three surfaces shared the pattern — the offer details header, the offer package
/// sheet and the cart bundle sheet. These model both arrangements and measure them.

const double _rowWidth = 320;

const String _longLabel = 'BUY 2 DOUBLE LAYER SPECIAL BEEF BURGER GET 1 FREE';
const String _longValidUntil = 'মেয়াদ শেষ হওয়ার তারিখ : 01 Jul 2026';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: _rowWidth, child: child)),
    ),
  );
}

/// Header variant: two bare Texts, as the offer details screen had them.
Widget oldHeaderRow({required String label, required String validUntil}) {
  return _host(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, key: const Key('label')),
    Text(validUntil, key: const Key('valid')),
  ]));
}

Widget newHeaderRow({required String label, required String validUntil}) {
  return _host(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Expanded(
      child: Text(label, key: const Key('label'), maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    const SizedBox(width: 8),
    Flexible(
      child: Text(validUntil, key: const Key('valid'), maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  ]));
}

/// Sheet variant: a label/validity Column beside a price that must keep its full width.
Widget oldSheetRow({required String label, required String validUntil}) {
  return _host(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, key: const Key('label')),
      Text(validUntil, key: const Key('valid')),
    ]),
    const Text(r'$375.00', key: Key('price')),
  ]));
}

Widget newSheetRow({required String label, required String validUntil}) {
  return _host(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, key: const Key('label'), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(validUntil, key: const Key('valid'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
    const SizedBox(width: 8),
    const Text(r'$375.00', key: Key('price')),
  ]));
}

void main() {
  group('offer details header', () {
    testWidgets('a long label overflowed the old row', (tester) async {
      await tester.pumpWidget(oldHeaderRow(label: _longLabel, validUntil: _longValidUntil));
      expect(tester.takeException(), isA<FlutterError>(),
          reason: 'unbounded Row children cannot wrap, so they overflow');
    });

    testWidgets('the new row truncates instead, and stays inside its width', (tester) async {
      await tester.pumpWidget(newHeaderRow(label: _longLabel, validUntil: _longValidUntil));
      expect(tester.takeException(), isNull);

      final double used = tester.getSize(find.byKey(const Key('label'))).width +
          tester.getSize(find.byKey(const Key('valid'))).width;
      expect(used, lessThanOrEqualTo(_rowWidth),
          reason: 'both sides are bounded, so together they fit the row');
      expect(tester.widget<Text>(find.byKey(const Key('label'))).overflow, TextOverflow.ellipsis);
      expect(tester.widget<Text>(find.byKey(const Key('valid'))).overflow, TextOverflow.ellipsis);
    });

    testWidgets('short text is unaffected — the validity still sits at the right edge', (tester) async {
      await tester.pumpWidget(newHeaderRow(label: 'BUY 2 GET 1', validUntil: 'Valid until : 01 Jul 2026'));
      expect(tester.takeException(), isNull);

      final Rect valid = tester.getRect(find.byKey(const Key('valid')));
      final Rect row = tester.getRect(find.byType(Row));
      expect(valid.right, moreOrLessEquals(row.right, epsilon: 0.5));
    });
  });

  group('package and cart bundle sheets', () {
    testWidgets('a long label overflowed the old row', (tester) async {
      await tester.pumpWidget(oldSheetRow(label: _longLabel, validUntil: _longValidUntil));
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('the new row truncates the label and leaves the price at full width', (tester) async {
      await tester.pumpWidget(newSheetRow(label: _longLabel, validUntil: _longValidUntil));
      expect(tester.takeException(), isNull);

      // The price is the one thing that must never be cut — it is the payable amount.
      final Size price = tester.getSize(find.byKey(const Key('price')));
      await tester.pumpWidget(newSheetRow(label: 'BUY 2 GET 1', validUntil: 'Valid until : 01 Jul 2026'));
      expect(tester.getSize(find.byKey(const Key('price'))), price,
          reason: 'the price keeps its intrinsic width whatever the label does');
    });
  });
}
