import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';

abstract class CouponServiceInterface{
  Future<List<CouponModel>?> getCouponList({int? customerId, int? storeId});
  Future<List<CouponModel>?> getTaxiCouponList();
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID, double? orderAmount);
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId);
}