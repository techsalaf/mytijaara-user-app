import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class ServiceBannerModel {
  final int? id;
  final String? title;
  final String? type;
  final String? image;
  final String? imageFullUrl;
  final String? link;
  final ServiceBannerCategory? category;
  final Service? service;

  ServiceBannerModel({this.id, this.title, this.type, this.image, this.imageFullUrl, this.link, this.category, this.service});

  factory ServiceBannerModel.fromJson(Map<String, dynamic> json) => ServiceBannerModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    title: json['title']?.toString(),
    type: json['type']?.toString(),
    image: json['image']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
    link: json['link']?.toString(),
    category: json['category'] != null ? ServiceBannerCategory.fromJson(json['category'] as Map<String, dynamic>) : null,
    service: json['service'] != null ? Service.fromJson(json['service'] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'type': type, 'image': image,
    'image_full_url': imageFullUrl, 'link': link,
    'category': category?.toJson(), 'service': service?.toJson(),
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
