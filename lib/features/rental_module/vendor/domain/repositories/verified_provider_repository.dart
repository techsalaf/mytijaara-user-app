
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/verified_provider_repository_interface.dart';


class VerifiedProviderRepository implements VerifiedProviderRepositoryInterface {
  final ApiClient apiClient;

  VerifiedProviderRepository({required this.apiClient});

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}
