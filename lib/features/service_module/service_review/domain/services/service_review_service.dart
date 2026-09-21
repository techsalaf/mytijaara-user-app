import 'package:sixam_mart/features/service_module/service_review/domain/repositories/service_review_repository_interface.dart';

import 'service_review_service_interface.dart';

class ServiceReviewService implements ServiceReviewServiceInterface {
  final ServiceReviewRepositoryInterface serviceReviewRepositoryInterface;
  ServiceReviewService({required this.serviceReviewRepositoryInterface});
}
