import 'package:get/get.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/services/booking_service_interface.dart';
import 'package:sixam_mart/features/service_module/provider_details/domain/services/provider_details_service_interface.dart';

class ProviderDataController extends GetxController implements GetxService {
  final ProviderDetailsServiceInterface providerDetailsServiceInterface;
  final BookingServiceInterface bookingServiceInterface;
  ProviderDataController({required this.providerDetailsServiceInterface, required this.bookingServiceInterface});
}
