import 'package:get/get.dart';
import '../domain/services/service_service_interface.dart';

class ServiceExploreController extends GetxController implements GetxService {
  final ServiceServiceInterface serviceServiceInterface;
  ServiceExploreController({required this.serviceServiceInterface});
}
