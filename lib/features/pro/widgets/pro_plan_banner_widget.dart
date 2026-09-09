import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ProPlanBannerWidget extends StatelessWidget {
  final VoidCallback? onSubscribe;
  const ProPlanBannerWidget({super.key, this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SplashController>().proStaus) return const SizedBox();

    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool hasProPlan = profileController.userInfoModel?.proStatus ?? false;

      return GetBuilder<ProController>(builder: (proController) {
        final ProActiveBenefit? benefit = proController.activeOfferModel?.benefit;

        // Pro member with no active offer applicable to this module — show nothing.
        if (hasProPlan && !proController.isBenefitAllowedForCurrentModule(benefit?.type)) {
          return const SizedBox();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF4B6CE0),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
          child: Row(children: [

            Container(
              height: 32, width: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFC107)),
              child: Image.asset(Images.proPlanCrown, fit: BoxFit.contain),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: RichText(
                text: TextSpan(
                  text: hasProPlan
                      ? '${'order_now_to_enjoy_exclusive_offer_with_your'.tr} '
                      : '${'enjoy_extra_savings_on_every_order_with_a'.tr} ',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
                  children: [
                    TextSpan(
                      text: 'pro_plan'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
                    ),
                    if (hasProPlan && benefit?.type != null)
                      TextSpan(
                        text: ' - ${_benefitName(benefit!.type)} ${'benefit_unlocked'.tr}',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),

            if (!hasProPlan) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              InkWell(
                onTap: onSubscribe,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('explore'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white)),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ]),
              ),
            ],

          ]),
        );
      });
    });
  }

  String _benefitName(ProBenefitType? type) {
    switch (type) {
      case ProBenefitType.discount:
        return 'pro_discount'.tr;
      case ProBenefitType.deliveryFee:
        return 'pro_delivery_fee'.tr;
      case ProBenefitType.coupon:
        return 'pro_coupon'.tr;
      case null:
        return 'pro_benefit'.tr;
    }
  }
}
