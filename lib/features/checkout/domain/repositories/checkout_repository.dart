import 'dart:developer';

import 'package:get/get_connect/connect.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/saved_prescription_model.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

import '../../../../common/widgets/custom_snackbar.dart';

class CheckoutRepository implements CheckoutRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  CheckoutRepository({ required this.apiClient, required this.sharedPreferences});

  @override
  Future<int> getDmTipMostTapped() async {
    int mostDmTipAmount = 0;
    Response response = await apiClient.getData(AppConstants.mostTipsUri);
    if (response.statusCode == 200) {
      // The server sends this as a number it may format either way — `10` or `10.0` —
      // and a double assigned straight into an int throws at runtime. Parsing through
      // double covers both, plus a numeric string.
      mostDmTipAmount = double.tryParse('${response.body['most_tips_amount']}')?.round() ?? 0;
    }
    return mostDmTipAmount;
  }

  @override
  Future<bool> saveSharedPrefDmTipIndex(String index) async {
    return await sharedPreferences.setString(AppConstants.dmTipIndex, index);
  }

  @override
  String getSharedPrefDmTipIndex() {
    return sharedPreferences.getString(AppConstants.dmTipIndex) ?? "";
  }

  @override
  Future<Response> getDistanceInMeter(LatLng originLatLng, LatLng destinationLatLng) async {
    return await apiClient.getData(
      '${AppConstants.distanceMatrixUri}?origin_lat=${originLatLng.latitude}&origin_lng=${originLatLng.longitude}'
          '&destination_lat=${destinationLatLng.latitude}&destination_lng=${destinationLatLng.longitude}&mode=WALK',
      handleError: false,
    );
  }

  @override
  Future<double> getExtraCharge(double? distance) async {
    double extraCharge = 0;
    Response response = await apiClient.getData('${AppConstants.vehicleChargeUri}?distance=$distance', handleError: false);
    if (response.statusCode == 200) {
      extraCharge = double.parse(response.body.toString());
    }
    return extraCharge;
  }



  @override
  Future<Response> placeOrder(PlaceOrderBodyModel orderBody, List<MultipartBody>? orderAttachment, List<String>? savedImages) async {
    Map<String, String> body = orderBody.toJson();
    // _attachSavedImages(body, savedImages);
    log("order Attachment (key -> file): ${orderAttachment?.map((e) => '${e.key} -> ${e.file?.name}').toList()}");
    log("Order Body: $body");
    return await apiClient.postMultipartData(AppConstants.placeOrderUri, body, orderAttachment ?? [], handleError: false);
  }

  @override
  Future<Response> placePrescriptionOrder(int? storeId, double? distance, String address, String longitude, String latitude, String note,
      List<MultipartBody> orderAttachment, List<String> savedImages, String dmTips, String deliveryInstruction) async {

    Map<String, String> body = {
      'store_id': storeId.toString(),
      'distance': distance.toString(),
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'order_note': note,
      'dm_tips': dmTips,
      'delivery_instruction': deliveryInstruction,
      'payment_method': 'cash_on_delivery',
      'order_type': 'delivery',
    };
    // _attachSavedImages(body, savedImages);
    return await apiClient.postMultipartData(AppConstants.placePrescriptionOrderUri, body, orderAttachment, handleError: false);
  }

  @override
  Future<List<SavedPrescriptionModel>?> getSavedPrescriptionImages() async {
    Response response = await apiClient.getData(AppConstants.savedFilesUri, handleError: false);
    if (response.statusCode != 200) {
      return null;
    }

    // ApiClient unwraps the envelope to `content` before this point, so the list arrives
    // either still under `saved_files` or as the bare list itself. listOf() takes both —
    // and, unlike naming the key directly, does not throw when the body is a list.
    final List<dynamic>? rawFiles = ResponseParser.listOf(response.body, legacyKey: 'saved_files');
    if (rawFiles == null) {
      log('saved-files: 200 but no list in body -> ${response.body}');
      return null;
    }

    final List<SavedPrescriptionModel> savedFiles = [];
    for (final savedFile in rawFiles) {
      if (savedFile is Map) {
        savedFiles.add(SavedPrescriptionModel.fromJson(Map<String, dynamic>.from(savedFile)));
      }
    }
    return savedFiles;
  }

  @override
  Future<Response> storeSavedPrescriptionImages(List<MultipartBody> images) async {
    final response = await apiClient.postMultipartData(AppConstants.storeSavedFilesUri, {}, images, handleError: false);

    if (response.statusCode == 400 && response.statusText == 'connection_to_api_server_failed'.tr) {
      showCustomSnackBar('max_file_size_2mb'.tr);
      return response;
    }
    return response;
  }

  @override
  Future<Response> deleteSavedPrescriptionImages() async {
    return await apiClient.deleteData(AppConstants.deleteSavedFilesUri, handleError: false);
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
  Future getList({int? offset}) async{
    return await _getOfflineMethodList();
  }

  Future<List<OfflineMethodModel>?> _getOfflineMethodList() async {
    List<OfflineMethodModel>? offlineMethodList;
    Response response = await apiClient.getData(AppConstants.offlineMethodListUri);
    if (response.statusCode == 200) {
      offlineMethodList = [];
      for (final dynamic method in ResponseParser.listOrEmpty(response.body)) {
        offlineMethodList.add(OfflineMethodModel.fromJson(method));
      }
    }
    return offlineMethodList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> getOrderTax(PlaceOrderBodyModel orderBody) async {
    Response response = await apiClient.postData(AppConstants.getOrderTaxUri, orderBody.toJson());
    return response;
  }

  /// The whole checkout quote in one call.
  ///
  /// `handleError: false` on purpose: this refires on every coupon, tip and
  /// address change, so routing failures through [ApiChecker] would pop a
  /// snackbar at the customer on each one. The controller decides which codes
  /// are actionable and silently falls back to the client-side figures for the
  /// rest.
  @override
  Future<Response> getCheckoutSummary(CheckoutSummaryBodyModel body) async {
    return await apiClient.postData(AppConstants.checkoutSummaryUri, body.toJson(), handleError: false);
  }

  /// What the customer must pick from, for a `(zone, module)`.
  ///
  /// `module_id` is sent explicitly rather than left to the `moduleId` header:
  /// the header is not enforced on this path, and a request answered against the
  /// wrong module returns a different rule.
  @override
  Future<CoverageListModel?> getCoverageList({required int zoneId, int? moduleId}) async {
    final String moduleQuery = moduleId != null ? '&module_id=$moduleId' : '';
    final Response response = await apiClient.getData(
      '${AppConstants.deliveryChargeCoverageListUri}?zone_id=$zoneId$moduleQuery',
      handleError: false,
    );
    if (response.statusCode == 200 && response.body is Map) {
      return CoverageListModel.fromJson(Map<String, dynamic>.from(response.body as Map));
    }
    return null;
  }
}
