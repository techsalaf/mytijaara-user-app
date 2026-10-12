import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/favourite/domain/repositories/favourite_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class FavouriteRepository implements FavouriteRepositoryInterface<ResponseModel> {
  final ApiClient apiClient;
  FavouriteRepository({required this.apiClient});

  @override
  Future<Response> getList({int? offset}) async {
    return await apiClient.getData(AppConstants.wishListGetUri);
  }

  @override
  Future<ResponseModel> add(dynamic a, {bool isStore = false, int? id, bool isServiceModule = false}) async {
    final String paramKey = isStore ? 'store_id=' : (isServiceModule ? 'service_id=' : 'item_id=');
    Response response = await apiClient.postData('${AppConstants.addWishListUri}$paramKey$id', null, handleError: false);
    return _responseOf(response);
  }

  @override
  Future<ResponseModel> delete(int? id, {bool isStore = false, bool isServiceModule = false}) async {
    final String paramKey = isStore ? 'store_id=' : (isServiceModule ? 'service_id=' : 'item_id=');
    Response response = await apiClient.deleteData('${AppConstants.removeWishListUri}$paramKey$id', handleError: false);
    return _responseOf(response);
  }

  ResponseModel _responseOf(Response response) {
    // Add answers 201, so any 2xx counts and the body's message is what the user sees.
    final dynamic message = response.body is Map ? response.body['message'] : null;
    if (ApiClient.isSuccessCode(response.statusCode)) {
      return ResponseModel(true, message is String ? message : response.statusText);
    }
    return ResponseModel(false, response.statusText);
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

// SUMMARY
// Wish-list data source. Fetches the customer's favourites and adds or removes an
// item, store or service, returning the API's own success or failure message for the
// snackbar to show.
