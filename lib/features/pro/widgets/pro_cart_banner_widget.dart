import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/screens/subscription_plan_screen.dart';
import 'package:sixam_mart/features/pro/widgets/pro_benefit_banner_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_plan_banner_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

class ProCartBannerWidget extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double couponDiscount;
  final String? redirectRoute;
  // Promo mode for screens without a cart/subtotal yet — see ProBenefitBannerWidget.
  const ProCartBannerWidget({super.key,
    required this.subtotal, this.discount = 0, this.couponDiscount = 0, this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SplashController>().proStaus) return const SizedBox();
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isPro = profileController.userInfoModel?.proStatus ?? false;
      if (!isPro) {
        return ProPlanBannerWidget(onSubscribe: () {
          Get.find<ProController>().saveCurrentPath(route: redirectRoute);
          SubscriptionPlanScreen.open();
        });
      }
      return GetBuilder<ProController>(builder: (proController) {
        final ProActiveBenefit? benefit = proController.activeOfferModel?.benefit;
        if (benefit == null || !proController.isBenefitAllowedForCurrentModule(benefit.type)) return const SizedBox();
        return ProBenefitBannerWidget(benefit: benefit, subtotal: subtotal, discount: discount, couponDiscount: couponDiscount,);
      });
    });
  }
}
