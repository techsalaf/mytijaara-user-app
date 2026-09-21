import 'package:get/get.dart';
import 'package:sixam_mart/features/service_module/service_category/domain/services/service_category_service_interface.dart';

class ServiceCategoryController extends GetxController implements GetxService {
  final ServiceCategoryServiceInterface serviceCategoryServiceInterface;
  ServiceCategoryController({required this.serviceCategoryServiceInterface});
}
