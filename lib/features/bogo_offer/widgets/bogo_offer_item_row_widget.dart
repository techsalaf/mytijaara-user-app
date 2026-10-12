import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/avg_review_widget.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';


class BogoOfferItemRowWidget extends StatelessWidget {
  const BogoOfferItemRowWidget({super.key, required this.offerItem, this.padding});

  final BogoOfferItemModel offerItem;
  final EdgeInsetsGeometry? padding;
  static const double _imageSize = 115;

  @override
  Widget build(BuildContext context) {
    final Item item = offerItem.item;
    final double price = item.price ?? 0;
    final double discount = item.discount ?? 0;
    final String discountType = item.discountType ?? 'percent';
    final double discountedPrice = PriceConverter.convertWithDiscount(price, discount, discountType) ?? price;

    final bool isAvailable = DateConverter.isAvailable(item.availableTimeStarts, item.availableTimeEnds);
    final bool showHalal = item.isStoreHalalActive == true && item.isHalalItem == true;
    final bool showVeg = (Get.find<SplashController>().configModel?.toggleVegNonVeg ?? false) && item.veg == 1;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              AvgReviewWidget(avgRating: item.avgRating ?? 0, ratingCount: item.ratingCount ?? 0),
              if(AvgReviewWidget.showRating(item.avgRating ?? 0)) const SizedBox(height: Dimensions.paddingSizeExtraSmall),
    
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Dimensions.paddingSizeSmall,
                children: offerItem.isFree ? [
                  Text(PriceConverter.convertPrice(price), textDirection: TextDirection.ltr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).disabledColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Theme.of(context).disabledColor,
                    ),
                  ),
    
                  Text('free'.tr, style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).colorScheme.error)),
                ] : [
                  Text(PriceConverter.convertPrice(discountedPrice), textDirection: TextDirection.ltr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
    
                  if(discountedPrice < price) Text(
                    PriceConverter.convertPrice(price), textDirection: TextDirection.ltr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
    
              if(offerItem.variationText.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(offerItem.variationText, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              ],
    
              if(offerItem.addOnText.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('${'addons'.tr} : ${offerItem.addOnText}', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              ],

              const SizedBox(height: Dimensions.paddingSizeSmall),

               Text('${'qty'.tr} : ${offerItem.quantity}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
            ]),
          ),
        ),
    
        SizedBox(
          width: _imageSize, height: _imageSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              Positioned.fill(
                child: CustomImage(
                  image: item.imageFullUrl ?? '', fit: BoxFit.cover, width: double.infinity, height: double.infinity, placeholder: Images.placeholder,
                  cacheWidth: ImageCacheHelper.pixels(context, _imageSize),
                ),
              ),
    
              Positioned(top: 8, left: 8,
                child: Row(children: [
                  if(showHalal) const _ImageRoundBadge(assetPath: Images.halalTag),
                  if(showHalal && showVeg) const SizedBox(width: 5),
                  if(showVeg) const _ImageRoundBadge(assetPath: Images.vegTag),
                ]),
              ),
    
              Positioned(top: 8, right: 8,
                child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                  final bool isWished = favouriteController.wishItemIdList.contains(item.id);
                  return _CardCircleButton(size: 28, child: CustomFavouriteWidget(item: item, isWished: isWished, size: 21));
                }),
              ),
    
              if(!isAvailable) const NotAvailableWidget(isStore: false, radius: 12),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ImageRoundBadge extends StatelessWidget {
  final String assetPath;
  const _ImageRoundBadge({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26, width: 26,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: CustomAssetImageWidget(assetPath),
    );
  }
}

class _CardCircleButton extends StatelessWidget {
  final Widget child;
  final double size;
  const _CardCircleButton({required this.child, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 3),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}
