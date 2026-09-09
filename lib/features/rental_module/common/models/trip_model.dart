import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';

class TripModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<TripDetailsModel>? trips;

  TripModel({this.totalSize, this.limit, this.offset, this.trips});

  TripModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['trips'] != null) {
      trips = <TripDetailsModel>[];
      json['trips'].forEach((v) {
        trips!.add(TripDetailsModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (trips != null) {
      data['trips'] = trips!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
//
// class Trips {
//   int? id;
//   int? userId;
//   int? providerId;
//   int? zoneId;
//   int? moduleId;
//   int? cashBackId;
//   double? tripAmount;
//   double? discountOnTrip;
//   String? discountOnTripBy;
//   int? couponDiscountAmount;
//   String? couponDiscountBy;
//   String? couponCode;
//   String? tripStatus;
//   String? paymentStatus;
//   String? paymentMethod;
//   String? transactionReference;
//   double? taxAmount;
//   String? taxStatus;
//   int? taxPercentage;
//   String? tripType;
//   int? additionalCharge;
//   int? partiallyPaidAmount;
//   double? distance;
//   int? estimatedHours;
//   int? refBonusAmount;
//   String? canceledBy;
//   String? cancellationReason;
//   PickupLocation? pickupLocation;
//   PickupLocation? destinationLocation;
//   String? tripNote;
//   String? callback;
//   String? otp;
//   int? isGuest;
//   int? edited;
//   int? checked;
//   int? scheduled;
//   String? scheduleAt;
//   String? pending;
//   bool? confirmed;
//   bool? ongoing;
//   bool? completed;
//   bool? canceled;
//   bool? paymentFailed;
//   int? quantity;
//   String? estimatedTripEndTime;
//   String? createdAt;
//   String? updatedAt;
//   int? pickupZoneId;
//   String? attachment;
//   UserInfo? userInfo;
//   Provider? provider;
//
//   Trips(
//       {this.id,
//         this.userId,
//         this.providerId,
//         this.zoneId,
//         this.moduleId,
//         this.cashBackId,
//         this.tripAmount,
//         this.discountOnTrip,
//         this.discountOnTripBy,
//         this.couponDiscountAmount,
//         this.couponDiscountBy,
//         this.couponCode,
//         this.tripStatus,
//         this.paymentStatus,
//         this.paymentMethod,
//         this.transactionReference,
//         this.taxAmount,
//         this.taxStatus,
//         this.taxPercentage,
//         this.tripType,
//         this.additionalCharge,
//         this.partiallyPaidAmount,
//         this.distance,
//         this.estimatedHours,
//         this.refBonusAmount,
//         this.canceledBy,
//         this.cancellationReason,
//         this.pickupLocation,
//         this.destinationLocation,
//         this.tripNote,
//         this.callback,
//         this.otp,
//         this.isGuest,
//         this.edited,
//         this.checked,
//         this.scheduled,
//         this.scheduleAt,
//         this.pending,
//         this.confirmed,
//         this.ongoing,
//         this.completed,
//         this.canceled,
//         this.paymentFailed,
//         this.quantity,
//         this.estimatedTripEndTime,
//         this.createdAt,
//         this.updatedAt,
//         this.pickupZoneId,
//         this.attachment,
//         this.userInfo,
//         this.provider});
//
//   Trips.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     userId = json['user_id'];
//     providerId = json['provider_id'];
//     zoneId = json['zone_id'];
//     moduleId = json['module_id'];
//     cashBackId = json['cash_back_id'];
//     tripAmount = json['trip_amount'];
//     discountOnTrip = json['discount_on_trip'];
//     discountOnTripBy = json['discount_on_trip_by'];
//     couponDiscountAmount = json['coupon_discount_amount'];
//     couponDiscountBy = json['coupon_discount_by'];
//     couponCode = json['coupon_code'];
//     tripStatus = json['trip_status'];
//     paymentStatus = json['payment_status'];
//     paymentMethod = json['payment_method'];
//     transactionReference = json['transaction_reference'];
//     taxAmount = json['tax_amount'];
//     taxStatus = json['tax_status'];
//     taxPercentage = json['tax_percentage'];
//     tripType = json['trip_type'];
//     additionalCharge = json['additional_charge'];
//     partiallyPaidAmount = json['partially_paid_amount'];
//     distance = json['distance'];
//     estimatedHours = json['estimated_hours'];
//     refBonusAmount = json['ref_bonus_amount'];
//     canceledBy = json['canceled_by'];
//     cancellationReason = json['cancellation_reason'];
//     pickupLocation = json['pickup_location'] != null
//         ? new PickupLocation.fromJson(json['pickup_location'])
//         : null;
//     destinationLocation = json['destination_location'] != null
//         ? new PickupLocation.fromJson(json['destination_location'])
//         : null;
//     tripNote = json['trip_note'];
//     callback = json['callback'];
//     otp = json['otp'];
//     isGuest = json['is_guest'];
//     edited = json['edited'];
//     checked = json['checked'];
//     scheduled = json['scheduled'];
//     scheduleAt = json['schedule_at'];
//     pending = json['pending'];
//     confirmed = json['confirmed'];
//     ongoing = json['ongoing'];
//     completed = json['completed'];
//     canceled = json['canceled'];
//     paymentFailed = json['payment_failed'];
//     quantity = json['quantity'];
//     estimatedTripEndTime = json['estimated_trip_end_time'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     pickupZoneId = json['pickup_zone_id'];
//     attachment = json['attachment'];
//     userInfo = json['user_info'] != null
//         ? new UserInfo.fromJson(json['user_info'])
//         : null;
//     provider = json['provider'] != null
//         ? new Provider.fromJson(json['provider'])
//         : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['user_id'] = this.userId;
//     data['provider_id'] = this.providerId;
//     data['zone_id'] = this.zoneId;
//     data['module_id'] = this.moduleId;
//     data['cash_back_id'] = this.cashBackId;
//     data['trip_amount'] = this.tripAmount;
//     data['discount_on_trip'] = this.discountOnTrip;
//     data['discount_on_trip_by'] = this.discountOnTripBy;
//     data['coupon_discount_amount'] = this.couponDiscountAmount;
//     data['coupon_discount_by'] = this.couponDiscountBy;
//     data['coupon_code'] = this.couponCode;
//     data['trip_status'] = this.tripStatus;
//     data['payment_status'] = this.paymentStatus;
//     data['payment_method'] = this.paymentMethod;
//     data['transaction_reference'] = this.transactionReference;
//     data['tax_amount'] = this.taxAmount;
//     data['tax_status'] = this.taxStatus;
//     data['tax_percentage'] = this.taxPercentage;
//     data['trip_type'] = this.tripType;
//     data['additional_charge'] = this.additionalCharge;
//     data['partially_paid_amount'] = this.partiallyPaidAmount;
//     data['distance'] = this.distance;
//     data['estimated_hours'] = this.estimatedHours;
//     data['ref_bonus_amount'] = this.refBonusAmount;
//     data['canceled_by'] = this.canceledBy;
//     data['cancellation_reason'] = this.cancellationReason;
//     if (this.pickupLocation != null) {
//       data['pickup_location'] = this.pickupLocation!.toJson();
//     }
//     if (this.destinationLocation != null) {
//       data['destination_location'] = this.destinationLocation!.toJson();
//     }
//     data['trip_note'] = this.tripNote;
//     data['callback'] = this.callback;
//     data['otp'] = this.otp;
//     data['is_guest'] = this.isGuest;
//     data['edited'] = this.edited;
//     data['checked'] = this.checked;
//     data['scheduled'] = this.scheduled;
//     data['schedule_at'] = this.scheduleAt;
//     data['pending'] = this.pending;
//     data['confirmed'] = this.confirmed;
//     data['ongoing'] = this.ongoing;
//     data['completed'] = this.completed;
//     data['canceled'] = this.canceled;
//     data['payment_failed'] = this.paymentFailed;
//     data['quantity'] = this.quantity;
//     data['estimated_trip_end_time'] = this.estimatedTripEndTime;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['pickup_zone_id'] = this.pickupZoneId;
//     data['attachment'] = this.attachment;
//     if (this.userInfo != null) {
//       data['user_info'] = this.userInfo!.toJson();
//     }
//     if (this.provider != null) {
//       data['provider'] = this.provider!.toJson();
//     }
//     return data;
//   }
// }
//
// class PickupLocation {
//   String? lat;
//   String? lng;
//   String? locationName;
//
//   PickupLocation({this.lat, this.lng, this.locationName});
//
//   PickupLocation.fromJson(Map<String, dynamic> json) {
//     lat = json['lat'];
//     lng = json['lng'];
//     locationName = json['location_name'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['lat'] = this.lat;
//     data['lng'] = this.lng;
//     data['location_name'] = this.locationName;
//     return data;
//   }
// }
//
// class UserInfo {
//   String? contactPersonName;
//   String? contactPersonNumber;
//   String? contactPersonEmail;
//
//   UserInfo(
//       {this.contactPersonName,
//         this.contactPersonNumber,
//         this.contactPersonEmail});
//
//   UserInfo.fromJson(Map<String, dynamic> json) {
//     contactPersonName = json['contact_person_name'];
//     contactPersonNumber = json['contact_person_number'];
//     contactPersonEmail = json['contact_person_email'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['contact_person_name'] = this.contactPersonName;
//     data['contact_person_number'] = this.contactPersonNumber;
//     data['contact_person_email'] = this.contactPersonEmail;
//     return data;
//   }
// }
//
// class Provider {
//   int? id;
//   String? name;
//   String? logo;
//   String? coverPhoto;
//   String? phone;
//   bool? gstStatus;
//   String? gstCode;
//   String? logoFullUrl;
//   String? coverPhotoFullUrl;
//   String? metaImageFullUrl;
//   List<Translations>? translations;
//   List<Storage>? storage;
//
//   Provider(
//       {this.id,
//         this.name,
//         this.logo,
//         this.coverPhoto,
//         this.phone,
//         this.gstStatus,
//         this.gstCode,
//         this.logoFullUrl,
//         this.coverPhotoFullUrl,
//         this.metaImageFullUrl,
//         this.translations,
//         this.storage});
//
//   Provider.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     logo = json['logo'];
//     coverPhoto = json['cover_photo'];
//     phone = json['phone'];
//     gstStatus = json['gst_status'];
//     gstCode = json['gst_code'];
//     logoFullUrl = json['logo_full_url'];
//     coverPhotoFullUrl = json['cover_photo_full_url'];
//     metaImageFullUrl = json['meta_image_full_url'];
//     if (json['translations'] != null) {
//       translations = <Translations>[];
//       json['translations'].forEach((v) {
//         translations!.add(new Translations.fromJson(v));
//       });
//     }
//     if (json['storage'] != null) {
//       storage = <Storage>[];
//       json['storage'].forEach((v) {
//         storage!.add(new Storage.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['logo'] = this.logo;
//     data['cover_photo'] = this.coverPhoto;
//     data['phone'] = this.phone;
//     data['gst_status'] = this.gstStatus;
//     data['gst_code'] = this.gstCode;
//     data['logo_full_url'] = this.logoFullUrl;
//     data['cover_photo_full_url'] = this.coverPhotoFullUrl;
//     data['meta_image_full_url'] = this.metaImageFullUrl;
//     if (this.translations != null) {
//       data['translations'] = this.translations!.map((v) => v.toJson()).toList();
//     }
//     if (this.storage != null) {
//       data['storage'] = this.storage!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Translations {
//   int? id;
//   String? translationableType;
//   int? translationableId;
//   String? locale;
//   String? key;
//   String? value;
//   String? createdAt;
//   String? updatedAt;
//
//   Translations(
//       {this.id,
//         this.translationableType,
//         this.translationableId,
//         this.locale,
//         this.key,
//         this.value,
//         this.createdAt,
//         this.updatedAt});
//
//   Translations.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     translationableType = json['translationable_type'];
//     translationableId = json['translationable_id'];
//     locale = json['locale'];
//     key = json['key'];
//     value = json['value'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['translationable_type'] = this.translationableType;
//     data['translationable_id'] = this.translationableId;
//     data['locale'] = this.locale;
//     data['key'] = this.key;
//     data['value'] = this.value;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     return data;
//   }
// }
//
// class Storage {
//   int? id;
//   String? dataType;
//   String? dataId;
//   String? key;
//   String? value;
//   String? createdAt;
//   String? updatedAt;
//
//   Storage(
//       {this.id,
//         this.dataType,
//         this.dataId,
//         this.key,
//         this.value,
//         this.createdAt,
//         this.updatedAt});
//
//   Storage.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     dataType = json['data_type'];
//     dataId = json['data_id'];
//     key = json['key'];
//     value = json['value'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['data_type'] = this.dataType;
//     data['data_id'] = this.dataId;
//     data['key'] = this.key;
//     data['value'] = this.value;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     return data;
//   }
// }