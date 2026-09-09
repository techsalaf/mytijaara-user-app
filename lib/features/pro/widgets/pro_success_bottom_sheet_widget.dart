import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProSuccessBottomSheetWidget extends StatelessWidget {
  final bool isRenewalMode;
  const ProSuccessBottomSheetWidget({super.key, this.isRenewalMode = false});

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Dimensions.paddingSizeSmall),
          isDesktop ? const SizedBox() : Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: const BoxDecoration(color: Color(0xFFFF8C00), shape: BoxShape.circle),
            child: Image.asset(Images.proPlanCrown, width: 40, height: 40, color: Colors.white),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            isRenewalMode ? 'pro_plan_renewed_successfully'.tr : 'you_are_now_a_pro_member'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
            child: Text(
              'pro_member_welcome_message'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ],
      ),
    );
  }
}
