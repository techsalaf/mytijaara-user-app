import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';

/// `delivery_duration` — the routing estimate posted with a parcel order.
///
/// It comes from the same `config/distance-api` response the distance is read
/// from, so the two always describe one measured route. The API expresses it as
/// `"11508s"`; the order body posts the bare seconds, because a server that has
/// to strip a unit is a server that can strip the wrong one.
void main() {
  /// Verbatim from the dev backend.
  const String liveBody = '''
  {"distanceMeters":13827,
   "duration":"11508s",
   "localizedValues":{"distance":{"text":"13.8 km"},
     "duration":{"text":"3 hours 12 mins"},
     "staticDuration":{"text":"3 hours 12 mins"}}}''';

  group('parseDurationSeconds', () {
    test('reads the live payload', () {
      final Map<String, dynamic> body = jsonDecode(liveBody) as Map<String, dynamic>;
      expect(CheckoutController.parseDurationSeconds(body['duration']), 11508);
    });

    test('accepts a number, in case the API stops suffixing it', () {
      expect(CheckoutController.parseDurationSeconds(11508), 11508);
      expect(CheckoutController.parseDurationSeconds(11508.4), 11508.4);
    });

    test('tolerates padding and case', () {
      expect(CheckoutController.parseDurationSeconds('  11508S '), 11508);
    });

    test('keeps a fractional duration rather than truncating it here', () {
      // Rounding belongs at the boundary that posts whole seconds, not here.
      expect(CheckoutController.parseDurationSeconds('11508.6s'), 11508.6);
    });

    test('is null for every unusable shape, never an exception', () {
      // Its caller sits inside the try that owns the distance: a throw here
      // would discard a distance that had already parsed and silently fall back
      // to the straight-line estimate.
      for (final dynamic raw in <dynamic>[null, '', '   ', 's', 'abc', 'PT3H12M', <String>['11508s']]) {
        expect(CheckoutController.parseDurationSeconds(raw), isNull, reason: '$raw');
      }
    });

    test('does not mangle an inner "s"', () {
      // `replaceAll('s', '')` would turn "secs" into "ec" and parse it as junk;
      // only a trailing unit is stripped.
      expect(CheckoutController.parseDurationSeconds('11508secs'), isNull);
    });
  });

  group('PlaceOrderBodyModel', () {
    PlaceOrderBodyModel bodyWith({int? deliveryDuration}) => PlaceOrderBodyModel(
      cart: <OnlineCart>[], couponDiscountAmount: null, couponCode: null, orderAmount: 60,
      orderType: 'parcel', paymentMethod: 'cash_on_delivery', storeId: null, distance: 13.827,
      // `taxAmount` is nominally optional, but `fromJson` does
      // `double.parse(json['tax_amount'].toString())` with no null guard, so a
      // body built without it cannot be round-tripped. Pre-existing, unrelated
      // to this field — set here so the round-trip test exercises what it means to.
      taxAmount: 0,
      discountAmount: 0, orderNote: '', receiverDetails: null, parcelCategoryId: '4',
      chargePayer: 'sender', dmTips: '0', unavailableItemNote: '', cutlery: 0, partialPayment: 0,
      guestId: 0, isBuyNow: 0, extraPackagingAmount: null, createNewUser: 0, password: '',
      deliveryDuration: deliveryDuration,
    );

    test('posts the seconds with no unit suffix', () {
      expect(bodyWith(deliveryDuration: 11508).toJson()['delivery_duration'], '11508');
    });

    test('omits the key when the route was never measured', () {
      // The straight-line fallback behind `distance` yields no duration, and a
      // fabricated one would be indistinguishable from a routed estimate.
      expect(bodyWith().toJson().containsKey('delivery_duration'), isFalse);
    });

    test('a zero duration is still sent — it is a measurement, not an absence', () {
      expect(bodyWith(deliveryDuration: 0).toJson()['delivery_duration'], '0');
    });

    test('survives a round trip', () {
      final PlaceOrderBodyModel restored =
          PlaceOrderBodyModel.fromJson(bodyWith(deliveryDuration: 11508).toJson());
      expect(restored.deliveryDuration, 11508);
    });

    test('adding it did not disturb the neighbouring parcel fields', () {
      final Map<String, String> json = bodyWith(deliveryDuration: 11508).toJson();
      expect(json['order_type'], 'parcel');
      expect(json['parcel_category_id'], '4');
      expect(json['distance'], '13.827');
    });
  });
}
