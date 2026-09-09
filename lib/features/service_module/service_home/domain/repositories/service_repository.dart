import '../../../../../api/api_client.dart';
import 'service_repository_interface.dart';

class ServiceRepository implements ServiceRepositoryInterface {
  final ApiClient apiClient;
  ServiceRepository({required this.apiClient});

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
