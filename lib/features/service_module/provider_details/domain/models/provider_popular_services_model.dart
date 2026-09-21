import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class ProviderPopularServicesModel {
  final int? totalSize;
  final int? limit;
  final int? offset;
  final List<Service>? services;

  ProviderPopularServicesModel({this.totalSize, this.limit, this.offset, this.services});

  factory ProviderPopularServicesModel.fromJson(dynamic json) {
    if (json is List) {
      return ProviderPopularServicesModel(
        services: json.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }

    final Map<String, dynamic> map = json as Map<String, dynamic>;
    final dynamic rawList = map['services'] ?? map['popular_services'] ?? map['data'] ?? map['items'];
    return ProviderPopularServicesModel(
      totalSize: int.tryParse(map['total_size']?.toString() ?? ''),
      limit: int.tryParse(map['limit']?.toString() ?? ''),
      offset: int.tryParse(map['offset']?.toString() ?? ''),
      services: rawList is List
          ? rawList.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }
}
