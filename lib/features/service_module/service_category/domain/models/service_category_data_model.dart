import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

enum ServiceCategoryFilter { all, services, providers }

class CategoryProviderEntry {
  final ServiceProvider provider;
  final List<Service> services;

  const CategoryProviderEntry({required this.provider, required this.services});

  factory CategoryProviderEntry.fromJson(Map<String, dynamic> json) =>
      CategoryProviderEntry(
        provider: ServiceProvider.fromJson(json),
        services: (json['services'] as List<dynamic>?)?.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      );
}

class ServiceCategoryDataModel {
  final List<Service>? services;
  final List<Service>? mostPopularServices;
  final List<CategoryProviderEntry>? providers;
  final int? totalSize;
  final int? offset;
  final int? limit;

  const ServiceCategoryDataModel({
    this.services, this.mostPopularServices, this.providers,
    this.totalSize, this.offset, this.limit,
  });

  factory ServiceCategoryDataModel.fromJson(Map<String, dynamic> json) =>
      ServiceCategoryDataModel(
        services: (json['services'] as List<dynamic>?)?.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList(),
        mostPopularServices: (json['most_popular_services'] as List<dynamic>?)?.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList(),
        providers: (json['providers'] as List<dynamic>?)?.map((e) => CategoryProviderEntry.fromJson(e as Map<String, dynamic>)).toList(),
        totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
        offset: int.tryParse(json['offset']?.toString() ?? ''),
        limit: int.tryParse(json['limit']?.toString() ?? ''),
      );
}
