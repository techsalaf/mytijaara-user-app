import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/domain/models/surge_price_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';

/// What the delivery fee row's info icon explains.
///
/// The row shows one figure, but `checkout-summary` prices it from several
/// parts — `base_delivery_charge` plus `surge_amount`, with a vehicle charge on
/// top where the zone has one. A customer looking at a fee that moved has no way
/// to tell which part moved it, so each part that has an explanation contributes
/// a line here.
///
/// Pure on purpose: it takes the two values rather than reaching for
/// `CheckoutController`, so the composition can be tested without a GetX
/// container standing behind it.
class DeliveryFeeTooltip {
  const DeliveryFeeTooltip._();

  /// The tooltip text, or null when there is nothing to explain — the caller
  /// then draws no icon at all rather than an icon with an empty bubble.
  ///
  /// Composed rather than one-or-the-other: a surged zone can also carry a
  /// vehicle charge, and dropping one because the other applied would leave part
  /// of the fee unexplained.
  static String? compose({required double? extraCharge, required SurgePriceModel? surge}) {
    final List<String> lines = <String>[];

    if (explainsVehicleCharge(extraCharge)) {
      lines.add('${"Vehicle Charge".tr} ${PriceConverter.convertPrice(extraCharge)}');
    }
    final String? surgeLine = surgeMessage(surge);
    if (surgeLine != null) {
      lines.add(surgeLine);
    }

    return lines.isEmpty ? null : lines.join('\n\n');
  }

  /// The reduce charge a saver tier could not spend, or null when there is nothing
  /// held back — the caller then adds no line.
  ///
  /// A `slightly_delay` reduction stops at the zone's minimum delivery charge, so a
  /// tier advertising a discount can leave the fee exactly where it was. The figure
  /// quoted is the floor that capped it, because that is the part the customer can
  /// act on: a bigger basket does not move it, a different zone does.
  static String? blockedSaverReductionMessage({required double blockedAmount, required double? minimumDeliveryCharge}) {
    if(blockedAmount <= 0 || minimumDeliveryCharge == null || minimumDeliveryCharge <= 0) {
      return null;
    }
    return 'saver_reduction_limited_by_minimum_delivery_charge'.trParams(<String, String>{
      'amount': PriceConverter.convertPrice(minimumDeliveryCharge),
    });
  }

  /// The surge explained in one line, or null when there is no surge to explain.
  ///
  /// `surge 50% included` on its own, or `<note>, surge 50% included` when the
  /// admin published a note. The note is their wording and theirs to withhold;
  /// the rate is what the customer paid, so it is shown either way.
  ///
  /// Split out of [compose] so the store checkout, whose fee row explains a
  /// vehicle charge differently, can use the surge half without the rest.
  static String? surgeMessage(SurgePriceModel? surge) {
    if (!explainsSurge(surge)) return null;
    final String rate = surgeSummary(surge!);
    return surge.hasCustomerNote ? '${surge.customerNote}, $rate' : rate;
  }

  /// Split out from [compose] so what the icon decides can be checked without a
  /// GetX container behind it — the lines themselves go through
  /// `PriceConverter`, which reads the currency config off `SplashController`.
  static bool explainsVehicleCharge(double? extraCharge) => (extraCharge ?? 0) > 0;

  /// An active surge always has something to say, because the customer paid it.
  ///
  /// Deliberately **not** gated on `customer_note_status`: that flag decides
  /// whether the admin's own wording is shown, not whether the surcharge is
  /// acknowledged. Gating the whole icon on it hid a real charge behind an
  /// editorial setting — a fee 50% above the base with nothing on screen saying
  /// so.
  ///
  /// The `price > 0` guard is belt-and-braces: the server omits the block
  /// entirely when nothing is surged, so a zero-rate surge should not reach
  /// here, and "surge 0% included" would explain nothing if it did.
  static bool explainsSurge(SurgePriceModel? surge) => surge != null && (surge.price ?? 0) > 0;

  /// `surge 50% included` — the rate as configured, not the money it worked out
  /// to. The amount is already inside the fee beside it; the rate is the part
  /// that explains *why* the fee is what it is.
  ///
  /// One key with a placeholder rather than words concatenated around a number,
  /// so a translator can move the rate within the sentence — several languages
  /// will not leave it where English does.
  static String surgeSummary(SurgePriceModel surge) =>
      'surge_rate_included'.trParams(<String, String>{'rate': surgeRate(surge)});

  /// `50%`, or the amount for a flat surge.
  static String surgeRate(SurgePriceModel surge) {
    final double price = surge.price ?? 0;
    if (surge.priceType != 'percent') {
      return PriceConverter.convertPrice(price);
    }
    // `price` arrives as `50.00`; a rate an admin typed as `50` should not read
    // back as `50.00%`.
    final String rendered =
        price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toString();
    return '$rendered%';
  }
}
