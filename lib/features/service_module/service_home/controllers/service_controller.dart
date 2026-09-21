import 'package:get/get.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/services/booking_service_interface.dart';

import '../domain/models/service_model.dart';
import '../domain/services/service_service_interface.dart';

class ServiceController extends GetxController implements GetxService {
  final ServiceServiceInterface serviceServiceInterface;
  final BookingServiceInterface bookingServiceInterface;
  ServiceController({required this.serviceServiceInterface, required this.bookingServiceInterface});

  void toggleFavourite(Service service) {}
}
