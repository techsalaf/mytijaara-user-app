import 'package:sixam_mart/features/service_module/service_category/domain/repositories/service_category_repository_interface.dart';
import 'package:sixam_mart/features/service_module/service_category/domain/services/service_category_service_interface.dart';

class ServiceCategoryService implements ServiceCategoryServiceInterface {
  final ServiceCategoryRepositoryInterface serviceCategoryRepositoryInterface;
  ServiceCategoryService({required this.serviceCategoryRepositoryInterface});
}
