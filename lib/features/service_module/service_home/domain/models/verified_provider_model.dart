import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';

class VerifiedProviderModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<ServiceProvider>? stores;

  VerifiedProviderModel({this.totalSize, this.limit, this.offset, this.stores});

  factory VerifiedProviderModel.fromJson(Map<String, dynamic> json) => VerifiedProviderModel(
    totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
    limit: int.tryParse(json['limit']?.toString() ?? ''),
    offset: int.tryParse(json['offset']?.toString() ?? ''),
    stores: (json['stores'] as List<dynamic>?)
        ?.map((e) => ServiceProvider.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'total_size': totalSize, 'limit': limit, 'offset': offset,
    'stores': stores?.map((e) => e.toJson()).toList(),
  };
}
