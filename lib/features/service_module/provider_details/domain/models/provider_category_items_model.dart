import 'package:sixam_mart/features/service_module/service_home/domain/models/service_category_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

/// Service Module — `GET /api/v1/store-categories/items?store_id={id}` envelope.
/// Mirrors the main store's `StoreCategoryItemsModel`, but the `category_wise_items`
/// entries are already standard [Service] objects so they parse directly.
class ProviderCategoryItemsModel {
  final int? totalSize;
  final int? limit;
  final int? offset;
  final String? categorySource;
  final List<ServiceCategoryModel>? categories;
  final Map<String, List<Service>>? categoryWiseServices;

  ProviderCategoryItemsModel({this.totalSize, this.limit, this.offset, this.categorySource,
    this.categories, this.categoryWiseServices,
  });

  factory ProviderCategoryItemsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? catWiseMap = json['category_wise_items'] as Map<String, dynamic>?;
    Map<String, List<Service>>? parsedCatWiseServices;
    if (catWiseMap != null) {
      parsedCatWiseServices = catWiseMap.map((key, value) => MapEntry(
        key,
        value is List
            ? value.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList()
            : <Service>[],
      ));
    }

    return ProviderCategoryItemsModel(
      totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
      limit: int.tryParse(json['limit']?.toString() ?? ''),
      offset: int.tryParse(json['offset']?.toString() ?? ''),
      categorySource: json['category_source']?.toString(),
      categories: json['categories'] is List
          ? (json['categories'] as List).map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      categoryWiseServices: parsedCatWiseServices,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_size': totalSize,
    'limit': limit,
    'offset': offset,
    'category_source': categorySource,
    'categories': categories?.map((e) => e.toJson()).toList(),
    'category_wise_items': categoryWiseServices?.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
  };
}

/// Paginated result envelope for `/api/v1/products/search?store_id={id}&search={q}`.
class ServiceSearchModel {
  int? totalSize;
  int? offset;
  List<Service>? services;

  ServiceSearchModel({this.totalSize, this.offset, this.services});

  factory ServiceSearchModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawList = json['services'] ?? json['products'] ?? json['items'];
    return ServiceSearchModel(
      totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
      offset: int.tryParse(json['offset']?.toString() ?? ''),
      services: rawList is List
          ? rawList.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }
}
