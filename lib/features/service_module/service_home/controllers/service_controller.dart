import 'package:get/get.dart';
import '../domain/services/service_service_interface.dart';

class ServiceController extends GetxController implements GetxService {
  final ServiceServiceInterface serviceServiceInterface;
  ServiceController({required this.serviceServiceInterface});
}
