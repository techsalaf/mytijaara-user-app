import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

/// Service Module — "Quick & Emergency Experts" envelope
/// `{ total_size, limit, offset, providers[] }` returned by
/// `/api/v1/service/quick-emergency-experts`. Each provider carries a small
/// `services[]` preview list (capped by the request's `preview_count`), reused
/// from the shared [Service] model since the keys are identical.
class ServiceExpertsModel {
  final int? totalSize;
  final int? limit;
  final int? offset;
  final List<ServiceExpertProvider>? providers;

  ServiceExpertsModel({this.totalSize, this.limit, this.offset, this.providers});

  factory ServiceExpertsModel.fromJson(Map<String, dynamic> json) => ServiceExpertsModel(
    totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
    limit: int.tryParse(json['limit']?.toString() ?? ''),
    offset: int.tryParse(json['offset']?.toString() ?? ''),
    providers: (json['providers'] as List<dynamic>?)
        ?.map((e) => ServiceExpertProvider.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'total_size': totalSize,
    'limit': limit,
    'offset': offset,
    'providers': providers?.map((e) => e.toJson()).toList(),
  };
}

/// A provider in the Quick & Emergency Experts section, with its preview
/// services bundled in. `deliveryTime` is the human-readable text the API
/// supplies (e.g. "20-60 min") and is rendered as-is.
class ServiceExpertProvider {
  final int? id;
  final String? name;
  final String? slug;
  final String? logoFullUrl;
  final String? coverPhotoFullUrl;
  final String? address;
  final double? rating;
  final String? deliveryTime;
  final int? minDeliveryTime;
  final int? maxDeliveryTime;
  final double? distanceKm;
  final int? open;
  final List<Service>? services;

  ServiceExpertProvider({this.id, this.name, this.slug, this.logoFullUrl, this.coverPhotoFullUrl,
    this.address, this.rating, this.deliveryTime, this.minDeliveryTime, this.maxDeliveryTime,
    this.distanceKm, this.open, this.services,
  });

  factory ServiceExpertProvider.fromJson(Map<String, dynamic> json) => ServiceExpertProvider(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
    logoFullUrl: json['logo_full_url']?.toString(),
    coverPhotoFullUrl: json['cover_photo_full_url']?.toString(),
    address: json['address']?.toString(),
    rating: double.tryParse(json['rating']?.toString() ?? ''),
    deliveryTime: json['delivery_time']?.toString(),
    minDeliveryTime: int.tryParse(json['min_delivery_time']?.toString() ?? ''),
    maxDeliveryTime: int.tryParse(json['max_delivery_time']?.toString() ?? ''),
    distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
    open: int.tryParse(json['open']?.toString() ?? ''),
    services: (json['services'] as List<dynamic>?)
        ?.map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo_full_url': logoFullUrl,
    'cover_photo_full_url': coverPhotoFullUrl,
    'address': address,
    'rating': rating,
    'delivery_time': deliveryTime,
    'min_delivery_time': minDeliveryTime,
    'max_delivery_time': maxDeliveryTime,
    'distance_km': distanceKm,
    'open': open,
    'services': services?.map((e) => e.toJson()).toList(),
  };
}
