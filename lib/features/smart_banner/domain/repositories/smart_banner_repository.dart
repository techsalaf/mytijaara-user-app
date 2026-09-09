import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';
import 'package:sixam_mart/features/smart_banner/domain/repositories/smart_banner_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class SmartBannerRepository implements SmartBannerRepositoryInterface {
  final ApiClient apiClient;
  SmartBannerRepository({required this.apiClient});

  @override
  Future<SmartBannerModel?> getList({int? offset}) async {
    SmartBannerModel? smartBannerModel;
    Response response = await apiClient.getData(AppConstants.smartBannerUri);
    if (response.statusCode == 200 && response.body is Map) {
      smartBannerModel = SmartBannerModel.fromJson(response.body);
    }
    return smartBannerModel;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
