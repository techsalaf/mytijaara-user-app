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
  final int? zoneId;
  final double? avgRating;
  final int? ratingCount;
  final bool? open;
  final double? distance;
  final int? deliveryTime;
  final String? deliveryTimeText;
  final bool? freeDelivery;
  final int? moduleId;
  final int? verifiedSeller;
  final bool? isRecommended;
  final int? ad;
  // Backend-pending (providers/distance will add these later). Rendered only
  // when present — no placeholders. `subTitle` is the card's bold title line.
  final String? subTitle;
  final double? basePrice;
  final double? discount;
  final String? discountType;
  // Store creation timestamp — drives the "New" badge on the verified card.
  final String? createdAt;

  ServiceProvider({this.id, this.name, this.slug, this.logoFullUrl, this.coverPhotoFullUrl,
    this.address, this.zoneId, this.avgRating, this.ratingCount, this.open, this.distance,
    this.deliveryTime, this.deliveryTimeText, this.freeDelivery, this.moduleId, this.verifiedSeller,
    this.isRecommended, this.ad, this.subTitle, this.basePrice, this.discount, this.discountType,
    this.createdAt,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) => ServiceProvider(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
    logoFullUrl: json['logo_full_url']?.toString(),
    coverPhotoFullUrl: json['cover_photo_full_url']?.toString(),
    address: json['address']?.toString(),
    zoneId: int.tryParse(json['zone_id']?.toString() ?? ''),
    avgRating: double.tryParse(json['avg_rating']?.toString() ?? ''),
    ratingCount: int.tryParse(json['rating_count']?.toString() ?? ''),
    open: json['open'] == 1 || json['open'] == true,
    distance: double.tryParse(json['distance']?.toString() ?? ''),
    deliveryTime: int.tryParse(json['delivery_time']?.toString() ?? ''),
    deliveryTimeText: json['delivery_time']?.toString(),
    freeDelivery: json['free_delivery'] == 1 || json['free_delivery'] == true,
    moduleId: int.tryParse(json['module_id']?.toString() ?? ''),
    verifiedSeller: int.tryParse(json['verified_seller']?.toString() ?? ''),
    isRecommended: json['is_recommended'] == 1 || json['is_recommended'] == true,
    ad: int.tryParse(json['ad']?.toString() ?? ''),
    subTitle: json['sub_title']?.toString() ?? json['tagline']?.toString(),
    basePrice: double.tryParse(json['base_price']?.toString() ?? ''),
    discount: double.tryParse(json['discount']?.toString() ?? ''),
    discountType: json['discount_type']?.toString(),
    createdAt: json['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo_full_url': logoFullUrl,
    'cover_photo_full_url': coverPhotoFullUrl,
    'address': address,
    'zone_id': zoneId,
    'avg_rating': avgRating,
    'rating_count': ratingCount,
    'open': open,
    'distance': distance,
    'delivery_time': deliveryTimeText,
    'free_delivery': freeDelivery,
    'module_id': moduleId,
    'verified_seller': verifiedSeller,
    'is_recommended': isRecommended,
    'ad': ad,
    'sub_title': subTitle,
    'base_price': basePrice,
    'discount': discount,
    'discount_type': discountType,
    'created_at': createdAt,
  };

  bool isNew() {
    if (createdAt == null) return false;
    try {
      final DateTime created = DateTime.parse(createdAt!).toLocal();
      final Duration diff = DateTime.now().difference(created);
      return diff.inDays >= 0 && diff.inDays <= 30;
    } catch (_) {
      return false;
    }
  }
}
