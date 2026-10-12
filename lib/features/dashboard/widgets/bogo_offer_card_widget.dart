import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/bogo_offer/controllers/bogo_offer_controller.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoOfferCardWidget extends StatelessWidget {
  final bool bordered;

  /// Overrides the default destination — the store screen opens that store's own offers
  /// rather than the module-wide list.
  final VoidCallback? onTap;

  const BogoOfferCardWidget({super.key, this.bordered = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BogoOfferController>(builder: (bogoOfferController) {
      final BogoHomeModel? bogoHome = bogoOfferController.bogoHomeModel;
      if(bogoHome?.isLive != true) {
        return const SizedBox.shrink();
      }

      final String title = 'hurry_up_bogo_offer_is_live'.tr;
      final String description = 'buy_more_and_enjoy_exclusive_free_items'.tr;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,
        ),
        child: CustomInkWell(
          onTap: onTap ?? () => Get.toNamed(RouteHelper.getBogoOfferRoute(moduleId: Get.find<SplashController>().module?.id)),
          radius: Dimensions.radiusLarge,
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: bordered ? null : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              border: bordered ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)) : null,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            child: Row(children: [
              const CustomAssetImageWidget(Images.bogoOfferIcon, height: 40, width: 40),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    const SizedBox(height: 2),
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              Icon(Icons.arrow_forward, color: Theme.of(context).textTheme.bodyLarge!.color, size: 20),
            ]),
          ),
        ),
      );
    });
  }
}
