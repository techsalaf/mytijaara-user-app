import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_category_model.dart';
import 'package:sixam_mart/features/service_module/service_review/domain/models/service_review_model.dart';

/// Service Module — service list envelope `{ total_size, limit, offset,
/// services[] }`. Fields are mutable so a controller can append pages in-place
/// (see ServiceExploreController). The `/explore` endpoint adds `categories[]`
/// (the tab strip, with an "All" tab); other list endpoints leave it null.
class ServiceModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Service>? services;
  List<ServiceCategoryModel>? categories;

  ServiceModel({this.totalSize, this.limit, this.offset, this.services, this.categories});

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
    limit: int.tryParse(json['limit']?.toString() ?? ''),
    offset: int.tryParse(json['offset']?.toString() ?? ''),
    services: (json['services'] as List<dynamic>?)
        ?.map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList(),
    categories: (json['categories'] as List<dynamic>?)
        ?.map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'total_size': totalSize,
    'limit': limit,
    'offset': offset,
    'services': services?.map((e) => e.toJson()).toList(),
    'categories': categories?.map((e) => e.toJson()).toList(),
  };
}

class Service {
  final int? id;
  final String? name;
  final String? slug;
  final String? shortDescription;
  final String? longDescription;
  final String? thumbnailFullUrl;
  final List<String>? additionalImagesFullUrl;
  final double? basePrice;
  final double? minBidPrice;
  final double? discount;
  final String? discountType;
  final double? discountedPrice; // explore card headline price
  final List<ServiceVariation>? variations;
  final List<String>? tags;
  final int? recommended;
  final int? orderCount;
  final double? avgRating;
  final int? ratingCount;
  final int? moduleId;
  final int? storeId;
  final String? storeName;
  final String? providerImageFullUrl; // list endpoints — flat provider avatar
  final int? verifiedProvider;        // list endpoints — 0/1 verified flag
  // Distance from the user in km — list endpoints (e.g. service/recommended)
  // send this as `distance_km`. Null when the endpoint omits it.
  final double? distanceKm;
  final int? categoryId;
  final int? subCategoryId;
  final ServiceMiniCategory? category;
  final ServiceMiniCategory? subCategory;
  final ServiceProvider? provider; // populated only by the service-details endpoint
  final List<ServiceFaq>? faqs; // populated only by the service-details endpoint
  final String? deliveryTime; // from provider.delivery_time, e.g. "10-11 min"
  final int? totalReviews; // details endpoint — total approved reviews for this service
  final List<ServiceReview>? reviews; // details endpoint — last 3 reviews (preview)
  bool isFavourite;

  Service({this.id, this.name, this.slug, this.shortDescription, this.longDescription,
    this.thumbnailFullUrl, this.additionalImagesFullUrl, this.basePrice, this.minBidPrice, this.discount,
    this.discountType, this.discountedPrice, this.variations, this.tags, this.recommended,
    this.orderCount, this.avgRating, this.ratingCount, this.moduleId, this.storeId,
    this.storeName, this.providerImageFullUrl, this.verifiedProvider, this.distanceKm, this.categoryId, this.subCategoryId,
    this.category, this.subCategory, this.provider, this.faqs, this.deliveryTime,
    this.totalReviews, this.reviews, this.isFavourite = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
    shortDescription: json['short_description']?.toString(),
    longDescription: json['long_description']?.toString(),
    thumbnailFullUrl: json['thumbnail_full_url']?.toString(),
    additionalImagesFullUrl: (json['additional_images_full_url'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    basePrice: double.tryParse(json['base_price']?.toString() ?? ''),
    minBidPrice: double.tryParse(json['min_bid_price']?.toString() ?? ''),
    discount: double.tryParse(json['discount']?.toString() ?? ''),
    discountType: json['discount_type']?.toString(),
    discountedPrice: double.tryParse(json['discounted_price']?.toString() ?? ''),
    variations: (json['variations'] as List<dynamic>?)?.map((e) => ServiceVariation.fromJson(e as Map<String, dynamic>)).toList(),
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    recommended: int.tryParse(json['recommended']?.toString() ?? ''),
    orderCount: int.tryParse(json['order_count']?.toString() ?? ''),
    avgRating: double.tryParse(json['avg_rating']?.toString() ?? ''),
    ratingCount: int.tryParse(json['rating_count']?.toString() ?? ''),
    moduleId: int.tryParse(json['module_id']?.toString() ?? ''),
    storeId: int.tryParse(json['store_id']?.toString() ?? ''),
    storeName: json['store_name']?.toString(),
    providerImageFullUrl: json['provider_image_full_url']?.toString(),
    verifiedProvider: int.tryParse(json['verified_provider']?.toString() ?? ''),
    distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
    categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
    subCategoryId: int.tryParse(json['sub_category_id']?.toString() ?? ''),
    category: json['category'] != null ? ServiceMiniCategory.fromJson(json['category'] as Map<String, dynamic>) : null,
    subCategory: json['sub_category'] != null ? ServiceMiniCategory.fromJson(json['sub_category'] as Map<String, dynamic>) : null,
    provider: json['provider'] != null ? ServiceProvider.fromJson(json['provider'] as Map<String, dynamic>) : null,
    faqs: (json['faqs'] as List<dynamic>?)?.map((e) => ServiceFaq.fromJson(e as Map<String, dynamic>)).toList(),
    deliveryTime: (json['provider'] as Map<String, dynamic>?)?['delivery_time']?.toString(),
    totalReviews: int.tryParse(json['total_reviews']?.toString() ?? ''),
    reviews: (json['reviews'] as List<dynamic>?)?.map((e) => ServiceReview.fromJson(e as Map<String, dynamic>)).toList(),
    isFavourite: json['is_favorite'] == true || json['is_favourite'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'short_description': shortDescription,
    'long_description': longDescription,
    'thumbnail_full_url': thumbnailFullUrl,
    'additional_images_full_url': additionalImagesFullUrl,
    'base_price': basePrice,
    'min_bid_price': minBidPrice,
    'discount': discount,
    'discount_type': discountType,
    'discounted_price': discountedPrice,
    'variations': variations?.map((e) => e.toJson()).toList(),
    'tags': tags,
    'recommended': recommended,
    'order_count': orderCount,
    'avg_rating': avgRating,
    'rating_count': ratingCount,
    'module_id': moduleId,
    'store_id': storeId,
    'store_name': storeName,
    'provider_image_full_url': providerImageFullUrl,
    'verified_provider': verifiedProvider,
    'distance_km': distanceKm,
    'category_id': categoryId,
    'sub_category_id': subCategoryId,
    'category': category?.toJson(),
    'sub_category': subCategory?.toJson(),
    'provider': provider?.toJson(),
    'faqs': faqs?.map((e) => e.toJson()).toList(),
    'delivery_time': deliveryTime,
    'total_reviews': totalReviews,
    'reviews': reviews?.map((e) => e.toJson()).toList(),
    'is_favourite': isFavourite,
  };
}

class ServiceVariation {
  final String? variantKey;
  final String? name;
  final double? price;
  final double? discount;
  final String? discountType;

  ServiceVariation({this.variantKey, this.name, this.price, this.discount, this.discountType});

  factory ServiceVariation.fromJson(Map<String, dynamic> json) => ServiceVariation(
    variantKey: json['variant_key']?.toString(),
    name: json['name']?.toString(),
    price: double.tryParse(json['price']?.toString() ?? ''),
    discount: double.tryParse(json['discount']?.toString() ?? ''),
    discountType: json['discount_type']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'variant_key': variantKey, 'name': name, 'price': price, 'discount': discount, 'discount_type': discountType,
  };
}

/// Service Module — FAQ entry, populated only by the service-details endpoint
/// (active FAQs only).
class ServiceFaq {
  final int? id;
  final String? question;
  final String? answer;

  ServiceFaq({this.id, this.question, this.answer});

  factory ServiceFaq.fromJson(Map<String, dynamic> json) => ServiceFaq(
    id: int.tryParse(json['id']?.toString() ?? ''),
    question: json['question']?.toString(),
    answer: json['answer']?.toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'question': question, 'answer': answer};
}

class ServiceMiniCategory {
  final int? id;
  final String? name;
  final String? slug;

  ServiceMiniCategory({this.id, this.name, this.slug});

  factory ServiceMiniCategory.fromJson(Map<String, dynamic> json) => ServiceMiniCategory(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}
