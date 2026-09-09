import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/offer_card_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodItemCard extends StatelessWidget {
  final Item data;
  final double width;
  final bool inStore;
  final bool isCampaign;
  final bool isFeatured;
  final int? index;

  const FoodItemCard({super.key,
    required this.data, required this.width, this.inStore = false, this.isCampaign = false, this.isFeatured = false, required this.index,
  });

  void _handleTap(BuildContext context) {
    if(isFeatured && Get.find<SplashController>().moduleList != null) {
      for(ModuleModel module in Get.find<SplashController>().moduleList!) {
        if(module.id == data.moduleId) {
          Get.find<SplashController>().setModule(module);
          break;
        }
      }
    }
    Get.find<ItemController>().navigateToItemPage(data, context, inStore: inStore, isCampaign: isCampaign, );
  }

  Widget _tagWidget(BuildContext context, String image) {
    return Container(
      height: 24, width: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.only(right: 5),
      child: CustomAssetImageWidget(image, fit: BoxFit.fill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final bool showHalal = (data.isStoreHalalActive ?? false) && (data.isHalalItem ?? false);
    final bool showOrganic = (data.organic == 1 && data.moduleType == 'grocery');
    final bool showVeg = Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg! && data.veg == 1;
    // final bool showNonVeg = Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg! && data.veg == 0;
    final bool isAvailable = DateConverter.isAvailable(data.availableTimeStarts, data.availableTimeEnds);

    return CustomInkWell(
      onTap: () => _handleTap(context),
      radius: 22,
      child: SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge-2),
                    child: CustomImage(image: data.imageFullUrl ?? ''),
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(children: [
                    if(showHalal) _tagWidget(context, Images.halalTag),
                    if(showOrganic) _tagWidget(context, Images.organicTag),
                    if(showVeg) _tagWidget(context, Images.vegTag),
                    // if(showNonVeg) _tagWidget(context, Images.nonVegTag),

                  ]),
                ),

                Positioned(
                  right: Dimensions.paddingSizeSmall,
                  bottom: Dimensions.paddingSizeSmall,
                  child: CartCountView(
                    item: data, index: index,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.add, size: 22),
                    ),
                  ),
                ),

                if(!isAvailable) const NotAvailableWidget(radius: Dimensions.radiusLarge),

                AddFavouriteView(
                  top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                  item: data, storeId: null, size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StoreVerifiedAvatar(
                      imageUrl: data.storeLogoFullUrl ?? data.storeImageFullUrl ?? '',
                      isVerified: data.verifiedSeller == 1,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        data.storeName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).hintColor,
                          fontSize: Dimensions.fontSizeSmall,
                          height: 130 * 0.01,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if(data.avgRating! > 0)...[
                      Icon(
                        Icons.star_rounded,
                        size: Dimensions.fontSizeSmall,
                        color: const Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data.avgRating?.toStringAsFixed(1)?? '0.0',
                        style: robotoMedium.copyWith(
                          color: titleColor,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ]
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  data.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
                    fontSize: Dimensions.fontSizeDefault,
                    height: 110 * 0.01,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8, alignment: WrapAlignment.start,
                  children: [
                    Text(
                      PriceConverter.convertPrice(data.price, discount: data.discount, discountType: data.discountType),
                      style: robotoBold.copyWith(
                        color: titleColor,
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    if (data.discount != null && data.discount! > 0)
                      Text(
                        PriceConverter.convertPrice(data.price),
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).disabledColor,
                          fontSize: Dimensions.fontSizeSmall,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),

                ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Wrap(spacing: Dimensions.paddingSizeExtraSmall, runSpacing: Dimensions.paddingSizeExtraSmall, children: [
                    if(data.discount != null && data.discount != 0.0) OfferCardWidget(label: '-${data.discount}${data.discountType == "percent" ? "%" : "\$"}', isHilight: true,),
                    if(data.freeDelivery ?? false) const OfferCardWidget(label: 'Free',iconData: Icons.pedal_bike_rounded,),
                    if(data.offerLabel != null) OfferCardWidget(label: data.offerLabel! ,iconData: Icons.discount_outlined,),
                  ]),
                ],
              ],
            ),
          ),

        ],
      ),
      ),
    );
  }
}
