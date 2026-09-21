import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class ServiceBannerResponseModel {
  final List<BasicCampaignModel>? campaigns;
  final List<ServiceBannerModel>? banners;

  ServiceBannerResponseModel({this.campaigns, this.banners});

  factory ServiceBannerResponseModel.fromJson(Map<String, dynamic> json) => ServiceBannerResponseModel(
    campaigns: (json['campaigns'] as List<dynamic>?)?.map((e) => BasicCampaignModel.fromJson(e as Map<String, dynamic>)).toList(),
    banners: (json['banners'] as List<dynamic>?)?.map((e) => ServiceBannerModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class ServiceBannerModel {
  final int? id;
  final String? title;
  final String? type;
  final String? image;
  final String? imageFullUrl;
  final String? link;
  final ServiceBannerCategory? category;
  final Service? service;
  final ServiceProvider? provider;
  final int? storeId;

  ServiceBannerModel({this.id, this.title, this.type, this.image, this.imageFullUrl, this.link, this.category, this.service, this.provider,
    this.storeId,
  });

  factory ServiceBannerModel.fromJson(Map<String, dynamic> json) => ServiceBannerModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    title: json['title']?.toString(),
    type: json['type']?.toString(),
    image: json['image']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
    link: json['link']?.toString(),
    category: json['category'] != null ? ServiceBannerCategory.fromJson(json['category'] as Map<String, dynamic>) : null,
    service: json['service'] != null ? Service.fromJson(json['service'] as Map<String, dynamic>) : null,
    provider: json['provider'] != null ? ServiceProvider.fromJson(json['provider'] as Map<String, dynamic>) : null,
    storeId: int.tryParse(json['store_id']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'image': image,
    'image_full_url': imageFullUrl,
    'link': link,
    'category': category?.toJson(),
    'service': service?.toJson(),
    'provider': provider?.toJson(),
    'store_id': storeId,
  };
}

class ServiceBannerCategory {
  final int? id;
  final String? name;
  final String? slug;
  final String? imageFullUrl;

  ServiceBannerCategory({this.id, this.name, this.slug, this.imageFullUrl});

  factory ServiceBannerCategory.fromJson(Map<String, dynamic> json) => ServiceBannerCategory(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug, 'image_full_url': imageFullUrl};
}
