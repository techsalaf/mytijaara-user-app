import 'package:sixam_mart/features/service_module/service_home/domain/repositories/service_repository_interface.dart';

import 'service_service_interface.dart';

class ServiceService implements ServiceServiceInterface {
  final ServiceRepositoryInterface serviceRepositoryInterface;
  ServiceService({required this.serviceRepositoryInterface});
}
