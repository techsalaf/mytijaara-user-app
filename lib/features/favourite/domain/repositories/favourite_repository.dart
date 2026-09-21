import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/favourite/domain/repositories/favourite_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class FavouriteRepository implements FavouriteRepositoryInterface<ResponseModel> {
  final ApiClient apiClient;
  FavouriteRepository({required this.apiClient});

  bool get isServiceModule =>
      Get.find<SplashController>().module?.moduleType == AppConstants.service;

  @override
  Future<Response> getList({int? offset}) async {
    return await apiClient.getData(AppConstants.wishListGetUri);
  }

  @override
  Future<ResponseModel> add(dynamic a, {bool isStore = false, int? id, bool isServiceModule = false}) async {
    ResponseModel responseModel;
    final String paramKey = isStore ? 'store_id=' : (isServiceModule ? 'service_id=' : 'item_id=');
    Response response = await apiClient.postData('${AppConstants.addWishListUri}$paramKey$id', null, handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body['message']);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  Future<ResponseModel> delete(int? id, {bool isStore = false, bool isServiceModule = false}) async {
    ResponseModel responseModel;
    final String paramKey = isStore ? 'store_id=' : (isServiceModule ? 'service_id=' : 'item_id=');
    Response response = await apiClient.deleteData('${AppConstants.removeWishListUri}$paramKey$id', handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body['message']);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
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