import 'package:get/get.dart';
import '../domain/services/service_service_interface.dart';

class ServiceVerifiedProviderController extends GetxController implements GetxService {
  final ServiceServiceInterface serviceServiceInterface;
  ServiceVerifiedProviderController({required this.serviceServiceInterface});
}
