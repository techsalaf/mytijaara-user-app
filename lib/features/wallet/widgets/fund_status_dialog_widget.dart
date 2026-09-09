import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class FundStatusDialogWidget extends StatelessWidget {
  final bool isSuccess;
  const FundStatusDialogWidget({super.key, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isSuccess ? Colors.green : Colors.red;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Container(
        width: ResponsiveHelper.isDesktop(context) ? 380 : double.infinity,
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeLarge, Dimensions.paddingSizeExtraLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          Container(
            height: 70, width: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.1),
            ),
            child: CustomAssetImageWidget(
              isSuccess ? Images.checkGif : Images.cancelGif,
              height: 60, width: 60, fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(
            isSuccess ? 'fund_added_successfully'.tr : 'fund_add_failed'.tr,
            textAlign: TextAlign.center,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: statusColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Text(
              isSuccess ? 'your_fund_has_been_added_to_your_wallet_successfully'.tr
                  : 'sorry_we_could_not_add_fund_to_your_wallet_please_try_again'.tr,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor, height: 1.5),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          CustomButton(
            buttonText: isSuccess ? 'done'.tr : 'try_again'.tr,
            color: statusColor,
            radius: Dimensions.radiusDefault,
            height: 45,
            onPressed: () => Get.back(),
          ),
        ]),
      ),
    );
  }
}
