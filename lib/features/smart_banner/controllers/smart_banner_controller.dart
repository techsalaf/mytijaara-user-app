import 'package:get/get.dart';
import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';
import 'package:sixam_mart/features/smart_banner/domain/services/smart_banner_service_interface.dart';

class SmartBannerController extends GetxController implements GetxService {
  final SmartBannerServiceInterface smartBannerServiceInterface;
  SmartBannerController({required this.smartBannerServiceInterface});

  List<SmartBanner>? _smartBanners;
  List<SmartBanner>? get smartBanners => _smartBanners;

  Future<void> getSmartBanners({bool notify = true}) async {
    // if (notify) update();
    final SmartBannerModel? model = await smartBannerServiceInterface.getSmartBannerList();
    _smartBanners = [];
    _smartBanners = model?.smartBanners ?? <SmartBanner>[];
    update();
  }
}
