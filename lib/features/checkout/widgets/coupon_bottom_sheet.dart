import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/coupon/widgets/coupon_card_widget.dart';

class CouponBottomSheet extends StatefulWidget {
  final int? storeId;
  final CheckoutController checkoutController;
  final Future<bool> Function(String code)? onCouponSelected;
  const CouponBottomSheet({super.key, required this.storeId, required this.checkoutController, this.onCouponSelected});

  @override
  State<CouponBottomSheet> createState() => _CouponBottomSheetState();
}

class _CouponBottomSheetState extends State<CouponBottomSheet> {
  /// An apply request is in flight — repeat taps are ignored so the API is hit once.
  bool _applying = false;

  /// This sheet has already been popped — makes the close idempotent, so a late
  /// response can never pop the checkout screen sitting underneath.
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimensions.webMaxWidth,
      margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context) ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : const BorderRadius.all(Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeLarge),
        child: Column(children: [

          !ResponsiveHelper.isDesktop(context) ? Container(
            height: 4, width: 35,
            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: Theme.of(context).disabledColor, borderRadius: BorderRadius.circular(10)),
          ) : const SizedBox(),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('available_promo'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            IconButton(
              onPressed: ()=> Get.back(),
              icon: Icon(Icons.clear, color: Theme.of(context).disabledColor),
            )
          ]),

          GetBuilder<CouponController>(builder: (couponController) {
            List<CouponModel>? couponList;
            if(couponController.couponList != null) {
              couponList = [];
              for(CouponModel coupon in couponController.couponList!) {
                if(coupon.storeId == null || (coupon.couponType != 'store_wise' && coupon.couponType != 'default' && coupon.couponType != 'free_delivery') || coupon.storeId == widget.storeId) {
                  couponList.add(coupon);
                }
              }
            }
            return couponList != null ? couponList.isNotEmpty ? GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveHelper.isDesktop(context) ? 3 : ResponsiveHelper.isTab(context) ? 2 : 1,
                mainAxisSpacing: Dimensions.paddingSizeSmall, crossAxisSpacing: Dimensions.paddingSizeSmall,
                childAspectRatio: ResponsiveHelper.isMobile(context) ? 3 : 3,
              ),
              itemCount: couponList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    if (_applying || _closed) return;
                    final String? code = couponList![index].code;
                    if (code == null) return;

                    /// Pop this sheet's own route only — `navigator.mounted` stays true
                    /// after the sheet closes, so it would pop the page underneath.
                    final NavigatorState navigator = Navigator.of(context);
                    final ModalRoute<dynamic>? route = ModalRoute.of(context);

                    if (widget.onCouponSelected == null) {
                      widget.checkoutController.couponController.text = code;
                      _closed = true;
                      if (route?.isCurrent ?? false) navigator.pop();
                      return;
                    }

                    _applying = true;
                    bool ok = false;
                    try {
                      ok = await widget.onCouponSelected!(code);
                    } finally {
                      _applying = false;
                    }

                    if (!ok || _closed || !mounted) return;
                    _closed = true;
                    if (route?.isCurrent ?? false) navigator.pop();
                  },
                  child: CouponCardWidget(coupon: couponList![index], index: index),
                );
              },
            ) : Column(children: [
              Image.asset(Images.noCoupon, height: 70),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text('no_promo_available'.tr, style: robotoMedium),
              const SizedBox(height: 50),
            ]) : const Center(child: CircularProgressIndicator());
          })

        ]),
      ),
    );
  }
}
