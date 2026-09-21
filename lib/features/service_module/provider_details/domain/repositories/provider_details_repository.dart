import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/service_module/provider_details/domain/repositories/provider_details_repository_interface.dart';

class ProviderDetailsRepository implements ProviderDetailsRepositoryInterface {
  final ApiClient apiClient;
  ProviderDetailsRepository({required this.apiClient});

  @override
  Future add(value) { throw UnimplementedError(); }

  @override
  Future delete(int? id) { throw UnimplementedError(); }

  @override
  Future get(String? id) { throw UnimplementedError(); }

  @override
  Future getList({int? offset}) { throw UnimplementedError(); }

  @override
  Future update(Map<String, dynamic> body, int? id) { throw UnimplementedError(); }
}
