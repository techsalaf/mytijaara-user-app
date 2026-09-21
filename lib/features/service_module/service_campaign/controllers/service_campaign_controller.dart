import 'package:get/get.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/services/service_service_interface.dart';

class ServiceCampaignController extends GetxController implements GetxService {
  final ServiceServiceInterface serviceServiceInterface;
  ServiceCampaignController({required this.serviceServiceInterface});
}
