import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';
import 'package:sixam_mart/features/coupon/domain/repositories/coupon_repository_interface.dart';
import 'package:sixam_mart/features/coupon/domain/services/coupon_service_interface.dart';

class CouponService implements CouponServiceInterface{
  final CouponRepositoryInterface couponRepositoryInterface;
  CouponService({required this.couponRepositoryInterface});

  @override
  Future<List<CouponModel>?> getCouponList({int? customerId, int? storeId}) async {
    return await couponRepositoryInterface.getList(couponList: true, customerId: customerId, storeId: storeId);
  }

  @override
  Future<List<CouponModel>?> getTaxiCouponList() async {
    return await couponRepositoryInterface.getList(taxiCouponList: true);
  }

  @override
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID, double? orderAmount) async {
    return await couponRepositoryInterface.applyCoupon(couponCode, storeID, orderAmount);
  }

  @override
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId) async {
    return await couponRepositoryInterface.applyTaxiCoupon(couponCode, providerId);
  }

}