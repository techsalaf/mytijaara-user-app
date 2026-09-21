import 'package:sixam_mart/features/service_module/service_cart/domain/repositories/service_cart_repository_interface.dart';
import 'package:sixam_mart/features/service_module/service_cart/domain/services/service_cart_service_interface.dart';

class ServiceCartService implements ServiceCartServiceInterface {
  final ServiceCartRepositoryInterface serviceCartRepositoryInterface;
  ServiceCartService({required this.serviceCartRepositoryInterface});
}
