import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/redesign_feature/common/models/new_item_model.dart';
import 'package:sixam_mart/features/offer/domain/repositories/offer_repository_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class OfferRepository implements OfferRepositoryInterface {
  final ApiClient apiClient;
  OfferRepository({required this.apiClient});

  @override
  Future<NewItemListResponse?> getOfferItems({required int offset, int limit = 10, String search = '', int? moduleId}) async {
    final Response response = await apiClient.getData(
      '${AppConstants.offerItemsUri}?search=$search&limit=$limit&offset=$offset',
      headers: _headersWithModule(moduleId),
    );
    if (response.statusCode == 200) {
      return NewItemListResponse.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<StoreModel?> getOfferStores({required int offset, int limit = 10, String search = '', int? moduleId}) async {
    final Response response = await apiClient.getData(
      '${AppConstants.offerStoresUri}?search=$search&limit=$limit&offset=$offset',
      headers: _headersWithModule(moduleId),
    );
    if (response.statusCode == 200) {
      return StoreModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<List<Store>?> getExclusiveDeals({int? moduleId}) async {
    final Response response = await apiClient.getData(
      AppConstants.exclusiveDealsUri,
      headers: _headersWithModule(moduleId),
    );
    if (response.statusCode == 200) {
      return StoreModel.fromJson(response.body).stores;
    }
    return null;
  }

  Map<String, String>? _headersWithModule(int? moduleId) {
    if (moduleId == null) return null;
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers[AppConstants.moduleId] = '$moduleId';
    return headers;
  }

  @override
  Future add(value) => throw UnimplementedError();

  @override
  Future delete(int? id) => throw UnimplementedError();

  @override
  Future get(String? id) => throw UnimplementedError();

  @override
  Future getList({int? offset}) => throw UnimplementedError();

  @override
  Future update(Map<String, dynamic> body, int? id) => throw UnimplementedError();
}
