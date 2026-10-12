import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/checkout/widgets/saver_delivery_time_widget.dart';

/// Covers the fee test that decides whether the saver delivery tiers
/// (Express / Slightly Delay / Standard) are selectable.
///
/// This logic used to sit inside `SaverDeliveryTimeWidget.canShow`, where it
/// controlled whether the section rendered **at all**. On an area- or ZIP-priced
/// zone that made the whole section vanish on arrival at checkout and only appear
/// after the customer picked their area — because the client has no formula for
/// `area_wise` / `zip_code_wise` pricing (`_calculateOriginalDeliveryCharge` only
/// branches on `distance` and `fixed`), so the fallback fee is `0`, and the
/// server's pre-pick quote is the rule's bare minimum, which can sit below the
/// module's own `pivot.minimum_delivery_charge`.
///
/// Visibility is now decided by the zone/module config alone and this test covers
/// only selectability. It is a plain static taking primitives precisely so it can
/// be tested — the widget itself cannot be mounted in a bare test, because
/// `Dimensions` reads `Get.context!` in its static initialisers.
void main() {
  group('SaverDeliveryTimeWidget.isDeliveryChargeEligible', () {
    test('a free delivery (0) is not eligible — there is no fee to vary', () {
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: 0, minimumDeliveryCharge: 20),
        isFalse,
      );
    });

    test('a fee still being calculated (-1) is not eligible', () {
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: -1, minimumDeliveryCharge: 20),
        isFalse,
      );
    });

    test('the reported case: area-wise quote before a pick (15) is below the module minimum (20)', () {
      // `docs/checkout-summary-api-guide.md`: an area-wise rule with no pick
      // quotes the rule's own minimum. That is exactly what used to hide the
      // whole section on arrival.
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: 15, minimumDeliveryCharge: 20),
        isFalse,
      );
    });

    test('the same zone after a pick (30) clears the module minimum', () {
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: 30, minimumDeliveryCharge: 20),
        isTrue,
      );
    });

    test('a fee exactly at the minimum is eligible — the bound is inclusive', () {
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: 20, minimumDeliveryCharge: 20),
        isTrue,
      );
    });

    test('no configured minimum means any positive fee is eligible', () {
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: 5, minimumDeliveryCharge: null),
        isTrue,
      );
    });

    test('a negative fee is not rescued by the absence of a minimum', () {
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: -1, minimumDeliveryCharge: null),
        isFalse,
      );
    });

    test('a zero minimum does not make a zero fee eligible', () {
      // `0 < 0` is false, so the below-minimum branch does not fire — the
      // `> 0` test is what has to catch this.
      expect(
        SaverDeliveryTimeWidget.isDeliveryChargeEligible(deliveryCharge: 0, minimumDeliveryCharge: 0),
        isFalse,
      );
    });
  });
}
