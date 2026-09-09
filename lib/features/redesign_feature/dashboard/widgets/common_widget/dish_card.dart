import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/offer_card_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class DishCard extends StatelessWidget {
  final Item item;
  final double? width;
  final bool isBorder;
  final int index;
  const DishCard({super.key, required this.item, this.width, this.isBorder = false, required this.index});

  @override
  Widget build(BuildContext context) {
    final double? startingPrice = Get.find<ItemController>().getStartingPrice(item);
    final bool hasDiscount = (item.discount ?? 0) > 0;
    final String currentPrice = PriceConverter.convertPrice(
      startingPrice, discount: item.discount, discountType: item.discountType,
    );
    final String previousPrice = hasDiscount ? PriceConverter.convertPrice(startingPrice) : '';
    final String? discountLabel = hasDiscount
        ? PriceConverter.percentageCalculation('${startingPrice ?? 0}', '${item.discount}', item.discountType ?? 'percent')
        : null;
    final String storeName = item.storeName ?? '';
    final String title = item.name ?? '';
    final bool showHalal = (item.isStoreHalalActive ?? false) && (item.isHalalItem ?? false);

    return Container(
      width: width,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: isBorder ? Border.all(color: Theme.of(context).disabledColor.withAlpha(50)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall,
                vertical: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      StoreVerifiedAvatar(
                        imageUrl: item.storeImageFullUrl ?? item.storeLogoFullUrl,
                        isVerified: item.verifiedSeller == 1,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          storeName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoSemiBold.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, height: 1.15),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall-2.5),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: Dimensions.paddingSizeExtraSmall, mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          currentPrice,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                        if (previousPrice.isNotEmpty) ...[
                          // const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            previousPrice,
                            style: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                              fontSize: Dimensions.fontSizeExtraSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  if (discountLabel != null) OfferCardWidget(label: discountLabel, isHilight: true),
                ],
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          _TrendingDishPreview(imageUrl: item.imageFullUrl ?? '', showHalal: showHalal, item: item, index: index),
        ],
      ),
    );
  }
}

class _TrendingDishPreview extends StatelessWidget {
  final String imageUrl;
  final bool showHalal;
  final Item item;
  final int index;
  const _TrendingDishPreview({required this.imageUrl, required this.showHalal, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = DateConverter.isAvailable(item.availableTimeStarts, item.availableTimeEnds);

    return Container(
      width: 126,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
              child: CustomImage(image: imageUrl, fit: BoxFit.cover),
            ),
          ),

          // is halal
          if (showHalal) Positioned(
            top: 10, left: 10,
            child: Container(
              height: 18, width: 18,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SvgPicture.asset(Images.halalTag),
            ),
          ),

          // add button
          Positioned(
            right: 8, bottom: 8,
            child: CartCountView(
              item: item, index: index,
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

          if(!isAvailable) const NotAvailableWidget(radius: Dimensions.radiusMedium),

          AddFavouriteView(
            top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
            item: item, storeId: null, size: 18,
          ),
        ],
      ),
    );
  }
}
