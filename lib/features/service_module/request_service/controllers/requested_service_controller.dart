import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/features/service_module/request_service/domain/services/requested_service_service_interface.dart';

class RequestedServiceController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  final RequestedServiceServiceInterface requestedServiceServiceInterface;

  RequestedServiceController({required this.categoryServiceInterface, required this.requestedServiceServiceInterface});
}
