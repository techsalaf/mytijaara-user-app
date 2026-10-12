import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/services/happy_hour_service_interface.dart';

/// `GET /customer/cart/discount-eligibility` → the cart's Discount row.
///
/// The endpoint's `discount_amount` used to be parsed and then read by nothing;
/// the row showed the client's own walk of the cart instead. The server figure is
/// authoritative — it knows which part of the basket the rate reaches and what
/// cap the store put on the payout — so the row now prefers it.
///
/// The invariant these protect is that the row and the subtotal stay two views of
/// one number: `CartController.subTotal` is net of the *client* figure, so
/// whichever discount is displayed has to be netted off the **gross** basket.
class _FakeHappyHourService implements HappyHourServiceInterface {
  _FakeHappyHourService(this.response);

  final DiscountEligibilityModel? response;
  int calls = 0;

  @override
  Future<DiscountEligibilityModel?> getDiscountEligibility(int storeId) async {
    calls++;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} is not expected on the eligibility path',
      );
}

DiscountEligibilityModel _eligibility(String rawBody) =>
    DiscountEligibilityModel.fromJson(jsonDecode(rawBody) as Map<String, dynamic>);

/// A qualified happy-hour basket: the server reached 42.50 of discount.
const String _qualified = '''
{"source":"happy_hour","percentage":10,"min_purchase":200,"max_discount":50,
 "qualifying_amount":425,"shortfall":0,"is_qualified":true,"discount_amount":42.5}''';

Future<HappyHourController> controllerWith(DiscountEligibilityModel? response, {int storeId = 7}) async {
  final HappyHourController controller =
      HappyHourController(happyHourServiceInterface: _FakeHappyHourService(response));
  await controller.getDiscountEligibility(storeId);
  return controller;
}

void main() {
  group('discountAmountFor', () {
    test('prefers the server figure over the client walk', () async {
      final HappyHourController controller = await controllerWith(_eligibility(_qualified));
      // The client had reached 40.00 by walking the cart; the server says 42.50,
      // having applied the cap and the reachable-basket rule.
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 42.5);
    });

    test('keeps the client figure for a store never asked about', () async {
      final HappyHourController controller = await controllerWith(_eligibility(_qualified));
      // Eligibility is only fetched while a Happy Hour runs, so every ordinary
      // store must behave exactly as before.
      expect(controller.discountAmountFor(storeId: 99, fallback: 40), 40);
      expect(controller.discountAmountFor(storeId: null, fallback: 40), 40);
    });

    test('keeps the client figure when the call failed', () async {
      final HappyHourController controller = await controllerWith(null);
      // A null answer settles nothing; blanking a discount the customer can
      // already see would be worse than a slightly stale one.
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });

    test('keeps the client figure when the key is missing from the answer', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":true}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });

    test('a store_discount source is honoured, not just happy_hour', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":true,"discount_amount":30}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 30);
    });

    test('an unnamed source falls back, even with an amount beside it', () async {
      // With neither kind running the server answers `source: null`; the figure
      // next to it describes nothing, so the cart walk stands.
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":null,"is_qualified":true,"discount_amount":12}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });

    test('a source this build does not know falls back rather than guessing', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"seasonal_campaign","is_qualified":true,"discount_amount":12}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });
  });

  group('discountSourceMessageFor — what the info icon cites', () {
    test('names a happy hour', () async {
      final HappyHourController controller = await controllerWith(_eligibility(_qualified));
      expect(controller.discountSourceMessageFor(7), isNotNull);
    });

    test('names a store discount', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":true,"discount_amount":30}'),
      );
      expect(controller.discountSourceMessageFor(7), isNotNull);
    });

    test('the two sources are worded differently', () async {
      final HappyHourController happy = await controllerWith(_eligibility(_qualified));
      final HappyHourController store = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":true,"discount_amount":30}'),
      );
      expect(happy.discountSourceMessageFor(7), isNot(store.discountSourceMessageFor(7)));
    });

    test('no icon when the server named no source', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":null,"is_qualified":true,"discount_amount":12}'),
      );
      // The row is then the client's own walk, and there is no source to cite.
      expect(controller.discountSourceMessageFor(7), isNull);
    });

    test('no icon for a store never asked about', () async {
      final HappyHourController controller = await controllerWith(_eligibility(_qualified));
      expect(controller.discountSourceMessageFor(99), isNull);
      expect(controller.discountSourceMessageFor(null), isNull);
    });

    test('a server zero is honoured — it is an answer, not an absence', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"happy_hour","is_qualified":true,"discount_amount":0}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 0);
    });

    test('a negative amount is refused rather than credited', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"happy_hour","is_qualified":true,"discount_amount":-5}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });
  });

  group('withholdsDiscount still gates the row', () {
    test('an unqualified happy hour withholds, whatever the amount says', () async {
      final HappyHourController controller = await controllerWith(_eligibility(
        '{"source":"happy_hour","min_purchase":200,"shortfall":75,'
        '"is_qualified":false,"discount_amount":42.5}',
      ));
      // The rate is baked into item prices but the server will not honour it
      // until the basket clears `min_purchase`, so the cart must not quote it.
      expect(controller.withholdsDiscount(7), isTrue);
    });

    test("a store's own standing discount is never withheld", () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":false,"discount_amount":30}'),
      );
      // `withholdsDiscount` is a Happy Hour rule and still does not fire here —
      // the row is not blanked. It falls back to the client figure instead, via
      // the `is_qualified` gate below.
      expect(controller.withholdsDiscount(7), isFalse);
    });
  });

  group('is_qualified decides whether the server figure is used', () {
    test('a qualified basket shows the server amount', () async {
      final HappyHourController controller = await controllerWith(_eligibility(_qualified));
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 42.5);
    });

    test('an unqualified happy hour falls back to the item discount', () async {
      final HappyHourController controller = await controllerWith(_eligibility(
        '{"source":"happy_hour","min_purchase":200,"shortfall":75,'
        '"is_qualified":false,"discount_amount":42.5}',
      ));
      // The basket has not cleared `min_purchase`, so 42.50 is a discount the
      // order will not get. The client's own figure stands until it qualifies.
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });

    test('an unqualified store discount falls back the same way', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":false,"discount_amount":30}'),
      );
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });

    test('a missing is_qualified is treated as not qualified', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","discount_amount":30}'),
      );
      // Absent reads as false, so a server that stops sending the key cannot
      // silently start quoting unearned discounts.
      expect(controller.discountAmountFor(storeId: 7, fallback: 40), 40);
    });

    test('the info icon stays away while the row is the client figure', () async {
      final HappyHourController controller = await controllerWith(
        _eligibility('{"source":"store_discount","is_qualified":false,"discount_amount":30}'),
      );
      // Citing "Store discount applied" beside a figure the server did not
      // supply would attribute it wrongly.
      expect(controller.discountSourceMessageFor(7), isNull);
    });
  });

  group('the bill reconciles', () {
    // Mirrors the cart screen: `subTotal` is net of the client figure, so the
    // gross is recovered by adding it back before the shown discount comes off.
    double shownSubtotal({required double netSubtotal, required double clientDiscount, required double shownDiscount}) =>
        netSubtotal + clientDiscount - shownDiscount;

    test('with no server answer it is byte-for-byte the old behaviour', () {
      // discount shown == client figure, so the two cancel.
      expect(shownSubtotal(netSubtotal: 360, clientDiscount: 40, shownDiscount: 40), 360);
    });

    test('a withheld discount adds it back, as before', () {
      expect(shownSubtotal(netSubtotal: 360, clientDiscount: 40, shownDiscount: 0), 400);
    });

    test('a larger server discount lowers the subtotal to match the row', () {
      // Gross 400, server says 42.50 → 357.50, and 400 − 42.50 reconciles.
      expect(shownSubtotal(netSubtotal: 360, clientDiscount: 40, shownDiscount: 42.5), 357.5);
    });

    test('a smaller server discount raises it to match', () {
      expect(shownSubtotal(netSubtotal: 360, clientDiscount: 40, shownDiscount: 25), 375);
    });
  });
}
