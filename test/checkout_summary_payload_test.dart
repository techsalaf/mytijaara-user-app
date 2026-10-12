import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';

/// Every payload here is copied from `docs/checkout-summary-api-guide.md`, which
/// captured them from a live run. The envelope is unwrapped the way
/// `ApiClient.handleResponse` unwraps it, so what the models see in these tests
/// is exactly what a repository sees at runtime.
void main() {
  dynamic contentOf(String wire) => ApiClient.unwrapEnvelope(jsonDecode(wire), 200);

  CheckoutSummaryModel parseSummary(String wire) =>
      CheckoutSummaryModel.fromJson(Map<String, dynamic>.from(contentOf(wire) as Map));

  group('checkout-summary — the documented baseline response', () {
    const String wire = '''
    {
      "identical_code": "default_200",
      "message": "Successfully fetched",
      "content": {
        "tax": {"tax_amount": 0, "tax_status": "excluded", "tax_included": 0,
                "total_price": 0, "pro_discount": 0, "ref_bonus_amount": 0},
        "delivery": {"delivery_charge": 20.0, "delivery_charge_before_pro_discount": 20.0,
                     "original_delivery_charge": 20.0, "base_delivery_charge": 20.0,
                     "surge_amount": 0.0, "free_delivery_by": null,
                     "pro_customer_savings": 0.0, "vehicle_id": 1},
        "surge": null,
        "pro": {"status": false, "type": null, "discount": 0.0,
                "delivery_savings": 0.0, "total_savings": 0.0},
        "cashback": {"calculated_amount": 50.0, "cashback_amount": 10.0,
                     "cashback_type": "percentage", "min_purchase": 500.0,
                     "max_discount": 100.0, "id": 1}
      },
      "errors": []
    }''';

    test('every block parses', () {
      final CheckoutSummaryModel summary = parseSummary(wire);

      expect(summary.delivery!.deliveryCharge, 20.0);
      expect(summary.delivery!.baseDeliveryCharge, 20.0);
      expect(summary.delivery!.surgeAmount, 0.0);
      expect(summary.delivery!.freeDeliveryBy, isNull);
      expect(summary.delivery!.vehicleId, 1);
      expect(summary.tax!.taxAmount, 0);
      expect(summary.tax!.isTaxIncluded, isFalse);
      expect(summary.surge, isNull);
      expect(summary.pro!.status, isFalse);
      expect(summary.cashback!.calculatedAmount, 50.0);
      expect(summary.cashback!.cashbackType, 'percentage');
    });
  });

  group('checkout-summary — the floor a saver reduction stops at', () {
    // Captured from a live run: a 70 fee, a 50 floor and a tier offering 50 off, which
    // is the case the reduction cannot be taken in full for.
    const String wire = '''
    {
      "identical_code": "default_200",
      "message": "Successfully fetched",
      "content": {
        "delivery": {"delivery_charge": 7.0, "delivery_charge_before_pro_discount": 70.0,
                     "original_delivery_charge": 70.0, "base_delivery_charge": 70.0,
                     "min_delivery_charge": 50.0, "surge_amount": 0.0, "free_delivery_by": "admin",
                     "pro_customer_savings": 63.0, "vehicle_id": 1},
        "delivery_options": [
          {"id": 52, "delivery_type": "slightly_delay", "delivery_type_text": "Slightly delay",
           "extra_charge": 0.0, "reduce_charge": 50.0, "time_range": "20 min - 1 hour 10 min"}
        ]
      },
      "errors": []
    }''';

    test('min_delivery_charge is read off the delivery block', () {
      expect(parseSummary(wire).delivery!.minDeliveryCharge, 50.0);
    });

    test('a quote that names no floor reads as none rather than zero', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":'
        '{"delivery":{"delivery_charge":20.0}},"errors":[]}',
      );
      // Null falls through to the zone config; a zero would assert "no floor" and let
      // the whole reduce charge come off.
      expect(summary.delivery!.minDeliveryCharge, isNull);
    });

    test('the floor leaves only part of the reduce charge to take', () {
      final CheckoutSummaryModel summary = parseSummary(wire);
      final double fee = summary.delivery!.deliveryChargeBeforeProDiscount!;
      final double floor = summary.delivery!.minDeliveryCharge!;
      final double reduceCharge = summary.deliveryOptions.first.chargeAdjustment;

      // What `getEffectiveSaverDeliveryAdjustment` caps the tier to, in the open.
      final double maxReduction = (fee - floor).clamp(0, fee).toDouble();
      expect(reduceCharge, -50.0);
      expect(maxReduction, 20.0);
      expect(fee - maxReduction, floor);
    });
  });

  group('checkout-summary — nullable blocks mean absent, not zero', () {
    test('delivery: null (address outside the store zone) is not read as free', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":'
        '{"tax":{"tax_amount":0},"delivery":null,"surge":null,"pro":null,"cashback":null},"errors":[]}',
      );
      // The screen keys "out of coverage" off delivery == null. A model that
      // defaulted this to a zero-fee object would render it as "free" instead.
      expect(summary.delivery, isNull);
    });

    test('surge: null means nothing is surged', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":'
        '{"tax":null,"delivery":null,"surge":null,"pro":null,"cashback":null},"errors":[]}',
      );
      expect(summary.surge, isNull);
    });

    test('a missing block is null rather than a throw', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{},"errors":[]}',
      );
      expect(summary.tax, isNull);
      expect(summary.delivery, isNull);
      expect(summary.pro, isNull);
      expect(summary.cashback, isNull);
    });
  });

  group('checkout-summary — take-away', () {
    test('no address, no fee, no vehicle', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{"delivery":'
        '{"delivery_charge":0.0,"delivery_charge_before_pro_discount":0.0,'
        '"original_delivery_charge":0.0,"base_delivery_charge":0.0,"surge_amount":0.0,'
        '"free_delivery_by":null,"pro_customer_savings":0.0,"vehicle_id":null}},"errors":[]}',
      );
      expect(summary.delivery, isNotNull);
      expect(summary.delivery!.deliveryCharge, 0.0);
      expect(summary.delivery!.vehicleId, isNull);
    });
  });

  group('checkout-summary — surge', () {
    test('the documented 25% surge parses, note shown', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{"surge":'
        '{"title":"Monsoon surge","customer_note":"Heavy rain in your area",'
        '"customer_note_status":1,"price":"25.00","price_type":"percent","zone_id":1}},"errors":[]}',
      );
      expect(summary.surge!.title, 'Monsoon surge');
      // `price` arrives as a *string* — the reason the model reads it tolerantly.
      expect(summary.surge!.price, 25.0);
      expect(summary.surge!.priceType, 'percent');
      expect(summary.surge!.zoneId, 1);
      expect(summary.surge!.hasCustomerNote, isTrue);
    });

    test('a free delivery blanks the note and clears its status', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{"surge":'
        '{"title":"Monsoon surge","customer_note":"","customer_note_status":0,'
        '"price":"25.00","price_type":"percent","zone_id":1}},"errors":[]}',
      );
      // Nothing is surged onto a free delivery, so there is nothing to explain.
      expect(summary.surge!.hasCustomerNote, isFalse);
    });
  });

  group('checkout-summary — the invariant CheckoutScreen relies on', () {
    // The screen feeds `delivery_charge_before_pro_discount` into its existing
    // gross-fee variable and `pro_customer_savings` into the discount it already
    // subtracts. That is only equivalent to the server's net figure if these agree.
    test('before_pro_discount minus pro_customer_savings equals delivery_charge', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{"delivery":'
        '{"delivery_charge":15.0,"delivery_charge_before_pro_discount":20.0,'
        '"original_delivery_charge":20.0,"base_delivery_charge":20.0,"surge_amount":0.0,'
        '"free_delivery_by":null,"pro_customer_savings":5.0,"vehicle_id":1}},"errors":[]}',
      );
      final CheckoutSummaryDelivery d = summary.delivery!;
      expect(d.deliveryChargeBeforeProDiscount! - d.proCustomerSavings!, d.deliveryCharge);
    });

    test('with no Pro discount the two fee fields are equal, so the row still renders', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{"delivery":'
        '{"delivery_charge":20.0,"delivery_charge_before_pro_discount":20.0,'
        '"pro_customer_savings":0.0}},"errors":[]}',
      );
      final CheckoutSummaryDelivery d = summary.delivery!;
      expect(d.deliveryChargeBeforeProDiscount, d.deliveryCharge);
    });

    test('free delivery is detected from free_delivery_by, not only from a zero', () {
      final CheckoutSummaryModel summary = parseSummary(
        '{"identical_code":"default_200","message":"ok","content":{"delivery":'
        '{"delivery_charge":0.0,"base_delivery_charge":20.0,"surge_amount":5.0,'
        '"free_delivery_by":"admin"}},"errors":[]}',
      );
      expect(summary.delivery!.isFreeDelivery, isTrue);
      expect(summary.delivery!.freeDeliveryBy, 'admin');
    });
  });

  group('coverage-list', () {
    CoverageListModel parseCoverage(String wire) =>
        CoverageListModel.fromJson(Map<String, dynamic>.from(contentOf(wire) as Map));

    test('distance_wise returns an empty list — the answer, not a missing one', () {
      final CoverageListModel coverage = parseCoverage(
        '{"identical_code":"default_200","message":"ok",'
        '"content":{"type":"distance_wise","coverage":[]},"errors":[]}',
      );
      expect(coverage.type, 'distance_wise');
      expect(coverage.coverage, isEmpty);
      expect(coverage.requiresSelection, isFalse);
    });

    test('fixed_amount needs no pick either', () {
      final CoverageListModel coverage = parseCoverage(
        '{"identical_code":"default_200","message":"ok",'
        '"content":{"type":"fixed_amount","coverage":[]},"errors":[]}',
      );
      expect(coverage.requiresSelection, isFalse);
    });

    test('area_wise lists its options and asks for a pick', () {
      final CoverageListModel coverage = parseCoverage(
        '{"identical_code":"default_200","message":"ok","content":{"type":"area_wise",'
        '"coverage":[{"id":794,"name":"Doc Far"},{"id":793,"name":"Doc Near"}]},"errors":[]}',
      );
      expect(coverage.requiresSelection, isTrue);
      expect(coverage.isZipCode, isFalse);
      expect(coverage.coverage.map((CoverageOption o) => o.id), <int>[794, 793]);
      expect(coverage.coverage.first.name, 'Doc Far');
    });

    test('zip_code_wise posts back under zip_code_id', () {
      final CoverageListModel coverage = parseCoverage(
        '{"identical_code":"default_200","message":"ok","content":{"type":"zip_code_wise",'
        '"coverage":[{"id":12,"name":"1207"}]},"errors":[]}',
      );
      expect(coverage.requiresSelection, isTrue);
      expect(coverage.isZipCode, isTrue);
    });

    test('type null means no active rule — the zone pivot prices it, no picker', () {
      final CoverageListModel coverage = parseCoverage(
        '{"identical_code":"default_200","message":"ok",'
        '"content":{"type":null,"coverage":[]},"errors":[]}',
      );
      expect(coverage.type, isNull);
      expect(coverage.requiresSelection, isFalse);
    });

    test('an area_wise rule with no options does not ask for an impossible pick', () {
      final CoverageListModel coverage = parseCoverage(
        '{"identical_code":"default_200","message":"ok",'
        '"content":{"type":"area_wise","coverage":[]},"errors":[]}',
      );
      expect(coverage.requiresSelection, isFalse);
    });
  });

  group('CheckoutSummaryBodyModel', () {
    test('sends only the keys it has — an explicit null would fail validation', () {
      final Map<String, dynamic> body = const CheckoutSummaryBodyModel(
        orderType: 'take_away', storeId: 5, orderAmount: 500,
      ).toJson();

      expect(body, <String, dynamic>{'order_type': 'take_away', 'order_amount': 500.0, 'store_id': 5});
      expect(body.containsKey('distance'), isFalse);
      expect(body.containsKey('latitude'), isFalse);
    });

    test('a delivery order carries distance in kilometres and the address', () {
      final Map<String, dynamic> body = const CheckoutSummaryBodyModel(
        orderType: 'delivery', storeId: 5, orderAmount: 500, distance: 4,
        latitude: '26.558691413230427', longitude: '81.06887096259652',
      ).toJson();

      expect(body['distance'], 4);
      expect(body['latitude'], '26.558691413230427');
    });

    test('a coverage pick is carried under the right key', () {
      expect(
        const CheckoutSummaryBodyModel(orderType: 'delivery', orderAmount: 500, areaId: 793).toJson()['area_id'],
        793,
      );
      expect(
        const CheckoutSummaryBodyModel(orderType: 'delivery', orderAmount: 500, zipCodeId: 12).toJson()['zip_code_id'],
        12,
      );
    });

    test('the saver tier is carried as delivery_type, and omitted when there is none', () {
      expect(
        const CheckoutSummaryBodyModel(
          orderType: 'delivery', orderAmount: 500, deliveryType: 'slightly_delay',
        ).toJson()['delivery_type'],
        'slightly_delay',
      );
      expect(
        const CheckoutSummaryBodyModel(orderType: 'delivery', orderAmount: 500).toJson().containsKey('delivery_type'),
        isFalse,
      );
    });

    test('a coverage requote keeps the tier, so the fee does not fall back to standard', () {
      const CheckoutSummaryBodyModel picked = CheckoutSummaryBodyModel(
        orderType: 'delivery', orderAmount: 500, deliveryType: 'express', weightId: 3,
      );

      expect(picked.copyWithCoverage(areaId: 793).toJson()['delivery_type'], 'express');
      expect(picked.copyWithTiers(dimensionId: 7).toJson()['delivery_type'], 'express');
    });

    test('a guest id of "0" is treated as absent rather than sent', () {
      final Map<String, dynamic> body = const CheckoutSummaryBodyModel(
        orderType: 'delivery', orderAmount: 500, guestId: '0',
      ).toJson();
      expect(body.containsKey('guest_id'), isFalse);
    });

    test('the signature changes when a pick changes, so the quote refires', () {
      const CheckoutSummaryBodyModel base = CheckoutSummaryBodyModel(orderType: 'delivery', orderAmount: 500);
      const CheckoutSummaryBodyModel picked = CheckoutSummaryBodyModel(orderType: 'delivery', orderAmount: 500, areaId: 793);

      expect(base.signature, isNot(picked.signature));
      // ...and is stable for identical inputs, so a rebuild does not requote.
      expect(base.signature, const CheckoutSummaryBodyModel(orderType: 'delivery', orderAmount: 500).signature);
    });

    test('the signature changes with the saver tier, so picking one refires the quote', () {
      const CheckoutSummaryBodyModel standard = CheckoutSummaryBodyModel(
        orderType: 'delivery', orderAmount: 500, deliveryType: 'standard',
      );
      const CheckoutSummaryBodyModel delayed = CheckoutSummaryBodyModel(
        orderType: 'delivery', orderAmount: 500, deliveryType: 'slightly_delay',
      );

      expect(standard.signature, isNot(delayed.signature));
    });
  });

  group('PlaceOrderBodyModel carries the same pick to place_order', () {
    PlaceOrderBodyModel orderBody({int? areaId, int? zipCodeId}) => PlaceOrderBodyModel(
      cart: const <OnlineCart>[], couponDiscountAmount: 0, couponCode: null, orderAmount: 500,
      orderType: 'delivery', paymentMethod: 'cash_on_delivery', storeId: 5, distance: 4,
      discountAmount: 0, orderNote: '', address: 'x', latitude: '1', longitude: '2',
      senderZoneId: null, contactPersonName: 'n', contactPersonNumber: '1', addressType: 'home',
      receiverDetails: null, parcelCategoryId: null, chargePayer: null, streetNumber: '',
      house: '', floor: '', dmTips: '', unavailableItemNote: '', deliveryInstruction: '',
      cutlery: 0, partialPayment: 0, guestId: 0, isBuyNow: 0, guestEmail: null,
      extraPackagingAmount: 0, createNewUser: 0, password: null,
      areaId: areaId, zipCodeId: zipCodeId,
    );

    test('an area pick is posted as area_id', () {
      expect(orderBody(areaId: 793).toJson()['area_id'], '793');
    });

    test('a ZIP pick is posted as zip_code_id', () {
      expect(orderBody(zipCodeId: 12).toJson()['zip_code_id'], '12');
    });

    test('no pick sends neither key — an absent rule must not become id 0', () {
      final Map<String, String> json = orderBody().toJson();
      expect(json.containsKey('area_id'), isFalse);
      expect(json.containsKey('zip_code_id'), isFalse);
    });
  });

  group('copyWithCoverage — swapping the pick without dragging the old one along', () {
    const CheckoutSummaryBodyModel base = CheckoutSummaryBodyModel(
      orderType: 'delivery', storeId: 5, orderAmount: 500, distance: 4,
      latitude: '26.55', longitude: '81.06', couponCode: 'FREEDEL',
    );

    test('keeps every other input identical', () {
      final Map<String, dynamic> json = base.copyWithCoverage(areaId: 793).toJson();
      expect(json['store_id'], 5);
      expect(json['order_amount'], 500.0);
      expect(json['distance'], 4);
      expect(json['latitude'], '26.55');
      expect(json['coupon_code'], 'FREEDEL');
    });

    test('an area pick replaces a previous ZIP pick rather than joining it', () {
      // Only one of the two can be set. Merging would post both and let the
      // server price against whichever it read first.
      final CheckoutSummaryBodyModel withZip = base.copyWithCoverage(zipCodeId: 12);
      final Map<String, dynamic> swapped = withZip.copyWithCoverage(areaId: 793).toJson();

      expect(swapped['area_id'], 793);
      expect(swapped.containsKey('zip_code_id'), isFalse);
    });

    test('clearing the pick sends neither key', () {
      final Map<String, dynamic> json = base.copyWithCoverage(areaId: 793).copyWithCoverage().toJson();
      expect(json.containsKey('area_id'), isFalse);
      expect(json.containsKey('zip_code_id'), isFalse);
    });

    test('the signature moves with the pick, so the requote is not skipped', () {
      expect(base.signature, isNot(base.copyWithCoverage(areaId: 793).signature));
    });
  });

  group('coverage gating — when the place-order button must block', () {
    CoverageListModel coverageOf(String type, {bool withOptions = true}) => CoverageListModel.fromJson(<String, dynamic>{
      'type': type,
      'coverage': withOptions ? <dynamic>[<String, dynamic>{'id': 793, 'name': 'Doc Near'}] : <dynamic>[],
    });

    // Mirrors CheckoutController.needCoverageAreaSelection, which the button
    // reads. Kept here as pure logic because the controller needs the whole GetX
    // container stood up to instantiate.
    bool needSelection(CoverageListModel? coverage, String orderType) =>
        (coverage?.requiresSelection ?? false) && orderType == 'delivery';

    test('area_wise delivery asks for a pick', () {
      expect(needSelection(coverageOf('area_wise'), 'delivery'), isTrue);
    });

    test('zip_code_wise delivery asks for a pick', () {
      expect(needSelection(coverageOf('zip_code_wise'), 'delivery'), isTrue);
    });

    test('take_away never asks, even in an area_wise zone', () {
      // A take-away order has no delivery fee to price, so demanding an area
      // would block an order that never needed one.
      expect(needSelection(coverageOf('area_wise'), 'take_away'), isFalse);
    });

    test('distance_wise and fixed_amount never ask', () {
      expect(needSelection(coverageOf('distance_wise', withOptions: false), 'delivery'), isFalse);
      expect(needSelection(coverageOf('fixed_amount', withOptions: false), 'delivery'), isFalse);
    });

    test('a coverage list that has not loaded yet does not block the order', () {
      expect(needSelection(null, 'delivery'), isFalse);
    });

    test('an area_wise rule with no options does not block on an impossible pick', () {
      expect(needSelection(coverageOf('area_wise', withOptions: false), 'delivery'), isFalse);
    });
  });
}
