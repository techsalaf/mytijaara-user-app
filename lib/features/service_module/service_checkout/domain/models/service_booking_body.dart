import 'package:sixam_mart/features/service_module/service_checkout/domain/models/service_buy_now_variant.dart';

/// Service Module — request payload for `POST service/booking/place` (normal /
/// cart flow). The custom-bid flow is intentionally not modelled here — see
/// [BidBookingBody] in bid_booking_body.dart.
///
/// Guests send `guest_id` + contact fields; logged-in customers rely on the
/// Bearer token (added automatically by ApiClient) and omit them. `moduleId`
/// and `zoneId` headers are also injected automatically while the service
/// module is active — they are not part of this body.
class ServiceBookingBody {
  final int providerId;
  final ServiceLocation serviceLocation;
  final int scheduled; // 0 = instant, 1 = scheduled
  final String? scheduleAt; // 'yyyy-MM-dd HH:mm:ss'
  final String bookingType; // 'regular' | 'repeat'
  final String? couponCode;
  final String? bookingNote;
  final String? description;

  // Guest-only (sent when there is no auth token).
  final String? guestId;
  final String? contactPersonName;
  final String? contactPersonNumber;
  final String? contactPersonEmail;

  // Guest create-account (sent alongside the guest block when the guest opts in
  // to create a real account from this booking). 1 = create, null = omitted.
  final int? createNewUser;
  final String? password;

  // Repeat-only — the expanded occurrences as 'yyyy-MM-dd HH:mm:ss' strings, one
  // per service visit. Serialized as a `dates` array of `{"date": ...}` objects.
  final List<String>? repeatSchedules;

  // Repeat-only — the recurrence sub-type ('daily' | 'weekly' | 'custom'). The
  // backend requires `multi_booking_type` whenever `booking_type` is `repeat`.
  final String? multiBookingType;

  // Payment — the selected method string ('cash_after_service' | 'wallet' |
  // 'digital_payment' | 'partial_payment' | 'offline_payment'). The booking is
  // created unpaid and then settled via the unified `booking/payment` endpoint.
  final String? paymentMethod;

  // Partial-payment only — the remainder method ('cash_after_service' |
  // 'digital_payment') covering whatever the wallet doesn't. Required by the
  // backend whenever paymentMethod is 'partial_payment'.
  final String? partialPaymentMethod;

  // Cash-after-service only — the "bring change for" amount the customer entered.
  final double? bringChangeAmount;

  // Offline-payment only — the id of the offline method (e.g. bank) chosen from
  // the offline_payment_method_list, resolved from the shared CheckoutController's
  // selection at the moment the booking is placed.
  final int? methodId;

  // Buy-now (cart-less) fields. When [buyNow] is 1 the backend resolves a single
  // line from [buyNowServiceId] instead of the server cart: [isCampaign] 1 means
  // it is a campaign id, 0 a plain service id. [price] / [variation] are optional
  // pass-throughs; [providerId] is still sent but ignored (derived server-side).
  final int? buyNow; // 1 = skip the cart
  final int? isCampaign; // 1 = service_id is a campaign id
  final int? buyNowServiceId;
  final int? quantity;
  final double? price; // single-line unit price, or the summed total when [variants] is set
  final String? variation;
  // Multi-variation buy-now — when non-empty, sent under the `variation` key as
  // an array of {variant_key, quantity}; [quantity]/[variation] are dropped and
  // [price] carries the summed total.
  final List<ServiceBuyNowVariant>? variants;

  ServiceBookingBody({
    required this.providerId, required this.serviceLocation, required this.scheduled, this.scheduleAt, this.bookingType = 'regular',
    this.couponCode, this.bookingNote, this.description, this.guestId, this.contactPersonName,
    this.contactPersonNumber, this.contactPersonEmail, this.createNewUser, this.password, this.repeatSchedules,
    this.multiBookingType, this.paymentMethod, this.partialPaymentMethod,
    this.bringChangeAmount, this.methodId, this.buyNow, this.isCampaign, this.buyNowServiceId, this.quantity, this.price,
    this.variation, this.variants,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['provider_id'] = providerId;
    data['service_location'] = serviceLocation.toJson();
    data['scheduled'] = scheduled;
    data['booking_type'] = bookingType;
    if (scheduleAt != null && scheduleAt!.isNotEmpty) data['schedule_at'] = scheduleAt;
    if (couponCode != null && couponCode!.isNotEmpty) data['coupon_code'] = couponCode;
    if (bookingNote != null && bookingNote!.isNotEmpty) data['booking_note'] = bookingNote;
    if (description != null && description!.isNotEmpty) data['description'] = description;

    if (paymentMethod != null && paymentMethod!.isNotEmpty) data['payment_method'] = paymentMethod;
    if (partialPaymentMethod != null && partialPaymentMethod!.isNotEmpty) data['partial_payment_method'] = partialPaymentMethod;
    if (bringChangeAmount != null) data['bring_change_amount'] = bringChangeAmount.toString();
    if (methodId != null) data['method_id'] = methodId;

    // Buy-now line resolution — emitted only for the cart-less flow. Provider is
    // derived server-side from the item, so provider_id above is ignored here.
    if (buyNow == 1) {
      data['buy_now'] = 1;
      data['is_campaign'] = isCampaign ?? 0;
      data['service_id'] = buyNowServiceId;
      // Multi-variation buy-now — `variation` is an array of {variant_key,
      // quantity} and `price` the summed total (no top-level quantity); the
      // single-line path keeps quantity/price/variation-name.
      if (variants != null && variants!.isNotEmpty) {
        if (price != null) data['price'] = price;
        data['variation'] = variants!.map((ServiceBuyNowVariant v) => v.toJson()).toList();
      } else {
        data['quantity'] = quantity ?? 1;
        if (price != null) data['price'] = price;
        if (variation != null && variation!.isNotEmpty) data['variation'] = variation;
      }
    }

    if (guestId != null && guestId!.isNotEmpty) {
      data['guest_id'] = guestId;
      data['contact_person_name'] = contactPersonName;
      data['contact_person_number'] = contactPersonNumber;
      data['contact_person_email'] = contactPersonEmail;
      if (createNewUser != null) data['create_new_user'] = createNewUser.toString();
      if (password != null && password!.isNotEmpty) data['password'] = password;
    }

    // Repeat recurrence — the expanded occurrences are sent under `dates` as an
    // array of `{"date": "yyyy-MM-dd HH:mm:ss"}` objects (mirrors the Demandium
    // repeat payload). ⚠️ Confirm the exact field name with the backend team —
    // this is the single integration point for the repeat schedule shape.
    if (bookingType == 'repeat' && repeatSchedules != null && repeatSchedules!.isNotEmpty) {
      data['dates'] = repeatSchedules!.map((String d) => <String, dynamic>{'date': d}).toList();
      // Required by the backend whenever booking_type is repeat.
      if (multiBookingType != null && multiBookingType!.isNotEmpty) data['multi_booking_type'] = multiBookingType;
    }
    return data;
  }
}

/// Where the service is delivered. Coordinates are validated against the
/// provider's zone by the backend, so both must be present.
class ServiceLocation {
  final String getServiceAt; // 'user' | 'provider'
  final String address;
  final double lat;
  final double lng;

  ServiceLocation({required this.getServiceAt, required this.address, required this.lat, required this.lng});

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'get_service_at': getServiceAt, 'address': address, 'lat': lat, 'lng': lng};
}
