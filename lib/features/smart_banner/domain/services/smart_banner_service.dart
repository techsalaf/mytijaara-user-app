import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';
import 'package:sixam_mart/features/smart_banner/domain/repositories/smart_banner_repository_interface.dart';
import 'package:sixam_mart/features/smart_banner/domain/services/smart_banner_service_interface.dart';

class SmartBannerService implements SmartBannerServiceInterface {
  final SmartBannerRepositoryInterface smartBannerRepositoryInterface;
  SmartBannerService({required this.smartBannerRepositoryInterface});

  @override
  Future<SmartBannerModel?> getSmartBannerList() async {
    return await smartBannerRepositoryInterface.getList();
  }
}
