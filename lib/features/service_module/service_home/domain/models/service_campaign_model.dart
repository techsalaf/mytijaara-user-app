import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

/// Service Module — running-campaign list envelope
/// `{ total_size, limit, offset, campaigns[] }` from `GET service/campaigns`.
class ServiceCampaignModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<ServiceCampaign>? campaigns;

  ServiceCampaignModel({this.totalSize, this.limit, this.offset, this.campaigns});

  factory ServiceCampaignModel.fromJson(Map<String, dynamic> json) => ServiceCampaignModel(
    totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
    limit: int.tryParse(json['limit']?.toString() ?? ''),
    offset: int.tryParse(json['offset']?.toString() ?? ''),
    campaigns: (json['campaigns'] as List<dynamic>?)
        ?.map((e) => ServiceCampaign.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Service Module — a running service campaign. Its shape parallels [Service]
/// (all service fields copied onto the campaign) plus campaign-only fields:
/// the schedule window, the owning provider summary, and the verified flag. The
/// details endpoint additionally embeds the full [provider]. Use [toService] to
/// render a campaign with the service widgets.
class ServiceCampaign {
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
  final double? discountedPrice;
  final List<ServiceVariation>? variations;
  final List<String>? tags;
  final int? moduleId;
  final int? storeId;
  final int? categoryId;
  final int? subCategoryId;
  final ServiceMiniCategory? category;
  final ServiceMiniCategory? subCategory;

  // Campaign-only fields.
  final String? providerName;
  final String? providerImageFullUrl;
  final int? verifiedProvider;
  final String? availableDateStarts;
  final String? availableDateEnds;
  final String? availableTimeStarts;
  final String? availableTimeEnds;
  final int? status;

  bool isFavourite;

  ServiceCampaign({this.id, this.name, this.slug, this.shortDescription, this.longDescription,
    this.thumbnailFullUrl, this.additionalImagesFullUrl, this.basePrice, this.minBidPrice, this.discount,
    this.discountType, this.discountedPrice, this.variations, this.tags, this.moduleId,
    this.storeId, this.categoryId, this.subCategoryId, this.category, this.subCategory,
    this.providerName, this.providerImageFullUrl, this.verifiedProvider, this.availableDateStarts, this.availableDateEnds,
    this.availableTimeStarts, this.availableTimeEnds, this.status, this.isFavourite = false,
  });

  factory ServiceCampaign.fromJson(Map<String, dynamic> json) => ServiceCampaign(
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
    moduleId: int.tryParse(json['module_id']?.toString() ?? ''),
    storeId: int.tryParse(json['store_id']?.toString() ?? ''),
    categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
    subCategoryId: int.tryParse(json['sub_category_id']?.toString() ?? ''),
    category: json['category'] != null ? ServiceMiniCategory.fromJson(json['category'] as Map<String, dynamic>) : null,
    subCategory: json['sub_category'] != null ? ServiceMiniCategory.fromJson(json['sub_category'] as Map<String, dynamic>) : null,
    providerName: json['provider_name']?.toString(),
    providerImageFullUrl: json['provider_image_full_url']?.toString(),
    verifiedProvider: int.tryParse(json['verified_provider']?.toString() ?? ''),
    availableDateStarts: json['available_date_starts']?.toString(),
    availableDateEnds: json['available_date_ends']?.toString(),
    availableTimeStarts: json['available_time_starts']?.toString(),
    availableTimeEnds: json['available_time_ends']?.toString(),
    status: int.tryParse(json['status']?.toString() ?? ''),
    isFavourite: json['is_favorite'] == true || json['is_favourite'] == true,
  );
}
