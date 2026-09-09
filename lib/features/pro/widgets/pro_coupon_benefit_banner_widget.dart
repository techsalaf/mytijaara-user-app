import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ProCouponBenefitBanner extends StatelessWidget {
  final bool? couponApplied;
  const ProCouponBenefitBanner({super.key, this.couponApplied});

  static const Color _green = Color(0xFF22A45D);

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SplashController>().proStaus) return const SizedBox();
    if (Get.find<SplashController>().module?.moduleType == AppConstants.parcel) return const SizedBox();
    if (!(Get.find<ProfileController>().userInfoModel?.proStatus ?? false)) return const SizedBox();

    return GetBuilder<ProController>(builder: (proController) {
      final ProActiveBenefit? benefit = proController.activeOfferModel?.benefit;
      final bool hasCouponBenefit = benefit?.type == ProBenefitType.coupon && proController.isBenefitAllowedForCurrentModule(benefit?.type);
      if (!hasCouponBenefit) return const SizedBox();

      // Rental/rideshare pass their own coupon state; stores fall back to the shared CouponController.
      if (couponApplied != null) {
        return couponApplied! ? const SizedBox() : _banner(context);
      }

      return GetBuilder<CouponController>(builder: (couponController) {
        final bool applied = (couponController.discount ?? 0) > 0 || couponController.coupon != null || couponController.freeDelivery;
        return applied ? const SizedBox() : _banner(context);
      });
    });
  }

  Widget _banner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          color: _green,
          strokeWidth: 1.2,
          dashPattern: [6, 4],
          radius: Radius.circular(Dimensions.radiusDefault),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info, color: _green, size: 22),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'pro_coupon_benefit_available'.tr,
                style: robotoBold.copyWith(color: _green, fontSize: Dimensions.fontSizeSmall),
              ),
              const SizedBox(height: 2),

              Text(
                'apply_your_pro_coupon_above_to_claim_discount_on_this_order'.tr,
                style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}
