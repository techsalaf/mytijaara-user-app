import 'dart:convert';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_cancellation_reasons_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_instruction_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_tier_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/video_content_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/why_choose_model.dart';
import 'package:sixam_mart/features/parcel/domain/repositories/parcel_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ParcelRepository implements ParcelRepositoryInterface {
  final ApiClient apiClient;
  ParcelRepository({required this.apiClient});

  @override
  Future<Response> getPlaceDetails(String? placeID) async {
    return await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$placeID');
  }

  @override
  Future get(String? id, {bool isVideoDetails = true, DataSourceEnum source = DataSourceEnum.client}) async {
    if(isVideoDetails) {
      return await _getVideoContentDetails(source: source);
    } else {
      return await _getWhyChooseDetails(source: source);
    }
  }

  Future<VideoContentModel?> _getVideoContentDetails({required DataSourceEnum source}) async {
    VideoContentModel? videoContentDetails;
    final int? moduleId = Get.find<SplashController>().module?.id;
    String cacheId = '${AppConstants.videoContentUri}-${moduleId ?? 0}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.videoContentUri);
        if(response.statusCode == 200) {
          videoContentDetails = VideoContentModel.fromJson(response.body);
          LocalClient.organize(source, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          videoContentDetails = VideoContentModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
    }
    return videoContentDetails;
  }

  Future<WhyChooseModel?> _getWhyChooseDetails({required DataSourceEnum source}) async {
    WhyChooseModel? whyChooseDetails;
    final int? moduleId = Get.find<SplashController>().module?.id;
    String cacheId = '${AppConstants.whyChooseUri}-${moduleId ?? 0}';

    switch(source) {
      case DataSourceEnum.client:
        Response response = await apiClient.getData(AppConstants.whyChooseUri);
        if(response.statusCode == 200) {
          whyChooseDetails = WhyChooseModel.fromJson(response.body);
          LocalClient.organize(source, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          whyChooseDetails = WhyChooseModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
    }
    return whyChooseDetails;
  }

  @override
  Future getList({int? offset, bool parcelCategory = true}) async {
    if(parcelCategory) {
     return await _getParcelCategory();
    } else {
      return await _getParcelInstruction(offset!);
    }
  }

  Future<List<ParcelCategoryModel>?> _getParcelCategory() async {
    List<ParcelCategoryModel>? parcelCategoryList;
    Response response = await apiClient.getData(AppConstants.parcelCategoryUri);
    if(response.statusCode == 200) {
      parcelCategoryList = [];
      for (final dynamic parcel in ResponseParser.listOrEmpty(response.body)) {
        parcelCategoryList.add(ParcelCategoryModel.fromJson(parcel));
      }
    }
    return parcelCategoryList;
  }

  Future<List<Data>?> _getParcelInstruction(int offset) async {
    List<Data>? parcelInstructionList;
    Response response = await apiClient.getData('${AppConstants.parcelInstructionUri}?limit=10&offset=$offset');
    if(response.statusCode == 200) {
      parcelInstructionList = [];
      parcelInstructionList.addAll(ParcelInstructionModel.fromJson(response.body).data!);
    }
    return parcelInstructionList;
  }

  @override
  Future<ParcelCancellationReasonsModel?> getParcelCancellationReasons({required bool isBeforePickup}) async {
    ParcelCancellationReasonsModel? cancellationReasonsModel;
    Response response = await apiClient.getData('${AppConstants.getParcelCancellationReasons}?limit=25&offset=1&user_type=customer&cancellation_type=${isBeforePickup ? 'before_pickup' : 'after_pickup'}');
    if(response.statusCode == 200){
      cancellationReasonsModel = ParcelCancellationReasonsModel.fromJson(response.body);
    }
    return cancellationReasonsModel;
  }

  /// The weight bands this `(zone, module)` prices by.
  ///
  /// `zone_id` is required and **singular** — a delivery rule is looked up for
  /// exactly one zone, while the `zoneId` header carries a list wherever zones
  /// overlap. `module_id` is sent explicitly rather than left to the `moduleId`
  /// header for the same reason as `delivery-charge/coverage-list`: the header
  /// is not enforced on this path, and the wrong module resolves a different rule.
  ///
  /// `handleError: false` because an empty or switched-off tier is an ordinary
  /// answer, not something to pop a snackbar at the customer over.
  @override
  Future<ParcelTierListModel<ParcelWeightModel>?> getParcelWeightList({required int zoneId, int? moduleId}) async {
    return await _getParcelTierList(
      AppConstants.parcelWeightUri, zoneId, moduleId, ParcelWeightModel.fromJson,
    );
  }

  @override
  Future<ParcelTierListModel<ParcelDimensionModel>?> getParcelDimensionList({required int zoneId, int? moduleId}) async {
    return await _getParcelTierList(
      AppConstants.parcelDimensionUri, zoneId, moduleId, ParcelDimensionModel.fromJson,
    );
  }

  Future<ParcelTierListModel<T>?> _getParcelTierList<T>(String uri, int zoneId, int? moduleId,
      T Function(Map<String, dynamic>) rowFromJson) async {
    final String moduleQuery = moduleId != null ? '&module_id=$moduleId' : '';
    final Response response = await apiClient.getData('$uri?zone_id=$zoneId$moduleQuery', handleError: false);
    if (response.statusCode == 200 && response.body is Map) {
      return ParcelTierListModel<T>.fromJson(Map<String, dynamic>.from(response.body as Map), rowFromJson);
    }
    return null;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

}
