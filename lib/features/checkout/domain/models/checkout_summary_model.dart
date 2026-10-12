import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/checkout/domain/models/surge_price_model.dart';

/// Everything the checkout page shows for a basket, in one response.
///
/// `POST customer/order/checkout-summary` replaces three round trips —
/// `get-Tax`, `get-surge-price` and `cashback/getCashback` — and, more
/// importantly, it is priced by the same methods `place_order` calls. A page
/// assembling a total from three calls can assemble it from three slightly
/// different baskets; this cannot, so the quote a customer is shown is the
/// amount they are charged.
///
/// Two blocks are deliberately nullable and must be rendered as *absent* rather
/// than as zero — see [delivery] and [surge].
class CheckoutSummaryModel {
  final CheckoutSummaryTax? tax;
  final CheckoutSummaryDelivery? delivery;
  final SurgePriceModel? surge;
  final CheckoutSummaryPro? pro;
  final CheckoutSummaryCashback? cashback;

  /// The saver delivery tiers priced for **this** order, each with its time range
  /// already written out. Empty when the platform sends `null` — a parcel quote
  /// always does, and so does a zone with the feature switched off.
  final List<CheckoutSummaryDeliveryOption> deliveryOptions;

  const CheckoutSummaryModel({this.tax, this.delivery, this.surge, this.pro, this.cashback,
    this.deliveryOptions = const <CheckoutSummaryDeliveryOption>[],
  });

  factory CheckoutSummaryModel.fromJson(Map<String, dynamic> json) => CheckoutSummaryModel(
    tax: json['tax'] is Map ? CheckoutSummaryTax.fromJson(Map<String, dynamic>.from(json['tax'] as Map)) : null,
    // `null` when the address falls outside the store's zone and there is
    // nothing to price. Render nothing rather than a zero, which reads as "free".
    delivery: json['delivery'] is Map ? CheckoutSummaryDelivery.fromJson(Map<String, dynamic>.from(json['delivery'] as Map)) : null,
    // `null` when nothing is surged; present only while `price > 0`.
    surge: json['surge'] is Map ? SurgePriceModel.fromJson(Map<String, dynamic>.from(json['surge'] as Map)) : null,
    pro: json['pro'] is Map ? CheckoutSummaryPro.fromJson(Map<String, dynamic>.from(json['pro'] as Map)) : null,
    cashback: json['cashback'] is Map ? CheckoutSummaryCashback.fromJson(Map<String, dynamic>.from(json['cashback'] as Map)) : null,
    deliveryOptions: ResponseParser.listOrEmpty(json['delivery_options'])
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) => CheckoutSummaryDeliveryOption.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

/// One saver delivery tier as the server priced it for this order.
///
/// Supersedes the copy the client assembled from the zone/module config: the
/// range used to be reconstructed here from the store's free-text
/// `delivery_time`, the zone pivot's minimum and the tier's own delta, which
/// could only ever approximate what the platform meant. [timeRange] is that
/// answer, already written out.
class CheckoutSummaryDeliveryOption {
  final int? id;

  /// `standard`, `express`, `slightly_delay` — the key posted as
  /// `saver_delivery_type` and matched against the customer's selection.
  final String? deliveryType;

  /// The server's own display name, e.g. `Slightly delay`. Already localised by
  /// the platform, so it is rendered as sent rather than run through `.tr`.
  final String? deliveryTypeText;

  final double? extraCharge;
  final double? reduceCharge;

  /// The range to show, e.g. `20 min - 1 hour 10 min`. Rendered verbatim.
  final String? timeRange;

  const CheckoutSummaryDeliveryOption({this.id, this.deliveryType, this.deliveryTypeText, this.extraCharge,
    this.reduceCharge, this.timeRange,
  });

  factory CheckoutSummaryDeliveryOption.fromJson(Map<String, dynamic> json) => CheckoutSummaryDeliveryOption(
    id: JsonReader.toInt(json['id']),
    deliveryType: JsonReader.toStr(json['delivery_type']),
    deliveryTypeText: JsonReader.toStr(json['delivery_type_text']),
    extraCharge: JsonReader.toDouble(json['extra_charge']),
    reduceCharge: JsonReader.toDouble(json['reduce_charge']),
    timeRange: JsonReader.toStr(json['time_range']),
  );

  /// What this tier does to the delivery fee — positive adds, negative reduces.
  ///
  /// Subtracted rather than branched on nullness, because this payload sends
  /// **both** keys and zeroes the one that does not apply. The zone-config
  /// shape leaves the unused side null instead, and `(x ?? 0)` reads both the
  /// same way; branching on `extraCharge != null` first, as the config path
  /// does, would read `slightly_delay`'s `extra_charge: 0.0` as "no change" and
  /// silently drop its reduction.
  double get chargeAdjustment => (extraCharge ?? 0) - (reduceCharge ?? 0);

  /// Whether this row can be rendered and posted at all.
  bool get isUsable => (deliveryType ?? '').isNotEmpty;
}

class CheckoutSummaryTax {
  final double? taxAmount;

  /// `included` or `excluded`.
  final String? taxStatus;

  /// The portion already inside the item prices. Kept as the int the API sends,
  /// because `CheckoutController.taxIncluded` is compared against `1`.
  final int? taxIncluded;

  /// The **post-discount** total the free-delivery and Pro rules are measured
  /// against. [proDiscount] and [refBonusAmount] are already inside it — they
  /// are returned separately so a checkout adopting this as its subtotal has
  /// something to name the difference with.
  final double? totalPrice;
  final double? proDiscount;
  final double? refBonusAmount;

  const CheckoutSummaryTax({this.taxAmount, this.taxStatus, this.taxIncluded, this.totalPrice, this.proDiscount,
    this.refBonusAmount,
  });

  factory CheckoutSummaryTax.fromJson(Map<String, dynamic> json) => CheckoutSummaryTax(
    taxAmount: JsonReader.toDouble(json['tax_amount']),
    taxStatus: JsonReader.toStr(json['tax_status']),
    taxIncluded: JsonReader.toInt(json['tax_included']),
    totalPrice: JsonReader.toDouble(json['total_price']),
    proDiscount: JsonReader.toDouble(json['pro_discount']),
    refBonusAmount: JsonReader.toDouble(json['ref_bonus_amount']),
  );

  bool get isTaxIncluded => taxIncluded == 1 || taxStatus == 'included';
}

class CheckoutSummaryDelivery {
  /// **The net figure** — what the customer pays and what the total is built from.
  final double? deliveryCharge;

  /// The same charge immediately before the Pro benefit reduced it. Equal to
  /// [deliveryCharge] when no Pro discount applied, so the row can be rendered
  /// unconditionally and the discount line shown only while savings are above zero.
  final double? deliveryChargeBeforeProDiscount;

  /// The notional full fee, for accounting.
  final double? originalDeliveryCharge;

  /// The fee before the surge; [surgeAmount] is the difference.
  final double? baseDeliveryCharge;
  final double? surgeAmount;

  /// The floor a saver reduction may take the fee down to, for this zone and module.
  ///
  /// The same figure the zone config carries as `pivot.minimum_delivery_charge`, but
  /// quoted against this order — and present whenever the tiers are, which the config
  /// copy is not: that one is read from the saved address and is missing wherever the
  /// address was resolved before the zone had the saver rule.
  final double? minDeliveryCharge;

  /// `admin`, `vendor`, `coupon` or null.
  final String? freeDeliveryBy;

  /// The actual saving, recomputed server-side — never the notional percentage.
  final double? proCustomerSavings;

  /// The matched coverage vehicle. **Dispatch only** — it carries no money.
  final int? vehicleId;

  const CheckoutSummaryDelivery({this.deliveryCharge, this.deliveryChargeBeforeProDiscount, this.originalDeliveryCharge,
    this.baseDeliveryCharge, this.surgeAmount, this.minDeliveryCharge, this.freeDeliveryBy, this.proCustomerSavings,
    this.vehicleId,
  });

  factory CheckoutSummaryDelivery.fromJson(Map<String, dynamic> json) => CheckoutSummaryDelivery(
    deliveryCharge: JsonReader.toDouble(json['delivery_charge']),
    deliveryChargeBeforeProDiscount: JsonReader.toDouble(json['delivery_charge_before_pro_discount']),
    originalDeliveryCharge: JsonReader.toDouble(json['original_delivery_charge']),
    baseDeliveryCharge: JsonReader.toDouble(json['base_delivery_charge']),
    surgeAmount: JsonReader.toDouble(json['surge_amount']),
    minDeliveryCharge: JsonReader.toDouble(json['min_delivery_charge']),
    freeDeliveryBy: JsonReader.toStr(json['free_delivery_by']),
    proCustomerSavings: JsonReader.toDouble(json['pro_customer_savings']),
    vehicleId: JsonReader.toInt(json['vehicle_id']),
  );

  bool get isFreeDelivery => (freeDeliveryBy != null && freeDeliveryBy!.isNotEmpty) || (deliveryCharge ?? 0) == 0;
}

/// What the membership was worth **on this basket** — the part
/// `pro-customer/active-offer` cannot know, because it describes the
/// entitlement rather than its effect here.
///
/// Only one of [discount] and [deliverySavings] can ever be non-zero (the admin
/// enables a single benefit), but a checkout should not have to know which.
class CheckoutSummaryPro {
  final bool status;
  final String? type;
  final double? discount;
  final double? deliverySavings;
  final double? totalSavings;

  const CheckoutSummaryPro({this.status = false, this.type, this.discount, this.deliverySavings, this.totalSavings});

  factory CheckoutSummaryPro.fromJson(Map<String, dynamic> json) => CheckoutSummaryPro(
    status: json['status'] == true || json['status'] == 1,
    type: JsonReader.toStr(json['type']),
    discount: JsonReader.toDouble(json['discount']),
    deliverySavings: JsonReader.toDouble(json['delivery_savings']),
    totalSavings: JsonReader.toDouble(json['total_savings']),
  );
}

/// What the customer earns back by placing this order. [calculatedAmount] is the
/// figure to show; the rest describes the rule it came from.
class CheckoutSummaryCashback {
  final double? calculatedAmount;
  final double? cashbackAmount;
  final String? cashbackType;
  final double? minPurchase;
  final double? maxDiscount;
  final int? id;

  const CheckoutSummaryCashback({this.calculatedAmount, this.cashbackAmount, this.cashbackType, this.minPurchase,
    this.maxDiscount, this.id,
  });

  factory CheckoutSummaryCashback.fromJson(Map<String, dynamic> json) => CheckoutSummaryCashback(
    calculatedAmount: JsonReader.toDouble(json['calculated_amount']),
    cashbackAmount: JsonReader.toDouble(json['cashback_amount']),
    cashbackType: JsonReader.toStr(json['cashback_type']),
    minPurchase: JsonReader.toDouble(json['min_purchase']),
    maxDiscount: JsonReader.toDouble(json['max_discount']),
    id: JsonReader.toInt(json['id']),
  );
}
