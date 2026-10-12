import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_body_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/review/domain/services/review_service_interface.dart';

class ReviewController extends GetxController implements GetxService {
  final ReviewServiceInterface reviewServiceInterface;
  ReviewController({required this.reviewServiceInterface});

  List<ReviewModel>? _storeReviewList;
  List<ReviewModel>? get storeReviewList => _storeReviewList;

  /// Paging metadata from the response, so the list can reach past the first page.
  int? _storeReviewTotalSize;
  int? get storeReviewTotalSize => _storeReviewTotalSize;

  int _storeReviewOffset = 1;
  int get storeReviewOffset => _storeReviewOffset;

  final List<int> _storeReviewOffsetList = <int>[];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<int> _ratingList = [];
  List<int> get ratingList => _ratingList;

  List<String> _reviewList = [];
  List<String> get reviewList => _reviewList;

  List<bool> _loadingList = [];
  List<bool> get loadingList => _loadingList;

  List<bool> _submitList = [];
  List<bool> get submitList => _submitList;

  int _deliveryManRating = 0;
  int get deliveryManRating => _deliveryManRating;

  /// Loads a page of a store's reviews.
  ///
  /// `offset` is the 1-based page number. Page 1 replaces the list (a fresh open or a
  /// pull-to-refresh); later pages append. The response's `pagination` block is kept so
  /// the screen knows whether more pages exist — it used to be thrown away, which
  /// capped the screen at the endpoint's default page size.
  Future<void> getStoreReviewList(String? storeID, {int offset = 1}) async {
    if (offset == 1) {
      _storeReviewList = null;
      _storeReviewOffsetList.clear();
      _storeReviewTotalSize = null;
      update();
    } else if (_storeReviewOffsetList.contains(offset)) {
      return;
    }
    _storeReviewOffsetList.add(offset);

    final StoreReviewModel? response = await reviewServiceInterface.getStoreReviewList(storeID, offset: offset);
    if (response != null) {
      _storeReviewTotalSize = response.totalSize;
      _storeReviewOffset = response.offset ?? offset;
      _storeReviewList ??= <ReviewModel>[];
      _storeReviewList!.addAll(response.reviews ?? <ReviewModel>[]);
    } else if (offset == 1) {
      // A failed first page still has to leave the loader, or the screen spins forever.
      _storeReviewList = <ReviewModel>[];
      _storeReviewOffsetList.remove(offset);
    } else {
      _storeReviewOffsetList.remove(offset);
    }
    update();
  }

  void initRatingData(List<OrderDetailsModel> orderDetailsList) {
    _ratingList = [];
    _reviewList = [];
    _loadingList = [];
    _submitList = [];
    _deliveryManRating = 0;
    for (var orderDetails in orderDetailsList) {
      _ratingList.add(0);
      _reviewList.add('');
      _loadingList.add(false);
      _submitList.add(false);
      if (kDebugMode) {
        print(orderDetails);
       }
    }
  }

  void setRating(int index, int rate, {bool notify = true}) {
    _ratingList[index] = rate;
    if(notify) update();
  }

  void setReview(int index, String review, {bool notify = true}) {
    _reviewList[index] = review;
    if (notify) update();
  }

  void setDeliveryManRating(int rate) {
    _deliveryManRating = rate;
    update();
  }

  Future<ResponseModel> submitReview(int index, ReviewBodyModel reviewBody) async {
    _loadingList[index] = true;
    update();
    ResponseModel responseModel = await reviewServiceInterface.submitReview(reviewBody);
    if (responseModel.isSuccess) {
      _submitList[index] = true;
      update();
    }
    _loadingList[index] = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> submitDeliveryManReview(ReviewBodyModel reviewBody) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await reviewServiceInterface.submitDeliveryManReview(reviewBody);
    if (responseModel.isSuccess) {
      _deliveryManRating = 0;
      update();
    }
    _isLoading = false;
    update();
    return responseModel;
  }

}