import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';
import 'package:sixam_mart/features/coupon/domain/repositories/coupon_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class CouponRepository implements CouponRepositoryInterface {
  final ApiClient apiClient;
  CouponRepository({required this.apiClient});

  @override
  Future getList({int? offset, bool couponList = false, bool taxiCouponList = false, int? customerId, int? storeId}) async {
    if(couponList) {
      return await _getCouponList(customerId: customerId, storeId: storeId);
    } else if(taxiCouponList) {
      return await _getTaxiCouponList();
    }
  }

  Future<List<CouponModel>?> _getCouponList({int? customerId, int? storeId}) async {
    List<CouponModel>? couponList;
    // Send customer_id / store_id only when provided (checkout passes them).
    final List<String> queryParams = [];
    if (customerId != null) queryParams.add('customer_id=$customerId');
    if (storeId != null) queryParams.add('store_id=$storeId');
    final String query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    Response response = await apiClient.getData('${AppConstants.couponUri}$query');
    if (response.statusCode == 200) {
      couponList = [];
      response.body.forEach((category) {
        CouponModel coupon = CouponModel.fromJson(category);
        coupon.toolTip = JustTheController();
        couponList!.add(coupon);
      });
    }
    return couponList;
  }

  Future<List<CouponModel>?> _getTaxiCouponList() async {
    List<CouponModel>? taxiCouponList;
    Response response = await apiClient.getData(AppConstants.taxiCouponUri);
    if (response.statusCode == 200) {
      taxiCouponList = [];
      response.body.forEach((category) => taxiCouponList!.add(CouponModel.fromJson(category)));
    }
    return taxiCouponList;
  }

  @override
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID, double? orderAmount) async {
    CouponModel? couponModel;
    Response response = await apiClient.getData('${AppConstants.couponApplyUri}$couponCode&store_id=$storeID&order_amount=$orderAmount');
    if (response.statusCode == 200) {
      couponModel = CouponModel.fromJson(response.body);
    }
    return couponModel;
  }

  @override
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId) async {
    CouponModel? taxiCouponModel;
    Response response = await apiClient.getData('${AppConstants.taxiCouponApplyUri}$couponCode&provider_id=$providerId');
    if (response.statusCode == 200) {
      taxiCouponModel = CouponModel.fromJson(response.body);
    }
    return taxiCouponModel;
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