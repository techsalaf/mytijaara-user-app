import 'dart:convert';

import 'package:get/get.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_category_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/category/domain/reposotories/category_repository_interface.dart';
import 'package:sixam_mart/helper/module_helper.dart';

class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  CategoryRepository({required this.apiClient});

  @override
  Future getList({int? offset, bool categoryList = false, bool subCategoryList = false, bool categoryItemList = false, bool categoryStoreList = false,
    bool? allCategory, String? id, String? type, DataSourceEnum? source}) async {
    if (categoryList) {
      return await _getCategoryList(allCategory!, source ?? DataSourceEnum.client);
    } else if (subCategoryList) {
      return await _getSubCategoryList(id);
    } else if (categoryItemList) {
      return await _getCategoryItemList(id, offset!, type!);
    } else if (categoryStoreList) {
      return await _getCategoryStoreList(id, offset!, type!);
    }
  }

  Future<List<CategoryModel>?> _getCategoryList(bool allCategory, DataSourceEnum source) async {
    List<CategoryModel>? categoryList;
    Map<String, String>? header = allCategory ? {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey: Get.find<LocalizationController>().locale.languageCode,
    } : null;

    Map<String, String>? cacheHeader = header ?? apiClient.getHeader();

    String cacheId = '${AppConstants.categoryUri} ${Get.find<SplashController>().module?.id??''}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.categoryUri, headers: header, moduleScoped: !allCategory);
        if (response.statusCode == 200) {
          final List<dynamic> categoriesJson = ResponseParser.listOrEmpty(response.body);
          categoryList = [];
          for (final dynamic category in categoriesJson) {
            categoryList.add(CategoryModel.fromJson(category));
          }
          // Cache the extracted list, not the raw body, so the local branch below
          // decodes the same shape whichever response format the client branch saw.
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(categoriesJson), cacheHeader);

        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          categoryList = [];
          for (final dynamic category in ResponseParser.listOrEmpty(jsonDecode(cacheResponseData))) {
            categoryList.add(CategoryModel.fromJson(category));
          }
        }
    }

    return categoryList;
  }

  Future<List<CategoryModel>?> _getSubCategoryList(String? parentID) async {
    List<CategoryModel>? subCategoryList;
    Response response = await apiClient.getData('${AppConstants.subCategoryUri}$parentID');
    if (response.statusCode == 200) {
      subCategoryList= [];
      for (final dynamic category in ResponseParser.listOrEmpty(response.body)) {
        subCategoryList.add(CategoryModel.fromJson(category));
      }
    }
    return subCategoryList;
  }

  Future<ItemModel?> _getCategoryItemList(String? categoryID, int offset, String type) async {
    ItemModel? categoryItem;
    Response response = await apiClient.getData('${AppConstants.categoryItemUri}$categoryID?limit=10&offset=$offset&type=$type');
    if (response.statusCode == 200) {
      categoryItem = ItemModel.fromJson(response.body);
    }
    return categoryItem;
  }

  Future<StoreModel?> _getCategoryStoreList(String? categoryID, int offset, String type) async {
    StoreModel? categoryStore;
    Response response = await apiClient.getData('${AppConstants.categoryStoreUri}$categoryID?limit=10&offset=$offset&type=$type');
    if (response.statusCode == 200) {
      categoryStore = StoreModel.fromJson(response.body);
    }
    return categoryStore;
  }

  @override
  Future<Response> getSearchData(String? query, String? categoryID, bool isStore, String type) async {
    return await apiClient.getData(
      '${AppConstants.searchUri}${isStore ? 'stores' : 'items'}/search?name=$query&category_id=$categoryID&type=$type&offset=1&limit=50',
    );
  }

  @override
  Future<bool> saveUserInterests(List<int?> interests) async {
    Response response = await apiClient.postData(AppConstants.interestUri, {"interest": interests});
    return (response.statusCode == 200);
  }

  @override
  Future<List<ServiceCategoryModel>?> getCategoriesWithChildes() async {
    // Reached from profile/menu, so the service module's id has to be pinned here.
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    final int? serviceModuleId = ModuleHelper.getModuleByType(AppConstants.service)?.id;
    if (serviceModuleId != null) {
      headers[AppConstants.moduleId] = '$serviceModuleId';
    }
    final Response response = await apiClient.getData(AppConstants.serviceCategoriesUri, headers: headers);
    if (response.statusCode == 200) {
      return ResponseParser.listOrEmpty(response.body)
          .map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
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

// SUMMARY
// Category data source. Fetches category, sub-category, category item and category
// store lists (cache-first where cached), the category search results, user interest
// saving, and the service module's categories with their sub-categories.
