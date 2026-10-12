import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/review/domain/models/review_body_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_model.dart';
import 'package:sixam_mart/features/review/domain/repositories/review_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ReviewRepository implements ReviewRepositoryInterface {
  final ApiClient apiClient;
  ReviewRepository({required this.apiClient});

  @override
  Future<StoreReviewModel?> getList({int? offset, String? storeID}) async {
    StoreReviewModel? storeReviewModel;
    // `offset` is a 1-based page number here, as everywhere else in this API. Sending it
    // with an explicit `limit` is what makes the pages beyond the default 25 reachable.
    Response response = await apiClient.getData(
      '${AppConstants.storeReviewUri}?store_id=$storeID&offset=${offset ?? 1}&limit=10',
    );
    if (ApiClient.isSuccessCode(response.statusCode) && response.body is Map<String, dynamic>) {
      storeReviewModel = StoreReviewModel.fromJson(response.body);
    }
    return storeReviewModel;
  }

  @override
  Future<ResponseModel> submitReview(ReviewBodyModel reviewBody) async {
    ResponseModel responseModel;
    Response response = await apiClient.postData(AppConstants.reviewUri, reviewBody.toJson(), handleError: false);
    // This endpoint answers `201 Created`; a plain `== 200` check read every accepted
    // review as a failure and put a red snackbar over a review the server had stored.
    if (ApiClient.isSuccessCode(response.statusCode)) {
      responseModel = ResponseModel(true, 'review_submitted_successfully'.tr);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  Future<ResponseModel> submitDeliveryManReview(ReviewBodyModel reviewBody) async {
    ResponseModel responseModel;
    Response response = await apiClient.postData(AppConstants.deliveryManReviewUri, reviewBody.toJson(), handleError: false);
    // Same endpoint family, same `201` — and the same screen submits it.
    if (ApiClient.isSuccessCode(response.statusCode)) {
      responseModel = ResponseModel(true, 'review_submitted_successfully'.tr);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
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