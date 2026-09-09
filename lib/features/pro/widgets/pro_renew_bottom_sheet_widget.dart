import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProRenewBottomSheetWidget extends StatelessWidget {
  const ProRenewBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: isDesktop ? 450 : MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(Dimensions.radiusExtraLarge),
          topRight: const Radius.circular(Dimensions.radiusExtraLarge),
          bottomLeft: Radius.circular(isDesktop ? Dimensions.radiusExtraLarge : 0),
          bottomRight: Radius.circular(isDesktop ? Dimensions.radiusExtraLarge : 0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: isDesktop ? const SizedBox() : Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
          const Text('🔔', style: TextStyle(fontSize: 60)),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'renew_your_subscription'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'renew_subscription_message'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed(RouteHelper.getSubscriptionPlanRoute());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffA16BFF),
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                elevation: 0,
              ),
              child: Text('renew_subscription'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white)),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ],
      ),
    );
  }
}
