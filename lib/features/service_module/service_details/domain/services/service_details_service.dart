import 'package:sixam_mart/features/service_module/service_details/domain/repositories/service_details_repository_interface.dart';

import 'service_details_service_interface.dart';

class ServiceDetailsService implements ServiceDetailsServiceInterface {
  final ServiceDetailsRepositoryInterface serviceDetailsRepositoryInterface;
  ServiceDetailsService({required this.serviceDetailsRepositoryInterface});
}
