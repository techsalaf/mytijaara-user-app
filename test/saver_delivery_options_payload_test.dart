import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_model.dart';

/// `checkout-summary.delivery_options` — the saver tiers priced for this order.
///
/// These used to be assembled client-side: the range was reconstructed from the
/// store's free-text `delivery_time`, the zone pivot's minimum and each tier's
/// own delta, and the charge was read off whichever of `extra_charge` /
/// `reduce_charge` happened to be non-null. The server now answers both, so the
/// contract these guard is that the app renders what it is given.
void main() {
  /// Verbatim from the dev backend, trimmed to the blocks under test.
  const String liveBody = '''
  {"delivery":{"delivery_charge":1984.89,"base_delivery_charge":1764.35,"surge_amount":882.18},
   "delivery_options":[
     {"id":50,"delivery_type":"standard","delivery_type_text":"Standard",
      "extra_charge":0.0,"reduce_charge":0.0,"add_delivery_time":0,"reduce_delivery_time":0,
      "time_range":"20 min - 1 hour"},
     {"id":51,"delivery_type":"express","delivery_type_text":"Express",
      "extra_charge":10.0,"reduce_charge":0.0,"add_delivery_time":0,"reduce_delivery_time":10,
      "time_range":"20 min - 50 min"},
     {"id":52,"delivery_type":"slightly_delay","delivery_type_text":"Slightly delay",
      "extra_charge":0.0,"reduce_charge":50.0,"add_delivery_time":10,"reduce_delivery_time":0,
      "time_range":"20 min - 1 hour 10 min"}
   ]}''';

  CheckoutSummaryModel summaryOf(String rawBody) =>
      CheckoutSummaryModel.fromJson(jsonDecode(rawBody) as Map<String, dynamic>);

  group('the live quote', () {
    late CheckoutSummaryModel summary;
    setUp(() => summary = summaryOf(liveBody));

    test('parses every tier in order', () {
      expect(summary.deliveryOptions, hasLength(3));
      expect(
        summary.deliveryOptions.map((CheckoutSummaryDeliveryOption o) => o.deliveryType),
        <String>['standard', 'express', 'slightly_delay'],
      );
    });

    test('carries the time range written out, so nothing is reconstructed', () {
      expect(summary.deliveryOptions[0].timeRange, '20 min - 1 hour');
      expect(summary.deliveryOptions[1].timeRange, '20 min - 50 min');
      expect(summary.deliveryOptions[2].timeRange, '20 min - 1 hour 10 min');
    });

    test('carries the platform-localised label', () {
      expect(summary.deliveryOptions[2].deliveryTypeText, 'Slightly delay');
    });
  });

  group('chargeAdjustment', () {
    late CheckoutSummaryModel summary;
    setUp(() => summary = summaryOf(liveBody));

    test('standard neither adds nor reduces', () {
      expect(summary.deliveryOptions[0].chargeAdjustment, 0);
    });

    test('express adds its extra charge', () {
      expect(summary.deliveryOptions[1].chargeAdjustment, 10);
    });

    test('slightly_delay reduces, despite extra_charge being present as 0.0', () {
      // The regression this guards: branching on `extraCharge != null` first —
      // as the zone-config path does — reads this row's `extra_charge: 0.0` as
      // "no change" and silently drops the 50.0 reduction.
      expect(summary.deliveryOptions[2].chargeAdjustment, -50);
    });

    test('the zone-config shape, with the unused key absent, reads the same way', () {
      final CheckoutSummaryModel configShape = summaryOf(
        '{"delivery_options":[{"delivery_type":"express","extra_charge":10.0},'
        '{"delivery_type":"slightly_delay","reduce_charge":50.0}]}',
      );
      expect(configShape.deliveryOptions[0].chargeAdjustment, 10);
      expect(configShape.deliveryOptions[1].chargeAdjustment, -50);
    });
  });

  group('when the platform sends nothing', () {
    test('an explicit null leaves the list empty, not null', () {
      // A parcel quote always sends `delivery_options: null`.
      expect(summaryOf('{"delivery_options":null}').deliveryOptions, isEmpty);
    });

    test('an absent key leaves the list empty', () {
      expect(summaryOf('{"tax":{"tax_amount":0}}').deliveryOptions, isEmpty);
    });

    test('a non-list value is ignored rather than throwing', () {
      expect(summaryOf('{"delivery_options":"none"}').deliveryOptions, isEmpty);
    });

    test('the rest of the quote still parses alongside the options', () {
      final CheckoutSummaryModel summary = summaryOf(liveBody);
      expect(summary.delivery!.deliveryCharge, 1984.89);
      expect(summary.delivery!.surgeAmount, 882.18);
    });
  });

  group('isUsable', () {
    test('a row with no delivery_type cannot be rendered or posted', () {
      // `delivery_type` is the key posted as `saver_delivery_type`; without it
      // the row has no identity to select or submit.
      final CheckoutSummaryModel summary =
          summaryOf('{"delivery_options":[{"id":9,"delivery_type_text":"Mystery","time_range":"1 hour"}]}');
      expect(summary.deliveryOptions.single.isUsable, isFalse);
    });

    test('a row with a delivery_type is usable even with nothing else', () {
      final CheckoutSummaryModel summary = summaryOf('{"delivery_options":[{"delivery_type":"standard"}]}');
      expect(summary.deliveryOptions.single.isUsable, isTrue);
      expect(summary.deliveryOptions.single.timeRange, isNull);
    });
  });
}
