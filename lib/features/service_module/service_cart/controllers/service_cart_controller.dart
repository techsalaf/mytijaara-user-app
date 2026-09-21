import 'package:get/get.dart';
import 'package:sixam_mart/features/service_module/service_cart/domain/services/service_cart_service_interface.dart';

class ServiceCartController extends GetxController implements GetxService {
  final ServiceCartServiceInterface serviceCartServiceInterface;
  ServiceCartController({required this.serviceCartServiceInterface});

  int get serviceCartItemCount => 0;

  Future<void> getServiceCartGroups({bool notify = true}) async {}
}
