import 'dart:convert';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';

/// Request body for `POST customer/order/checkout-summary`.
///
/// Placement's inputs, minus everything placement needs only in order to *write*
/// an order. Kept as its own model rather than reusing `PlaceOrderBodyModel`
/// because the quote takes a strict subset, and sending the write-only fields
/// (cart rows, payment method, prescription flags) would imply they affect the
/// numbers.
///
/// When a pick is posted here it **must** be posted to `place_order` too — the
/// fee moves with it, and posting it to only one of the two is how the quote and
/// the charge come apart.
class CheckoutSummaryBodyModel {
  /// `take_away`, `delivery` or `parcel`.
  final String orderType;

  /// Required unless [orderType] is `parcel`.
  final int? storeId;

  /// The basket the cashback is measured against.
  final double orderAmount;

  /// **Kilometres, always.** The `distance_unit` business setting decides the
  /// unit the *rates* are quoted in, never how this value is read. Omitted for
  /// `take_away`.
  final double? distance;
  final String? latitude;
  final String? longitude;
  final int? parcelCategoryId;

  /// The weight band and size class picked, when this `(zone, module)` prices by
  /// them. Optional on purpose — a zone charging a flat parcel fee offers nothing
  /// to pick, so requiring them would refuse every order there.
  ///
  /// An id posted at a switched-off tier costs nothing: the engine re-checks the
  /// same switches the list endpoints check, so a client holding an id fetched
  /// before an admin disabled the tier cannot charge the customer for it.
  final int? weightId;
  final int? dimensionId;

  /// **Required when [orderType] is `parcel`.** The quote reads the receiver's
  /// zone out of this, and its absence answers 500 rather than naming what was
  /// missing.
  final AddressModel? receiverDetails;

  /// A free-delivery coupon pre-sets the charge here exactly as at placement.
  final String? couponCode;

  /// A scheduled order is surged for the slot it will be delivered in.
  final String? scheduleAt;

  /// Validated against the store's zone, but never required by the quote.
  final int? areaId;
  final int? zipCodeId;

  // Sent even when it is `standard`, so switching back off a tier requotes and drops its charge.
  final String? deliveryType;

  /// Required when not logged in.
  final String? guestId;

  const CheckoutSummaryBodyModel({required this.orderType, required this.orderAmount, this.storeId, this.distance,
    this.latitude, this.longitude, this.parcelCategoryId, this.weightId, this.dimensionId, this.receiverDetails,
    this.couponCode, this.scheduleAt, this.areaId, this.zipCodeId, this.deliveryType, this.guestId,
  });

  /// Only keys with a value are sent — the endpoint validates presence, so an
  /// explicit null would fail validation where an absent key passes.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'order_type': orderType,
      'order_amount': orderAmount,
    };
    if (storeId != null) data['store_id'] = storeId;
    if (distance != null) data['distance'] = distance;
    if (latitude != null && latitude!.isNotEmpty) data['latitude'] = latitude;
    if (longitude != null && longitude!.isNotEmpty) data['longitude'] = longitude;
    if (parcelCategoryId != null) data['parcel_category_id'] = parcelCategoryId;
    if (weightId != null) data['weight_id'] = weightId;
    if (dimensionId != null) data['dimension_id'] = dimensionId;
    // Encoded as a JSON string, exactly as `place_order` sends it — both are read
    // by the same parser, and the quote must be priced off the identical payload.
    if (receiverDetails != null) data['receiver_details'] = jsonEncode(receiverDetails!.toJson());
    if (couponCode != null && couponCode!.isNotEmpty) data['coupon_code'] = couponCode;
    if (scheduleAt != null && scheduleAt!.isNotEmpty) data['schedule_at'] = scheduleAt;
    if (areaId != null) data['area_id'] = areaId;
    if (zipCodeId != null) data['zip_code_id'] = zipCodeId;
    if (deliveryType != null && deliveryType!.isNotEmpty) data['delivery_type'] = deliveryType;
    if (guestId != null && guestId!.isNotEmpty && guestId != '0') data['guest_id'] = guestId;
    return data;
  }

  /// The same basket with a different coverage pick.
  ///
  /// Both ids are replaced rather than merged, because only one of them can be
  /// set at a time — passing the new pick and leaving the old one behind would
  /// post `area_id` and `zip_code_id` together.
  CheckoutSummaryBodyModel copyWithCoverage({int? areaId, int? zipCodeId}) => CheckoutSummaryBodyModel(
    orderType: orderType, orderAmount: orderAmount, storeId: storeId, distance: distance,
    latitude: latitude, longitude: longitude, parcelCategoryId: parcelCategoryId, weightId: weightId,
    dimensionId: dimensionId, receiverDetails: receiverDetails, couponCode: couponCode,
    scheduleAt: scheduleAt, areaId: areaId, zipCodeId: zipCodeId, deliveryType: deliveryType, guestId: guestId,
  );

  /// The same basket with a different weight band or size class.
  ///
  /// Unlike the coverage pair these are independent — a rule may price by weight
  /// and not by size — so an omitted argument keeps its current value instead of
  /// clearing the other one.
  CheckoutSummaryBodyModel copyWithTiers({int? weightId, int? dimensionId}) => CheckoutSummaryBodyModel(
    orderType: orderType, orderAmount: orderAmount, storeId: storeId, distance: distance,
    latitude: latitude, longitude: longitude, parcelCategoryId: parcelCategoryId,
    weightId: weightId ?? this.weightId, dimensionId: dimensionId ?? this.dimensionId,
    receiverDetails: receiverDetails, couponCode: couponCode,
    scheduleAt: scheduleAt, areaId: areaId, zipCodeId: zipCodeId, deliveryType: deliveryType, guestId: guestId,
  );

  /// Identity of the inputs that change the numbers, used to skip refetching a
  /// quote for a basket that has not moved.
  String get signature => toJson().entries
      .map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}')
      .toList()
      .join('&');
}

// SUMMARY
// Request body for the checkout quote. Carries the inputs that price an order — store,
// amount, distance, coordinates, coupon, schedule, parcel category and tiers, area or ZIP
// pick, saver delivery tier and guest id — sending only the keys that have a value, and
// exposes a signature of those keys so an unchanged basket is not requoted.
