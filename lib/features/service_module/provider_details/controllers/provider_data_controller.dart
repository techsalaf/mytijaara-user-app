import 'package:get/get.dart';
import '../domain/services/provider_details_service_interface.dart';

class ProviderBookingRecord {}

class ProviderDataController extends GetxController implements GetxService {
  final ProviderDetailsServiceInterface providerDetailsServiceInterface;
  ProviderDataController({required this.providerDetailsServiceInterface});
}
