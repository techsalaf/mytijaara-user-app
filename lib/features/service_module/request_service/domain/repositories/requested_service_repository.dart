import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/service_module/request_service/domain/repositories/requested_service_repository_interface.dart';

class RequestedServiceRepository implements RequestedServiceRepositoryInterface {
  final ApiClient apiClient;
  RequestedServiceRepository({required this.apiClient});
}
