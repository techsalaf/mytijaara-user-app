/// Service Module — response of `booking/place` and the non-gateway responses of
/// the unified `booking/payment` endpoint (wallet / cash_after_service):
/// `{ booking_id, payment_method, payment_status, partially_paid_amount }`.
class ServiceBookingResponseModel {
  final String? bookingId;
  final String? paymentMethod;
  final String? paymentStatus;
  final double partiallyPaidAmount;
  final String? token;

  ServiceBookingResponseModel({this.bookingId, this.paymentMethod, this.paymentStatus, this.partiallyPaidAmount = 0, this.token});

  factory ServiceBookingResponseModel.fromJson(Map<String, dynamic> json) {
    final dynamic id = json['booking_id'] ?? json['id'];
    return ServiceBookingResponseModel(
      bookingId: id?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      partiallyPaidAmount: double.tryParse(json['partially_paid_amount']?.toString() ?? '') ?? 0,
      token: json['token']?.toString(),
    );
  }
}

/// Service Module — gateway/offline response of `booking/payment`: a
/// `redirect_link` (digital / partial remainder) or a `message` (offline).
class ServicePaymentResponseModel {
  final String? redirectLink;
  final String? message;

  ServicePaymentResponseModel({this.redirectLink, this.message});

  factory ServicePaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return ServicePaymentResponseModel(
      redirectLink: json['redirect_link']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
