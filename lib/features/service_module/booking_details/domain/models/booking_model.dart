import 'dart:convert';

import 'package:sixam_mart/features/service_module/booking_details/domain/models/booking_line_item_model.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';

class PaginatedBookingModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<BookingModel>? bookings;

  PaginatedBookingModel({this.totalSize, this.limit, this.offset, this.bookings});

  factory PaginatedBookingModel.fromJson(Map<String, dynamic> json) => PaginatedBookingModel(
    totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
    limit: int.tryParse(json['limit']?.toString() ?? ''),
    offset: int.tryParse(json['offset']?.toString() ?? ''),
    bookings: (json['bookings'] as List<dynamic>?)?.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'total_size': totalSize, 'limit': limit, 'offset': offset,
    'bookings': bookings?.map((e) => e.toJson()).toList(),
  };
}

class BookingModel {
  int? id;
  String? displayId;
  String? bookingType;
  String? multiBookingType;
  int? parentBookingId;
  bool? isRepeatParent;
  int? childBookingsCount;
  int? activeBookingId;
  String? activeDisplayId;
  String? activeBookingStatus;
  String? activeStatusLabel;
  String? activeScheduleAt;
  List<BookingModel>? repeatLog;
  bool? isCustom;
  String? bookingStatus;
  String? statusLabel;
  Map<String, String>? statusHistory;
  String? paymentStatus;
  String? paymentMethod;
  String? transactionReference;
  int? scheduled;
  String? scheduleAt;
  int? quantity;
  String? otp;
  String? bookingNote;
  String? cancellationReason;
  String? canceledBy;
  BookingServiceLocation? serviceLocation;
  BookingAmount? amount;
  double? bookingAmount;
  String? couponCode;
  bool? isReviewed;
  bool? canRebook;
  bool? isCampaign;
  String? currencySymbol;
  ServiceProvider? provider;
  BookingCustomer? customer;
  List<BookingServiceman>? servicemen;
  List<BookingLineItemModel>? details;
  List<BookingServiceItem>? services;
  // Present only for a `partial_payment` booking — [0] is the wallet slice,
  // [1] the remainder method (cash_after_service / digital_payment / ...).
  List<BookingPayment>? partialPayments;
  // Present when the booking was settled offline (also alongside `partial_payments`
  // when offline covers a partial remainder) — carries the provider's payment
  // instructions, what the customer submitted, and the verification status.
  BookingOfflinePayment? offlinePayment;
  int? detailsCount;
  String? createdAt;
  String? updatedAt;

  BookingModel({this.id, this.displayId, this.bookingType, this.multiBookingType, this.parentBookingId, this.isRepeatParent,
    this.childBookingsCount, this.activeBookingId, this.activeDisplayId, this.activeBookingStatus, this.activeStatusLabel,
    this.activeScheduleAt, this.repeatLog, this.isCustom, this.bookingStatus, this.statusLabel, this.statusHistory,
    this.paymentStatus, this.paymentMethod, this.transactionReference, this.scheduled, this.scheduleAt,
    this.quantity, this.otp, this.bookingNote, this.cancellationReason, this.canceledBy, this.serviceLocation,
    this.amount, this.bookingAmount, this.couponCode, this.isReviewed, this.canRebook, this.isCampaign, this.currencySymbol, this.provider,
    this.customer, this.details, this.services, this.detailsCount, this.createdAt, this.updatedAt,
    this.servicemen, this.partialPayments, this.offlinePayment,
  });

  List<String>? get serviceNames => services?.map((e) => e.name ?? '').toList();
  List<String> get serviceImageUrls => services?.map((e) => e.imageFullUrl ?? '').toList() ?? [];

  bool get isRepeatParentBooking => bookingType == 'repeat' && (isRepeatParent ?? false);
  bool get isRepeatChildBooking => bookingType == 'repeat' && !(isRepeatParent ?? false);
  // A repeat occurrence in the "next service" bucket — the soonest confirmed sub-booking.
  bool get isConfirmedOccurrence => (bookingStatus ?? '').toLowerCase() == 'confirmed';
  String? get effectiveStatusLabel => isRepeatParentBooking ? (activeStatusLabel ?? statusLabel) : statusLabel;
  String? get effectiveBookingStatus => isRepeatParentBooking ? (activeBookingStatus ?? bookingStatus) : bookingStatus;
  String? get effectiveScheduleAt => isRepeatParentBooking ? (activeScheduleAt ?? scheduleAt) : scheduleAt;
  String? get effectiveDisplayId => isRepeatParentBooking ? (activeDisplayId ?? displayId) : displayId;

  // Partial payment — wallet covers a slice, the rest is settled by a second
  // method. Both slices come back in `partial_payments` (wallet first).
  bool get isPartialPayment => paymentMethod == 'partial_payment' && (partialPayments?.length ?? 0) > 1;
  BookingPayment? get walletPayment => isPartialPayment ? partialPayments![0] : null;
  BookingPayment? get remainderPayment => isPartialPayment ? partialPayments![1] : null;

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    displayId: json['display_id']?.toString(),
    bookingType: json['booking_type']?.toString(),
    multiBookingType: json['multi_booking_type']?.toString(),
    parentBookingId: int.tryParse(json['parent_booking_id']?.toString() ?? ''),
    isRepeatParent: json['is_repeat_parent'] == 1 || json['is_repeat_parent'] == true,
    childBookingsCount: int.tryParse(json['child_bookings_count']?.toString() ?? ''),
    activeBookingId: int.tryParse(json['active_booking_id']?.toString() ?? ''),
    activeDisplayId: json['active_display_id']?.toString(),
    activeBookingStatus: json['active_booking_status']?.toString(),
    activeStatusLabel: json['active_status_label']?.toString(),
    activeScheduleAt: json['active_schedule_at']?.toString(),
    repeatLog: (json['repeat_log'] as List<dynamic>?)?.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList(),
    isCustom: json['is_custom'] == 1 || json['is_custom'] == true,
    bookingStatus: json['booking_status']?.toString(),
    statusLabel: json['status_label']?.toString(),
    statusHistory: (json['status_history'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value.toString())),
    paymentStatus: json['payment_status']?.toString(),
    paymentMethod: json['payment_method']?.toString(),
    transactionReference: json['transaction_reference']?.toString(),
    scheduled: int.tryParse(json['scheduled']?.toString() ?? ''),
    scheduleAt: json['schedule_at']?.toString(),
    quantity: int.tryParse(json['quantity']?.toString() ?? ''),
    otp: json['otp']?.toString(),
    bookingNote: json['booking_note']?.toString(),
    cancellationReason: json['cancellation_reason']?.toString(),
    canceledBy: json['canceled_by']?.toString(),
    serviceLocation: json['service_location'] != null ? BookingServiceLocation.fromJson(json['service_location'] as Map<String, dynamic>) : null,
    amount: json['amount'] != null ? BookingAmount.fromJson(json['amount'] as Map<String, dynamic>) : null,
    bookingAmount: double.tryParse(json['booking_amount']?.toString() ?? ''),
    couponCode: json['coupon_code']?.toString(),
    isReviewed: json['is_reviewed'] == 1 || json['is_reviewed'] == true,
    canRebook: json['can_rebook'] == 1 || json['can_rebook'] == true,
    isCampaign: json['is_campaign'] == 1 || json['is_campaign'] == true,
    currencySymbol: json['currency_symbol']?.toString(),
    provider: json['provider'] != null ? ServiceProvider.fromJson(json['provider'] as Map<String, dynamic>) : null,
    customer: json['customer'] != null ? BookingCustomer.fromJson(json['customer'] as Map<String, dynamic>) : null,
    servicemen: (json['servicemen'] as List<dynamic>?)?.map((e) => BookingServiceman.fromJson(e as Map<String, dynamic>)).toList(),
    details: (json['details'] as List<dynamic>?)?.map((e) => BookingLineItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    services: (json['services'] as List<dynamic>?)?.map((e) => BookingServiceItem.fromJson(e as Map<String, dynamic>)).toList(),
    partialPayments: (json['partial_payments'] as List<dynamic>?)?.map((e) => BookingPayment.fromJson(e as Map<String, dynamic>)).toList(),
    offlinePayment: json['offline_payment'] != null ? BookingOfflinePayment.fromJson(json['offline_payment'] as Map<String, dynamic>) : null,
    detailsCount: int.tryParse(json['details_count']?.toString() ?? ''),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'display_id': displayId,
    'booking_type': bookingType,
    'multi_booking_type': multiBookingType,
    'parent_booking_id': parentBookingId,
    'is_repeat_parent': isRepeatParent,
    'child_bookings_count': childBookingsCount,
    'active_booking_id': activeBookingId,
    'active_display_id': activeDisplayId,
    'active_booking_status': activeBookingStatus,
    'active_status_label': activeStatusLabel,
    'active_schedule_at': activeScheduleAt,
    'repeat_log': repeatLog?.map((e) => e.toJson()).toList(),
    'is_custom': isCustom,
    'booking_status': bookingStatus,
    'status_label': statusLabel,
    'status_history': statusHistory,
    'payment_status': paymentStatus,
    'payment_method': paymentMethod,
    'transaction_reference': transactionReference,
    'scheduled': scheduled,
    'schedule_at': scheduleAt,
    'quantity': quantity,
    'otp': otp,
    'booking_note': bookingNote,
    'cancellation_reason': cancellationReason,
    'canceled_by': canceledBy,
    'service_location': serviceLocation?.toJson(),
    'amount': amount?.toJson(),
    'booking_amount': bookingAmount,
    'coupon_code': couponCode,
    'is_reviewed': isReviewed,
    'currency_symbol': currencySymbol,
    'provider': provider?.toJson(),
    'customer': customer?.toJson(),
    'servicemen': servicemen?.map((e) => e.toJson()).toList(),
    'details': details?.map((e) => e.toJson()).toList(),
    'can_rebook': canRebook,
    'services': services?.map((e) => e.toJson()).toList(),
    'partial_payments': partialPayments?.map((e) => e.toJson()).toList(),
    'offline_payment': offlinePayment?.toJson(),
    'details_count': detailsCount,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class BookingAmount {
  double? bookingAmount;
  double? discountAmount;
  double? couponDiscountAmount;
  double? proDiscount;
  double? refBonusAmount;
  double? taxAmount;
  String? taxStatus;
  double? additionalCharge;
  double? partiallyPaidAmount;

  BookingAmount({this.bookingAmount, this.discountAmount, this.couponDiscountAmount, this.proDiscount,
    this.refBonusAmount, this.taxAmount, this.taxStatus, this.additionalCharge, this.partiallyPaidAmount,
  });

  factory BookingAmount.fromJson(Map<String, dynamic> json) => BookingAmount(
    bookingAmount: double.tryParse(json['booking_amount']?.toString() ?? ''),
    discountAmount: double.tryParse(json['discount_amount']?.toString() ?? ''),
    couponDiscountAmount: double.tryParse(json['coupon_discount_amount']?.toString() ?? ''),
    proDiscount: double.tryParse(json['pro_discount']?.toString() ?? ''),
    refBonusAmount: double.tryParse(json['ref_bonus_amount']?.toString() ?? ''),
    taxAmount: double.tryParse(json['tax_amount']?.toString() ?? ''),
    taxStatus: json['tax_status']?.toString(),
    additionalCharge: double.tryParse(json['additional_charge']?.toString() ?? ''),
    partiallyPaidAmount: double.tryParse(json['partially_paid_amount']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'booking_amount': bookingAmount, 'discount_amount': discountAmount, 'coupon_discount_amount': couponDiscountAmount,
    'pro_discount': proDiscount, 'ref_bonus_amount': refBonusAmount, 'tax_amount': taxAmount, 'tax_status': taxStatus,
    'additional_charge': additionalCharge, 'partially_paid_amount': partiallyPaidAmount,
  };
}

class BookingServiceLocation {
  String? getServiceAt;
  String? address;
  double? lat;
  double? lng;

  BookingServiceLocation({this.getServiceAt, this.address, this.lat, this.lng});

  factory BookingServiceLocation.fromJson(Map<String, dynamic> json) => BookingServiceLocation(
    getServiceAt: json['get_service_at']?.toString(),
    address: json['address']?.toString(),
    lat: double.tryParse(json['lat']?.toString() ?? ''),
    lng: double.tryParse(json['lng']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {'get_service_at': getServiceAt, 'address': address, 'lat': lat, 'lng': lng};
}

class BookingServiceman {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? imageFullUrl;

  BookingServiceman({this.id, this.name, this.phone, this.email, this.imageFullUrl});

  factory BookingServiceman.fromJson(Map<String, dynamic> json) => BookingServiceman(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    phone: json['phone']?.toString(),
    email: json['email']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'email': email, 'image_full_url': imageFullUrl,
  };
}

class BookingServiceItem {
  String? name;
  String? imageFullUrl;

  BookingServiceItem({this.name, this.imageFullUrl});

  factory BookingServiceItem.fromJson(Map<String, dynamic> json) => BookingServiceItem(
    name: json['name']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {'name': name, 'image_full_url': imageFullUrl};
}

class BookingCustomer {
  int? id;
  bool? isGuest;
  String? name;
  String? phone;
  String? email;
  String? imageFullUrl;

  BookingCustomer({this.id, this.isGuest, this.name, this.phone, this.email, this.imageFullUrl});

  factory BookingCustomer.fromJson(Map<String, dynamic> json) => BookingCustomer(
    id: int.tryParse(json['id']?.toString() ?? ''),
    isGuest: json['is_guest'] == 1 || json['is_guest'] == true,
    name: json['name']?.toString(),
    phone: json['phone']?.toString(),
    email: json['email']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'is_guest': isGuest, 'name': name, 'phone': phone, 'email': email, 'image_full_url': imageFullUrl,
  };
}

class BookingPayment {
  int? id;
  int? bookingId;
  double? amount;
  String? paymentStatus;
  String? paymentMethod;
  String? createdAt;
  String? updatedAt;

  BookingPayment({this.id, this.bookingId, this.amount, this.paymentStatus, this.paymentMethod, this.createdAt, this.updatedAt});

  factory BookingPayment.fromJson(Map<String, dynamic> json) => BookingPayment(
    id: int.tryParse(json['id']?.toString() ?? ''),
    bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
    amount: double.tryParse(json['amount']?.toString() ?? ''),
    paymentStatus: json['payment_status']?.toString(),
    paymentMethod: json['payment_method']?.toString(),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'booking_id': bookingId, 'amount': amount, 'payment_status': paymentStatus,
    'payment_method': paymentMethod, 'created_at': createdAt, 'updated_at': updatedAt,
  };
}

/// The offline-payment submission attached to a booking paid (or partially paid)
/// offline. Shaped differently from the core order module's `OfflinePayment`: the
/// customer's entries arrive as a flat `payment_info` map, the verification state
/// is a top-level `status`, and `method_fields` (the provider's bank details) comes
/// back as a JSON-encoded *string* rather than an array.
class BookingOfflinePayment {
  int? id;
  int? bookingId;
  Map<String, String>? paymentInfo;
  String? status;
  String? note;
  String? customerNote;
  List<BookingOfflineMethodField>? methodFields;
  String? createdAt;
  String? updatedAt;

  BookingOfflinePayment({this.id, this.bookingId, this.paymentInfo, this.status, this.note,
    this.customerNote, this.methodFields, this.createdAt, this.updatedAt,
  });

  /// The offline method the customer paid through, e.g. "Bank".
  String? get methodName => paymentInfo?['method_name'];

  /// What the customer actually typed — `payment_info` minus the method metadata,
  /// which is identity, not an input worth showing back to them.
  Map<String, String> get customerInputs => Map<String, String>.fromEntries(
    (paymentInfo ?? const <String, String>{}).entries.where((MapEntry<String, String> e) => e.key != 'method_id' && e.key != 'method_name'),
  );

  bool get isDenied => status == 'denied';
  bool get isVerified => status == 'verified';
  bool get isPending => !isDenied && !isVerified;

  /// `method_fields` is normally a JSON string, but tolerate a decoded list too —
  /// and never let a malformed value take down the whole booking-details parse.
  static List<BookingOfflineMethodField> _parseMethodFields(dynamic raw) {
    try {
      final dynamic decoded = raw is String ? (raw.isEmpty ? null : jsonDecode(raw)) : raw;
      if (decoded is! List) return <BookingOfflineMethodField>[];
      return decoded.whereType<Map<String, dynamic>>().map(BookingOfflineMethodField.fromJson).toList();
    } catch (_) {
      return <BookingOfflineMethodField>[];
    }
  }

  factory BookingOfflinePayment.fromJson(Map<String, dynamic> json) => BookingOfflinePayment(
    id: int.tryParse(json['id']?.toString() ?? ''),
    bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
    paymentInfo: (json['payment_info'] as Map<String, dynamic>?)?.map((String key, dynamic value) => MapEntry(key, value?.toString() ?? '')),
    status: json['status']?.toString(),
    note: json['note']?.toString(),
    customerNote: json['customer_note']?.toString(),
    methodFields: _parseMethodFields(json['method_fields']),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'booking_id': bookingId, 'payment_info': paymentInfo, 'status': status,
    'note': note, 'customer_note': customerNote,
    'method_fields': methodFields?.map((BookingOfflineMethodField e) => e.toJson()).toList(),
    'created_at': createdAt, 'updated_at': updatedAt,
  };
}

/// One row of the provider's payment instructions (bank name, account number, …).
class BookingOfflineMethodField {
  String? inputName;
  String? inputData;

  BookingOfflineMethodField({this.inputName, this.inputData});

  factory BookingOfflineMethodField.fromJson(Map<String, dynamic> json) => BookingOfflineMethodField(
    inputName: json['input_name']?.toString(),
    inputData: json['input_data']?.toString(),
  );

  Map<String, dynamic> toJson() => {'input_name': inputName, 'input_data': inputData};
}
