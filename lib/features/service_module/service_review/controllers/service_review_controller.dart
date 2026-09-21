import 'package:get/get.dart';

import '../domain/services/service_review_service_interface.dart';

class ServiceReviewController extends GetxController implements GetxService {
  final ServiceReviewServiceInterface serviceReviewServiceInterface;
  ServiceReviewController({required this.serviceReviewServiceInterface});
}
