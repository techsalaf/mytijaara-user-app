import 'package:sixam_mart/api/json_reader.dart';

/// The body of `GET customer/order/payment-failed`.
///
/// The endpoint answers for two different kinds of purchase, and names the same
/// things differently in each:
///
/// | | mart order | rental trip |
/// |---|---|---|
/// | id | `order_id` | `trip_id` |
/// | amount | `order_amount` | `trip_amount` |
/// | kind | `order_type: "delivery"` | `type: "rental"` |
/// | `module_type` | `"food"`, `"grocery"`, … | `"rental"` |
///
/// [orderID] and [orderAmount] read whichever pair is present, so callers that
/// only need "what failed and for how much" are unaffected by the difference.
/// [moduleType] is what tells the two apart — see `CheckoutController.isTripPayment`,
/// which routes trips to the rental payment endpoint instead of the mart ones.
class PaymentModel {
  String? orderID;
  String? orderType;
  /// `rental` for a trip; the storefront module (`food`, `grocery`, …) otherwise.
  String? moduleType;
  double? orderAmount;
  double? maxCodOrderAmount;
  bool? isCashOnDeliveryActive;
  bool? isDigitalPaymentActive;
  bool? isOfflinePaymentActive;
  String? guestId;
  String? contactNumber;
  int? zoneId;
  double? partiallyPaidAmount;
  String? paymentStatus;
  String? paymentMethod;
  int? userId;

  PaymentModel({
    this.orderID,
    this.orderType,
    this.moduleType,
    this.orderAmount,
    this.maxCodOrderAmount,
    this.isCashOnDeliveryActive,
    this.isDigitalPaymentActive,
    this.isOfflinePaymentActive,
    this.guestId,
    this.contactNumber,
    this.zoneId,
    this.partiallyPaidAmount,
    this.paymentStatus,
    this.paymentMethod,
    this.userId,
});

  PaymentModel.fromJson(Map<String, dynamic> json)
      // A rental trip names these `trip_id` / `trip_amount`. Read `order_*` first
      // so a mart order is parsed exactly as before, and fall back rather than
      // branching — the two never both appear.
      : orderID = (json['order_id'] ?? json['trip_id'])?.toString(),
        orderType = json['order_type'] ?? json['type'],
        moduleType = json['module_type']?.toString(),
        orderAmount = JsonReader.toDouble(json['order_amount'] ?? json['trip_amount']) ?? 0,
        maxCodOrderAmount = JsonReader.toDouble(json['maximum_cod_order_amount']),
        isCashOnDeliveryActive = json['cash_on_delivery'],
        isDigitalPaymentActive = json['digital_payment'],
        isOfflinePaymentActive = json['offline_payment'],
        guestId = json['guest_id'],
        contactNumber = json['contact_person_number'] ?? '',
        // `?? ''` assigned a String to this `int?` field whenever `zone_id` was
        // absent, throwing a TypeError. The repository wraps this constructor in
        // a bare `catch`, so the model came back null and the payment-failed
        // screen rendered nothing at all — no error, just an empty flow.
        zoneId = JsonReader.toInt(json['zone_id']),
        partiallyPaidAmount = JsonReader.toDouble(json['partially_paid_amount']),
        paymentStatus = json['payment_status'],
        paymentMethod = json['payment_method'],
        userId = JsonReader.toInt(json['user_id']);

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderID,
      'order_type': orderType,
      'order_amount': orderAmount,
      'maximum_cod_order_amount': maxCodOrderAmount,
      'cash_on_delivery': isCashOnDeliveryActive,
      'digital_payment': isDigitalPaymentActive,
      'offline_payment': isOfflinePaymentActive,
      'guest_id': guestId,
      'contact_person_number': contactNumber,
      'zone_id': zoneId,
      'partially_paid_amount': partiallyPaidAmount,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'user_id': userId,
    };
  }
}