import 'package:get/get.dart';
import '../domain/services/service_details_service_interface.dart';

class ServiceDetailsController extends GetxController implements GetxService {
  final ServiceDetailsServiceInterface serviceDetailsServiceInterface;
  ServiceDetailsController({required this.serviceDetailsServiceInterface});
}
