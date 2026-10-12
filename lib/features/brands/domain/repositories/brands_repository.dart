import 'dart:convert';

import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/brands/domain/repositories/brands_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class BrandsRepository implements BrandsRepositoryInterface{
  final ApiClient apiClient;
  BrandsRepository({required this.apiClient});

  @override
  Future<List<BrandModel>?> getBrandList({required DataSourceEnum source}) async {
    List<BrandModel>? brandList;
    String cacheId = '${AppConstants.brandListUri}-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.brandListUri);
        if (response.statusCode == 200) {
          final List<dynamic> brandsJson = ResponseParser.listOrEmpty(response.body);
          brandList = [];
          for (final dynamic brand in brandsJson) {
            brandList.add(BrandModel.fromJson(brand));
          }
          // Cache the extracted list, not the raw body. The body is
          // `{data, pagination}`, and the local branch below decodes whatever was
          // stored — handing it the wrapper made it iterate a Map and throw.
          LocalClient.organize(source, cacheId, jsonEncode(brandsJson), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          brandList = [];
          for (final dynamic brand in ResponseParser.listOrEmpty(jsonDecode(cacheResponseData))) {
            brandList.add(BrandModel.fromJson(brand));
          }
        }
    }

    return brandList;
  }

  @override
  Future<ItemModel?> getBrandItemList({required int brandId, int? offset}) async {
    ItemModel? brandItemModel;
    Response response = await apiClient.getData('${AppConstants.brandItemUri}/$brandId?offset=$offset&limit=12');
    if (response.statusCode == 200) {
       brandItemModel = ItemModel.fromJson(response.body);
    }
    return brandItemModel;
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

  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

}