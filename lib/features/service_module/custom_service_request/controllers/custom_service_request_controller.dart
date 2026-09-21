import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/features/service_module/custom_service_request/domain/services/custom_service_request_service_interface.dart';

class CustomServiceRequestController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  final CustomServiceRequestServiceInterface customServiceRequestServiceInterface;

  CustomServiceRequestController({required this.categoryServiceInterface, required this.customServiceRequestServiceInterface});

  Future<void> refreshDetail(int id) async {}
}
