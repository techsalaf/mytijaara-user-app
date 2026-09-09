import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_category_items_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/store/domain/repositories/store_repository_interface.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/header_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class StoreRepository implements StoreRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  StoreRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future getList({int? offset, bool isStoreList = false, String? filterBy, bool isPopularStoreList = false, String? type, bool isLatestStoreList = false,
    bool isFeaturedStoreList = false, bool isVisitAgainStoreList = false, bool isStoreRecommendedItemList = false, int? storeId,
    bool isStoreBannerList = false, bool isRecommendedStoreList = false, bool isTopOfferStoreList = false, bool fromHome = false, DataSourceEnum? source, String name = ''}) async {
    if(isStoreList){
      return await _getStoreList(offset!, filterBy!, type!, source: source ?? DataSourceEnum.client, name: name);
    }else if(isPopularStoreList){
      return await _getPopularStoreList(type!, source: source ?? DataSourceEnum.client);
    }else if(isLatestStoreList){
      return await _getLatestStoreList(type!, source: source ?? DataSourceEnum.client);
    }else if(isFeaturedStoreList){
      return await _getFeaturedStoreList(source: source ?? DataSourceEnum.client, fromHome: fromHome);
    }else if(isVisitAgainStoreList){
      return await _getVisitAgainStoreList(source: source ?? DataSourceEnum.client);
    }else if(isStoreRecommendedItemList){
      return await _getStoreRecommendedItemList(storeId);
    }else if(isStoreBannerList){
      return await _getStoreBannerList(storeId);
    }else if(isRecommendedStoreList){
      return await _getRecommendedStoreList(source: source ?? DataSourceEnum.client);
    }else if(isTopOfferStoreList){
      return await _getTopOfferStoreList(source: source ?? DataSourceEnum.client, filterBy: filterBy, sortBy: type);
    }
  }

  @override
  Future<StoreModel?> getQuickDeliveryStores({int offset = 1, int limit = 10, int? moduleId, String name = ''}) async {
    final String nameQuery = name.isNotEmpty ? '&search=${Uri.encodeComponent(name)}' : '';
    final Response response = await apiClient.getData(
      '${AppConstants.quickDeliveryStoresUri}?limit=$limit&offset=$offset&with_items=1$nameQuery',
      headers: _headersWithModule(moduleId), moduleScoped: moduleId == null,
    );
    if(response.statusCode == 200) {
      return StoreModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<StoreModel?> getNearbyStores({int offset = 1, int limit = 10, int? moduleId, String name = ''}) async {
    final Response response = await apiClient.getData(
      '${AppConstants.distanceStoresUri}?type=all&name=${Uri.encodeComponent(name)}&limit=$limit&offset=$offset',
      headers: _headersWithModule(moduleId),
    );
    if(response.statusCode == 200) {
      return StoreModel.fromJson(response.body);
    }
    return null;
  }

  Map<String, String>? _headersWithModule(int? moduleId) {
    if(moduleId == null) return null;
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers[AppConstants.moduleId] = '$moduleId';
    return headers;
  }

  Future<StoreModel?> _getStoreList(int offset, String filterBy, String storeType, {required DataSourceEnum source, String name = ''}) async {
    StoreModel? storeModel;
    final String nameQuery = name.isNotEmpty ? '&search=${Uri.encodeComponent(name)}' : '';
    String cacheId = '${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=12$nameQuery-${Get.find<SplashController>().module?.id??''}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.storeUri}/$filterBy?store_type=$storeType&offset=$offset&limit=12$nameQuery', moduleScoped: true);
        if(response.statusCode == 200){
          storeModel = StoreModel.fromJson(response.body);
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:

        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          storeModel = StoreModel.fromJson(jsonDecode(cacheResponseData));
        }
    }
    return storeModel;
  }

  Future<List<Store>?> _getPopularStoreList(String type, {required DataSourceEnum source}) async {
    List<Store>? popularStoreList;
    String cacheId = '${AppConstants.popularStoreUri}?type=$type&offset=1&limit=50-${Get.find<SplashController>().module?.id??''}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.popularStoreUri}?type=$type&offset=1&limit=50', moduleScoped: true);
        if (response.statusCode == 200) {
          popularStoreList = [];
          final List storesJson = response.body['stores'] as List? ?? [];
          for (var store in storesJson) { popularStoreList.add(Store.fromJson(store)); }
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(storesJson), apiClient.getHeader());
        }

      case DataSourceEnum.local:

        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          popularStoreList = [];
          jsonDecode(cacheResponseData).forEach((store) => popularStoreList!.add(Store.fromJson(store)));
        }
    }
    return popularStoreList;
  }

  Future<List<Store>?> _getLatestStoreList(String type, {required DataSourceEnum source}) async {
    List<Store>? latestStoreList;
    String cacheId = '${AppConstants.latestStoreUri}?type=$type&offset=1&limit=50-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.latestStoreUri}?type=$type&offset=1&limit=50', moduleScoped: true);
        if (response.statusCode == 200) {
          latestStoreList = [];
          final List storesJson = response.body['stores'] as List? ?? [];
          for (var store in storesJson) { latestStoreList.add(Store.fromJson(store)); }
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(storesJson), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          latestStoreList = [];
          jsonDecode(cacheResponseData).forEach((store) => latestStoreList!.add(Store.fromJson(store)));
        }
    }

    return latestStoreList;
  }

  Future<List<Store>?> _getTopOfferStoreList({required DataSourceEnum source, String? filterBy, String? sortBy}) async {
    List<Store>? topOfferStoreList;
    String cacheId = '${AppConstants.topOfferStoreUri}-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.topOfferStoreUri}?sort_by=$sortBy&${filterBy == '1' ? 'halal=1' : filterBy == 'veg' ? 'type=veg' : filterBy == 'non_veg' ? 'type=non_veg' : 'type='}', moduleScoped: true);
        if (response.statusCode == 200) {
          topOfferStoreList = [];
          response.body['stores'].forEach((store) => topOfferStoreList!.add(Store.fromJson(store)));
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(response.body['stores']), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          topOfferStoreList = [];
          jsonDecode(cacheResponseData).forEach((store) => topOfferStoreList!.add(Store.fromJson(store)));
        }
    }
    return topOfferStoreList;
  }

  Future<List<Store>?> _getFeaturedStoreList({required DataSourceEnum source, bool fromHome = false}) async {
    List<Store>? featuredStoreList;
    final bool useFeaturedHeader = fromHome
        || (Get.find<SplashController>().module == null && Get.find<SplashController>().configModel!.module == null);
    final String cacheSuffix = useFeaturedHeader ? 'home' : '${Get.find<SplashController>().module?.id ?? ''}';
    String cacheId = '${AppConstants.storeUri}/all?featured=1&offset=1&limit=50-$cacheSuffix';
    Map<String, String> header = useFeaturedHeader ? HeaderHelper.featuredHeader() : apiClient.getHeader();

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(
          '${AppConstants.storeUri}/all?featured=1&offset=1&limit=50',
          headers: useFeaturedHeader ? HeaderHelper.featuredHeader() : null,
        );
        if (response.statusCode == 200) {
          featuredStoreList = [];
          response.body['stores'].forEach((store) => featuredStoreList!.add(Store.fromJson(store)));
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(response.body['stores']), header);
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          featuredStoreList = [];
          jsonDecode(cacheResponseData).forEach((store) => featuredStoreList!.add(Store.fromJson(store)));
        }
    }
    return featuredStoreList;
  }

  Future<List<Store>?> _getVisitAgainStoreList({required DataSourceEnum source}) async {
    List<Store>? visitAgainStoreList;
    String cacheId = '${AppConstants.visitAgainStoreUri}-${ModuleHelper.getModule()?.id}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.visitAgainStoreUri, moduleScoped: true);
        if (response.statusCode == 200) {
          visitAgainStoreList = [];
          response.body.forEach((store) => visitAgainStoreList!.add(Store.fromJson(store)));
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(response.body), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          visitAgainStoreList = [];
          jsonDecode(cacheResponseData).forEach((store) => visitAgainStoreList!.add(Store.fromJson(store)));
        }
    }
    return visitAgainStoreList;
  }

  @override
  Future<Store?> getStoreDetails(String storeID, bool fromCart, String slug, String languageCode, ModuleModel? module, int? cacheModuleId, int? moduleId) async {
    Store? store;
    Map<String, String>? header ;
    if(fromCart){
      AddressModel? addressModel = AddressHelper.getUserAddressFromSharedPref();
      header = apiClient.updateHeader(
        sharedPreferences.getString(AppConstants.token), addressModel?.zoneIds, addressModel?.areaIds,
        languageCode, module == null ? cacheModuleId?.toString() : moduleId?.toString(),
        addressModel?.latitude, addressModel?.longitude, null, setHeader: false,
      );
    }
    if(slug.isNotEmpty){
      header = apiClient.updateHeader(
        sharedPreferences.getString(AppConstants.token), [], [],
        languageCode, "0", '', '', null, setHeader: false,
      );
    }
    Response response = await apiClient.getData('${AppConstants.storeDetailsUri}${slug.isNotEmpty ? slug : storeID}', headers: header);
    if(response.statusCode == 200){
      store = Store.fromJson(response.body);
    }
    return store;
  }

  @override
  Future<ItemModel?> getStoreItemList({int? storeID, required int offset, int? categoryID, String? type, List<String>? filter, int? rating, double? lowerValue, double? upperValue}) async {
    ItemModel? storeItemModel;
    final filterString = filter != null ? jsonEncode(filter) : null;
    Response response = await apiClient.getData(
      '${AppConstants.storeItemUri}?store_id=$storeID&category_id=$categoryID&offset=$offset&limit=13&type=$type&filter=$filterString&rating_count=${rating ?? ''}&min_price=${lowerValue ?? ''}&max_price=${upperValue ?? ''}');
    if(response.statusCode == 200){
      storeItemModel = ItemModel.fromJson(response.body);
    }
    return storeItemModel;
  }

  @override
  Future<ItemModel?> getStoreSearchItemList(String searchText, String? storeID, int offset, String type, int? categoryID) async {
    ItemModel? storeSearchItemModel;
    Response response = await apiClient.getData(
      '${AppConstants.searchUri}items/search?store_id=$storeID&name=$searchText&offset=$offset&limit=10&type=$type&category_id=${categoryID ?? ''}');
    if(response.statusCode == 200){
      storeSearchItemModel = ItemModel.fromJson(response.body);
    }
    return storeSearchItemModel;
  }

  Future<RecommendedItemModel?> _getStoreRecommendedItemList(int? storeId) async {
    RecommendedItemModel? recommendedItemModel;
    Response response = await apiClient.getData('${AppConstants.storeRecommendedItemUri}?store_id=$storeId&offset=1&limit=50');
    if(response.statusCode == 200){
      recommendedItemModel = RecommendedItemModel.fromJson(response.body);
    }
    return recommendedItemModel;
  }

  @override
  Future<CartSuggestItemModel?> getCartStoreSuggestedItemList(int? storeId, String languageCode, ModuleModel? module, int? cacheModuleId, int? moduleId) async {
    CartSuggestItemModel? cartSuggestItemModel;
    AddressModel? addressModel = AddressHelper.getUserAddressFromSharedPref();
    Map<String, String> header = apiClient.updateHeader(
      sharedPreferences.getString(AppConstants.token), addressModel?.zoneIds, addressModel?.areaIds,
      languageCode, module == null ? cacheModuleId?.toString() : moduleId?.toString(),
      addressModel?.latitude, addressModel?.longitude, null, setHeader: false,
    );
    Response response = await apiClient.getData('${AppConstants.cartStoreSuggestedItemsUri}?recommended=1&store_id=$storeId&offset=1&limit=50', headers: header);
    if(response.statusCode == 200){
      cartSuggestItemModel = CartSuggestItemModel.fromJson(response.body);
    }
    return cartSuggestItemModel;
  }

  Future<List<StoreBannerModel>?> _getStoreBannerList(int? storeId) async {
    List<StoreBannerModel>? storeBanners;
    Response response = await apiClient.getData('${AppConstants.storeBannersUri}$storeId');
    if (response.statusCode == 200) {
      storeBanners = [];
      response.body.forEach((banner) => storeBanners!.add(StoreBannerModel.fromJson(banner)));
    }
    return storeBanners;
  }

  Future<List<Store>?> _getRecommendedStoreList({required DataSourceEnum source}) async {
    List<Store>? recommendedStoreList;
    String cacheId = '${AppConstants.recommendedStoreUri}/all?featured=1&offset=1&limit=50-${Get.find<SplashController>().module?.id??''}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.recommendedStoreUri}?offset=1&limit=50', moduleScoped: true);
        if (response.statusCode == 200) {
          recommendedStoreList = [];
          final List storesJson = response.body['stores'] as List? ?? [];
          for (var store in storesJson) { recommendedStoreList.add(Store.fromJson(store)); }
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(storesJson), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          recommendedStoreList = [];
          jsonDecode(cacheResponseData).forEach((store) => recommendedStoreList!.add(Store.fromJson(store)));
        }
    }

    return recommendedStoreList;
  }

  @override
  Future<StoreCategoryItemsModel?> getStoreCategoryItems(int storeId) async {
    StoreCategoryItemsModel? model;
    Response response = await apiClient.getData('${AppConstants.storeCategoryItemsUri}?store_id=$storeId');
    if (response.statusCode == 200) {
      model = StoreCategoryItemsModel.fromJson(response.body);
    }
    return model;
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