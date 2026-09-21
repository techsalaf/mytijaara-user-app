import 'package:get/get.dart';
import 'package:sixam_mart/features/service_module/service_checkout/domain/services/service_checkout_service_interface.dart';

/// Where the customer wants the service — their own location or the provider's.
enum ServiceLocationType { myLocation, providerLocation }

class ServiceCheckoutController extends GetxController implements GetxService {
  final ServiceCheckoutServiceInterface serviceCheckoutServiceInterface;
  ServiceCheckoutController({required this.serviceCheckoutServiceInterface});

  bool get isCreateAccount => false;

  void saveLoyaltyEarningPoint(double total) {}
}
