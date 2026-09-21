import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart' hide Store;
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';

/// Service Module — provider (the module's "store"), standard store shape from
/// `Helpers::store_data_formatting()`. Embedded in the service-details response
/// and returned by the provider endpoints.
class ServiceProvider {
  final int? id;
  final String? name;
  final String? slug;
  final String? logoFullUrl;
  final String? coverPhotoFullUrl;
  final String? address;
  final String? phone;
  final String? latitude;
  final String? longitude;
  final int? zoneId;
  final double? avgRating;
  final int? ratingCount;
  final double? distance;
  final List<Schedules>? schedules;
  final int? open;
  final bool? active;
  // Distance from the user in km — service endpoints (e.g. category-providers)
  // send this as `distance_km` rather than the standard `distance` field.
  final double? distanceKm;
  final int? deliveryTime;
  final String? deliveryTimeText;
  final bool? freeDelivery;
  final int? moduleId;
  final int? verifiedSeller;
  final bool? isRecommended;
  final int? ad;
  final bool? announcementActive;
  final String? announcementMessage;
  // Backend-pending (providers/distance will add these later). Rendered only
  // when present — no placeholders. `subTitle` is the card's bold title line.
  final String? subTitle;
  final double? basePrice;
  final double? discount;
  final String? discountType;
  // Full discount rule (min purchase, max discount, valid date/time range) —
  // parsed from the `discount` object the store-details endpoint returns.
  final Discount? discountDetails;
  // Store creation timestamp — drives the "New" badge on the verified card.
  final String? createdAt;
  // Total completed orders — drives the "Service Provided" stat and gates the
  // "Most Popular" section (hidden when 0).
  final int? orderCount;
  // Store-scoped coupons returned with the store-details response.
  final List<CouponModel>? coupons;
  // Per-provider booking capability flags (from `/stores/details`). These are the
  // single source of truth for which booking modes the checkout offers.
  final bool instantBooking;
  final bool repeatBooking;
  final bool scheduleBooking;

  ServiceProvider({this.id, this.name, this.slug, this.logoFullUrl, this.coverPhotoFullUrl,
    this.address, this.phone, this.latitude, this.longitude,
    this.zoneId, this.avgRating, this.ratingCount, this.open, this.active, this.distance, this.schedules,
    this.deliveryTime, this.deliveryTimeText, this.freeDelivery, this.moduleId, this.verifiedSeller,
    this.isRecommended, this.ad, this.distanceKm, this.announcementActive, this.announcementMessage, this.subTitle,
    this.basePrice, this.discount, this.discountType,
    this.discountDetails, this.createdAt, this.orderCount, this.coupons, this.instantBooking = false,
    this.repeatBooking = false, this.scheduleBooking = false,
  });

  factory ServiceProvider.fromStore(Store store) => ServiceProvider(
    id: store.id,
    name: store.name,
    slug: store.slug,
    logoFullUrl: store.logoFullUrl,
    coverPhotoFullUrl: store.coverPhotoFullUrl,
    address: store.address,
    phone: store.phone,
    latitude: store.latitude,
    longitude: store.longitude,
    zoneId: store.zoneId,
    avgRating: store.avgRating,
    ratingCount: store.ratingCount,
    open: store.open,
    schedules: store.schedules,
    active: store.active,
    distance: store.distance,
    deliveryTimeText: store.deliveryTime,
    freeDelivery: store.freeDelivery,
    moduleId: store.moduleId,
    verifiedSeller: store.verifiedSeller,
    discount: store.discount?.discount,
    discountType: store.discount?.discountType,
    discountDetails: store.discount,
    announcementActive: store.announcementActive,
    announcementMessage: store.announcementMessage,
  );

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    // The `discount` key is a rule object (min purchase, max discount, valid
    // date/time range) — not a bare number — on the store-details response.
    final Discount? discountDetails = json['discount'] is Map<String, dynamic>
        ? Discount.fromJson(json['discount'] as Map<String, dynamic>)
        : null;

    return ServiceProvider(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
      logoFullUrl: json['logo_full_url']?.toString(),
      coverPhotoFullUrl: json['cover_photo_full_url']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      zoneId: int.tryParse(json['zone_id']?.toString() ?? ''),
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? ''),
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? ''),
      open: json['open'] == 1 || json['open'] == true ? 1 : 0,
      active: json['active'] == 1 || json['active'] == true,
      schedules: json['schedules'] is List
          ? (json['schedules'] as List).map((e) => Schedules.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      distance: double.tryParse(json['distance']?.toString() ?? ''),
      deliveryTime: int.tryParse(json['delivery_time']?.toString() ?? ''),
      deliveryTimeText: json['delivery_time']?.toString(),
      freeDelivery: json['free_delivery'] == 1 || json['free_delivery'] == true,
      moduleId: int.tryParse(json['module_id']?.toString() ?? ''),
      verifiedSeller: int.tryParse(json['verified_seller']?.toString() ?? ''),
      isRecommended: json['is_recommended'] == 1 || json['is_recommended'] == true,
      ad: int.tryParse(json['ad']?.toString() ?? ''),
      announcementActive: json['announcement'] == 1 || json['announcement'] == true,
      announcementMessage: json['announcement_message']?.toString(),
      subTitle: json['sub_title']?.toString() ?? json['tagline']?.toString(),
      basePrice: double.tryParse(json['base_price']?.toString() ?? ''),
      discount: discountDetails?.discount ?? double.tryParse(json['discount']?.toString() ?? ''),
      discountType: discountDetails?.discountType ?? json['discount_type']?.toString(),
      discountDetails: discountDetails,
      createdAt: json['created_at']?.toString(),
      orderCount: int.tryParse(json['order_count']?.toString() ?? ''),
      coupons: json['coupons'] is List
          ? (json['coupons'] as List).map((e) => CouponModel.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      instantBooking: json['instant_booking'] == 1 || json['instant_booking'] == true,
      repeatBooking: json['repeat_booking'] == 1 || json['repeat_booking'] == true,
      scheduleBooking: json['schedule_booking'] == 1 || json['schedule_booking'] == true,
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo_full_url': logoFullUrl,
    'cover_photo_full_url': coverPhotoFullUrl,
    'address': address,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
    'zone_id': zoneId,
    'avg_rating': avgRating,
    'rating_count': ratingCount,
    'open': open,
    'active': active,
    'schedules': schedules?.map((s) => s.toJson()).toList(),
    'distance': distance,
    'distance_km': distanceKm,
    'delivery_time': deliveryTimeText,
    'free_delivery': freeDelivery,
    'module_id': moduleId,
    'verified_seller': verifiedSeller,
    'is_recommended': isRecommended,
    'ad': ad,
    'announcement': announcementActive,
    'announcement_message': announcementMessage,
    'sub_title': subTitle,
    'base_price': basePrice,
    'discount': discountDetails?.toJson() ?? discount,
    'discount_type': discountType,
    'created_at': createdAt,
    'order_count': orderCount,
    'instant_booking': instantBooking,
    'repeat_booking': repeatBooking,
    'schedule_booking': scheduleBooking,
  };

  // True when the store was created within the last 30 days (drives "New" badge).
  bool isNew() => DateConverter.isWithinDays(createdAt, 5);
}
