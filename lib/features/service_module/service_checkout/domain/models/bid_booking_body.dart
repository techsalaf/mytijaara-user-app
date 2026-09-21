import 'package:sixam_mart/features/service_module/service_checkout/domain/models/service_booking_body.dart';

/// Service Module — request payload for `POST service/booking/place` (custom
/// request / accepted-bid flow). Mirrors [ServiceBookingBody] minus the cart
/// concerns (coupon, repeat schedules) and carries the approved offer as
/// `selected_bid_id`; the backend derives the provider and prices the booking
/// from the bid's offer price, not a cart.
///
/// Bid bookings are logged-in customers only (guests are rejected `403`), so
/// there are no guest fields — the Bearer token identifies the customer.
/// `moduleId` and `zoneId` headers are injected automatically while the
/// service module is active — they are not part of this body.
class BidBookingBody {
  final int selectedBidId;
  final ServiceLocation serviceLocation;
  final int scheduled; // 0 = instant, 1 = scheduled
  final String? scheduleAt; // 'yyyy-MM-dd HH:mm:ss'
  final String bookingType; // always 'regular' — bid bookings are single visits
  final String? bookingNote;
  final String? description;

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

  BidBookingBody({
    required this.selectedBidId, required this.serviceLocation, required this.scheduled, this.scheduleAt, this.bookingType = 'regular',
    this.bookingNote, this.description, this.paymentMethod, this.partialPaymentMethod, this.bringChangeAmount, this.methodId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['selected_bid_id'] = selectedBidId;
    data['service_location'] = serviceLocation.toJson();
    data['scheduled'] = scheduled;
    data['booking_type'] = bookingType;
    if (scheduleAt != null && scheduleAt!.isNotEmpty) data['schedule_at'] = scheduleAt;
    if (bookingNote != null && bookingNote!.isNotEmpty) data['booking_note'] = bookingNote;
    if (description != null && description!.isNotEmpty) data['description'] = description;

    if (paymentMethod != null && paymentMethod!.isNotEmpty) data['payment_method'] = paymentMethod;
    if (partialPaymentMethod != null && partialPaymentMethod!.isNotEmpty) data['partial_payment_method'] = partialPaymentMethod;
    if (bringChangeAmount != null) data['bring_change_amount'] = bringChangeAmount.toString();
    if (methodId != null) data['method_id'] = methodId;
    return data;
  }
}
