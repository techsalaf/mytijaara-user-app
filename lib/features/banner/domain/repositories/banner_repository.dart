import 'dart:convert';
import 'package:sixam_mart/api/response_parser.dart';

import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:sixam_mart/features/banner/domain/repositories/banner_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/header_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class BannerRepository implements BannerRepositoryInterface {
  final ApiClient apiClient;
  BannerRepository({required this.apiClient});

  @override
  Future getList({int? offset, bool isBanner = false, bool isTaxiBanner = false, bool isFeaturedBanner = false, bool isParcelOtherBanner = false, bool isPromotionalBanner = false, DataSourceEnum? source}) async {
    if (isBanner) {
      return await _getBannerList(source: source!);
    } else if (isTaxiBanner) {
      return await _getTaxiBannerList();
    } else if (isFeaturedBanner) {
      return await _getFeaturedBannerList();
    } else if (isParcelOtherBanner) {
      return await _getParcelOtherBannerList();
    } else if (isPromotionalBanner) {
      return await _getPromotionalBannerList();
    }
  }

  Future<BannerModel?> _getBannerList({required DataSourceEnum source}) async {
    BannerModel? bannerModel;
    String cacheId = '${AppConstants.bannerUri}-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.bannerUri, moduleScoped: true);
        if (response.statusCode == 200) {
          bannerModel = BannerModel.fromJson(response.body);
          LocalClient.organize(source, cacheId, response.bodyString ?? '', apiClient.getHeader());

        }
      case DataSourceEnum.local:

        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          bannerModel = BannerModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
    }


    return bannerModel;
  }

  Future<BannerModel?> _getTaxiBannerList() async {
    BannerModel? bannerModel;
    Response response = await apiClient.getData(AppConstants.taxiBannerUri);
    if (response.statusCode == 200) {
      bannerModel = BannerModel.fromJson(response.body);
    }
    return bannerModel;
  }

  Future<BannerModel?> _getFeaturedBannerList() async {
    BannerModel? bannerModel;
    Response response = await apiClient.getData('${AppConstants.bannerUri}?featured=1', headers: HeaderHelper.featuredHeader());
    if (response.statusCode == 200) {
      bannerModel = BannerModel.fromJson(response.body);
    }
    return bannerModel;
  }

  Future<ParcelOtherBannerModel?> _getParcelOtherBannerList() async {
    ParcelOtherBannerModel? parcelOtherBannerModel;
    Response response = await apiClient.getData(AppConstants.parcelOtherBannerUri);
    if (response.statusCode == 200) {
      parcelOtherBannerModel = ParcelOtherBannerModel.fromJson(response.body);
    }
    return parcelOtherBannerModel;
  }

  Future<PromotionalBanner?> _getPromotionalBannerList() async {
    Response response = await apiClient.getData(AppConstants.promotionalBannerUri, moduleScoped: true);
    // Any 2xx is a parseable answer, whatever shape it arrived in — the food
    // module returns a bare `[]` for "no banner configured", and gating on
    // `body is Map` dropped that as if the request had failed, leaving the view
    // shimmering. Null is now reserved for a genuine failure.
    if (!ApiClient.isSuccessCode(response.statusCode)) {
      return null;
    }
    return PromotionalBanner.fromResponse(response.body);
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