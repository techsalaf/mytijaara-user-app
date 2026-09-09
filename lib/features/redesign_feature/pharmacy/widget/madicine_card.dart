import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MadicineCardWidget extends StatelessWidget {
  final Item item;
  final double width;
  final bool isBorder;

  const MadicineCardWidget({super.key, required this.item, required this.width, this.isBorder = false});

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
    final String? phrmaName = (item.genericName != null && item.genericName!.isNotEmpty) ? item.genericName!.first : null;
    final String storeName = item.storeName ?? '';
    final String title = item.name ?? '';
    final String? packType = item.unitType;
    final bool freeDelivery = item.freeDelivery ?? false;

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
                        imageUrl: item.storeLogoFullUrl ?? item.storeImageFullUrl,
                        isVerified: item.verifiedSeller == 1,
                        size: 18,
                      ),
                      const SizedBox(width: 6),

                      Flexible(
                        child: Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoSemiBold.copyWith(
                            color: Theme.of(context).disabledColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      height: 1.15,
                    ),
                  ),

                  if(phrmaName != null)
                    Text(phrmaName, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),

                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          currentPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      ),
                      if(previousPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            previousPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),

                  if(packType != null) FittedBox(
                    child: Text(packType, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          _TrendingDishPreview(item: item),
        ],
      ),
    );
  }
}

class _TrendingDishPreview extends StatelessWidget {
  final Item item;

  const _TrendingDishPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    double? discount = item.discount;
    String? discountType = item.discountType;
    return Container(
      width: 120,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Theme.of(context).disabledColor, width: 0.15),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(image: item.imageFullUrl??'', fit: BoxFit.cover),
            ),
          ),

          AddFavouriteView(item: item, top: 5, right: 10),

          DiscountTag(
            discount: discount,
            discountType: discountType,
            freeDelivery: false,
          ),

          // add button
          Positioned(
            right: 8, bottom: 8,
            child: Container(
              height: 36, width: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: const Color(0xFFE8E8E8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, size: 24, color: Color(0xFF212121)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCardWidget extends StatelessWidget {
  final String? label;
  final bool? isFree;
  const _OfferCardWidget({this.label, this.isFree});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(color: (isFree ?? false) ? Colors.blueAccent : Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((isFree ?? false)) ...[
            Icon(Icons.delivery_dining_outlined, size: Dimensions.fontSizeSmall, color: Colors.white),
            const SizedBox(width: 5),
          ],

          Text((isFree ?? false) ? 'Free' : label!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)),
        ],
      ),
    );
  }
}
