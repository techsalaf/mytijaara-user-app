import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/surge_price_model.dart';
import 'package:sixam_mart/helper/delivery_fee_tooltip.dart';

/// What the parcel bill's delivery-fee info icon explains.
///
/// The row renders one figure that `checkout-summary` prices from several parts
/// (`base_delivery_charge` + `surge_amount`, plus a vehicle charge where the
/// zone has one). These guard that each part with an explanation contributes a
/// line, that a surge with nothing to say contributes none, and that the icon
/// disappears entirely rather than opening an empty bubble.

/// The live 200 for a surged parcel, shape intact.
const String _surgedBody = '''
{"tax":{"tax_amount":0,"tax_included":1,"tax_status":"included"},
 "delivery":{"delivery_charge":180.0,"delivery_charge_before_pro_discount":180.0,
   "original_delivery_charge":180.0,"base_delivery_charge":120.0,"surge_amount":60.0,
   "free_delivery_by":null,"pro_customer_savings":0.0,"vehicle_id":1},
 "surge":{"title":"main zone","customer_note":"Main zone surge test case",
   "customer_note_status":1,"price":"50.00","price_type":"percent","zone_id":1},
 "pro":{"status":false,"type":null,"discount":0.0,"delivery_savings":0.0,"total_savings":0.0},
 "cashback":{"calculated_amount":0.0,"cashback_amount":0,"cashback_type":"",
   "min_purchase":0,"max_discount":0,"id":null},
 "delivery_options":null}''';

CheckoutSummaryModel _summary(String rawBody) =>
    CheckoutSummaryModel.fromJson(jsonDecode(rawBody) as Map<String, dynamic>);

SurgePriceModel _surge(String rawSurge) =>
    SurgePriceModel.fromJson(jsonDecode(rawSurge) as Map<String, dynamic>);

void main() {
  // `PriceConverter.convertPrice` reads the config through GetX; the percent
  // path never touches it, so only the amount-typed cases need a container and
  // those assert on structure rather than on a formatted currency string.
  //
  // The real `en.json` is loaded rather than a stub of it, so a key deleted or
  // renamed there fails here instead of silently rendering its own name — which
  // is what `.trParams` falls back to.
  setUp(() {
    Get.reset();
    final Map<String, dynamic> en =
        jsonDecode(File('assets/language/en.json').readAsStringSync()) as Map<String, dynamic>;
    Get.addTranslations(<String, Map<String, String>>{
      'en_US': en.map((String k, dynamic v) => MapEntry<String, String>(k, v.toString())),
    });
    Get.locale = const Locale('en', 'US');
  });

  group('the live surged quote', () {
    test('parses the surge block the tooltip is built from', () {
      final CheckoutSummaryModel summary = _summary(_surgedBody);

      expect(summary.surge, isNotNull);
      expect(summary.surge!.customerNote, 'Main zone surge test case');
      expect(summary.surge!.customerNoteStatus, 1);
      // Sent as the string "50.00"; JsonReader coerces it.
      expect(summary.surge!.price, 50.0);
      expect(summary.surge!.priceType, 'percent');
      expect(summary.surge!.hasCustomerNote, isTrue);
    });

    test('the fee is the base plus the surge, so the note explains a real gap', () {
      final CheckoutSummaryModel summary = _summary(_surgedBody);
      expect(summary.delivery!.baseDeliveryCharge, 120.0);
      expect(summary.delivery!.surgeAmount, 60.0);
      expect(summary.delivery!.deliveryCharge, 180.0);
    });

    test('composes the note with its rate', () {
      final String? message = DeliveryFeeTooltip.compose(
        extraCharge: 0, surge: _summary(_surgedBody).surge,
      );

      // Note, comma, then the rate in a sentence of its own.
      expect(message, 'Main zone surge test case, surge 50% included');
    });
  });

  group('DeliveryFeeTooltip.surgeRate', () {
    test('a whole percent does not read back with decimals', () {
      // The API sends "50.00"; showing `50.00%` reads as a rounding artefact of
      // a rate the admin typed as 50.
      expect(DeliveryFeeTooltip.surgeRate(_surge('{"price":"50.00","price_type":"percent"}')), '50%');
    });

    test('a fractional percent keeps its decimals', () {
      expect(DeliveryFeeTooltip.surgeRate(_surge('{"price":"12.5","price_type":"percent"}')), '12.5%');
    });

    test('a missing price degrades to zero rather than throwing', () {
      expect(DeliveryFeeTooltip.surgeRate(_surge('{"price":null,"price_type":"percent"}')), '0%');
    });
  });

  group('a surge whose note is withheld', () {
    test('still shows the rate — the note is optional, the surcharge is not', () {
      final SurgePriceModel surge =
          _surge('{"customer_note":"internal only","customer_note_status":0,"price":"50.00","price_type":"percent"}');

      expect(surge.hasCustomerNote, isFalse);
      // The admin's wording stays private; the charge the customer paid does not.
      expect(DeliveryFeeTooltip.compose(extraCharge: 0, surge: surge), 'surge 50% included');
    });

    test('an empty note renders the rate alone, with no stray comma', () {
      final SurgePriceModel surge =
          _surge('{"customer_note":"","customer_note_status":1,"price":"50.00","price_type":"percent"}');

      expect(DeliveryFeeTooltip.compose(extraCharge: 0, surge: surge), 'surge 50% included');
    });
  });

  // The store checkout's fee row explains a vehicle charge its own way, so it
  // takes the surge half on its own rather than going through `compose`.
  group('surgeMessage, the entry point the store checkout uses', () {
    test('a silenced note still yields the rate', () {
      // Verbatim surge block from a live store quote: 50% surged, note withheld.
      // This row used to render no icon at all, hiding 881.12 of surcharge.
      final SurgePriceModel surge = _surge(
        '{"title":"main zone","customer_note":"","customer_note_status":0,'
        '"price":"50.00","price_type":"percent","zone_id":1}',
      );
      expect(DeliveryFeeTooltip.surgeMessage(surge), 'surge 50% included');
    });

    test('a published note is prepended', () {
      expect(
        DeliveryFeeTooltip.surgeMessage(_summary(_surgedBody).surge),
        'Main zone surge test case, surge 50% included',
      );
    });

    test('no surge means no icon', () {
      expect(DeliveryFeeTooltip.surgeMessage(null), isNull);
    });

    test('compose and surgeMessage agree on the surge line', () {
      // `compose` delegates here, so the parcel bill and the store bill cannot
      // describe the same surge differently.
      final SurgePriceModel? surge = _summary(_surgedBody).surge;
      expect(DeliveryFeeTooltip.compose(extraCharge: 0, surge: surge), DeliveryFeeTooltip.surgeMessage(surge));
    });
  });

  group('when nothing should be explained', () {
    test('no surge and no vehicle charge draws no icon at all', () {
      expect(DeliveryFeeTooltip.compose(extraCharge: 0, surge: null), isNull);
      expect(DeliveryFeeTooltip.compose(extraCharge: null, surge: null), isNull);
    });

    test('a zero-rate surge explains nothing', () {
      // The server omits the block when nothing is surged, so this should not
      // arrive — but "surge 0% included" would be worse than silence.
      expect(
        DeliveryFeeTooltip.compose(
          extraCharge: 0,
          surge: _surge('{"customer_note":"x","customer_note_status":1,"price":"0","price_type":"percent"}'),
        ),
        isNull,
      );
    });

    test('a quote with no surge block leaves the model null', () {
      final CheckoutSummaryModel summary = _summary('{"delivery":{"delivery_charge":120.0},"surge":null}');
      expect(summary.surge, isNull);
      expect(DeliveryFeeTooltip.compose(extraCharge: 0, surge: summary.surge), isNull);
    });
  });

  // The saver line quotes the floor through `PriceConverter` too, so only the cases
  // that return before formatting are asserted here — which is the whole gate.
  group('a saver reduction the minimum delivery charge held back', () {
    test('nothing held back earns no line', () {
      expect(
        DeliveryFeeTooltip.blockedSaverReductionMessage(blockedAmount: 0, minimumDeliveryCharge: 50),
        isNull,
      );
    });

    test('a zone with no floor of its own has nothing to name', () {
      // The cap is taken from `pivot.minimum_delivery_charge`; with none there is
      // no figure to quote, and a reduction cannot have been held back by it.
      expect(
        DeliveryFeeTooltip.blockedSaverReductionMessage(blockedAmount: 50, minimumDeliveryCharge: null),
        isNull,
      );
      expect(
        DeliveryFeeTooltip.blockedSaverReductionMessage(blockedAmount: 50, minimumDeliveryCharge: 0),
        isNull,
      );
    });
  });

  // The rendered vehicle-charge line runs through `PriceConverter`, which reads
  // the currency config off a registered `SplashController`. Nothing in this
  // suite stands one up, so what that line *decides* is asserted here and the
  // formatted string is left to the screen.
  group('what the icon decides to explain', () {
    test('a vehicle charge above zero earns a line; zero and null do not', () {
      expect(DeliveryFeeTooltip.explainsVehicleCharge(25), isTrue);
      expect(DeliveryFeeTooltip.explainsVehicleCharge(0), isFalse);
      expect(DeliveryFeeTooltip.explainsVehicleCharge(null), isFalse);
    });

    test('both parts can apply at once, so neither excludes the other', () {
      final SurgePriceModel? surge = _summary(_surgedBody).surge;
      // Dropping one because the other applied would leave part of the fee
      // unexplained — a surged zone can also carry a vehicle charge.
      expect(DeliveryFeeTooltip.explainsVehicleCharge(25), isTrue);
      expect(DeliveryFeeTooltip.explainsSurge(surge), isTrue);
    });

    test('the note status does not decide whether the surge is acknowledged', () {
      expect(DeliveryFeeTooltip.explainsSurge(null), isFalse);
      // Silenced note, real surcharge — still explained, just without the wording.
      expect(
        DeliveryFeeTooltip.explainsSurge(
          _surge('{"customer_note":"x","customer_note_status":0,"price":"50.00","price_type":"percent"}')),
        isTrue,
      );
      // Nothing surged is the one case that earns no line.
      expect(
        DeliveryFeeTooltip.explainsSurge(
          _surge('{"customer_note":"x","customer_note_status":1,"price":"0","price_type":"percent"}')),
        isFalse,
      );
    });
  });
}
