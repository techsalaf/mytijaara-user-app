
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/verified_provider_repository_interface.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/services/verified_provider_service_interface.dart';

class VerifiedProviderService implements VerifiedProviderServiceInterface {
  final VerifiedProviderRepositoryInterface verifiedProviderRepositoryInterface;

  VerifiedProviderService({required this.verifiedProviderRepositoryInterface});

}
