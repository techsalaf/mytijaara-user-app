import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/offer_card_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ExclusiveDealCard extends StatelessWidget {
  final Item item;
  final double? width;
  final int? index;
  final bool isCampaign;

  const ExclusiveDealCard({super.key, required this.item, this.width, this.index, this.isCampaign = false});

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context, isCampaign: isCampaign),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          Expanded(child: _LeftSection(item: item)),
          const SizedBox(width: 4),
          _ImageSection(item: item, index: index, isCampaign: isCampaign),
        ]),
      ),
    );
  }
}

class _LeftSection extends StatelessWidget {
  final Item item;

  const _LeftSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final double? startingPrice = Get.find<ItemController>().getStartingPrice(item);
    final bool hasDiscount = (item.discount ?? 0) > 0;
    final String currentPrice = PriceConverter.convertPrice(
      startingPrice, discount: item.discount, discountType: item.discountType,
    );
    final String originalPrice = hasDiscount ? PriceConverter.convertPrice(startingPrice) : '';
    double discount = item.discount ?? 0;
    String discountType = item.discountType ?? '';
    bool isRightSide = Get.find<SplashController>().configModel!.currencySymbolDirection == 'right';
    String currencySymbol = Get.find<SplashController>().configModel!.currencySymbol!;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: <Widget>[
      Row(children: <Widget>[
        StoreVerifiedAvatar(
          imageUrl: item.storeLogoFullUrl ?? item.storeImageFullUrl ?? '',
          isVerified: item.verifiedSeller == 1,
          size: 18,
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Expanded(child: Text(item.storeName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        )),
      ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Text(item.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      const SizedBox(height: 4),

      if(item.avgRating != null && item.avgRating! > 0)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                Icons.star_rounded,
                size: Dimensions.fontSizeSmall,
                color: const Color(0xFFF5A623),
              ),
              const SizedBox(width: 2),
              Text(
                '${item.avgRating?.toStringAsFixed(1)?? '0.0'} (${item.ratingCount} ${'reviews'.tr})',
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                ),
              ),
            ]),
            const SizedBox(height: 4),
          ],
        ),

      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: <Widget>[
          Text(currentPrice,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          if (originalPrice.isNotEmpty)
            Text(originalPrice, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                  decoration: TextDecoration.lineThrough, decorationColor: Theme.of(context).disabledColor),
            ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
        if(item.discount != null && item.discount != 0)
          OfferCardWidget(
            isHilight: true,
            label: discount > 0 ? '${(isRightSide || discountType == 'percent') ? '' : currencySymbol}$discount${discountType == 'percent' ? '%'
                : isRightSide ? currencySymbol : ''} ${'off'.tr}' : 'free_delivery'.tr,
          ),
        if(item.freeDelivery ?? false)
          OfferCardWidget(label: 'free'.tr,iconData: Icons.directions_bike_outlined),
        if(item.offerLabel != null)
          OfferCardWidget(label: item.offerLabel! ,iconData: Icons.discount),
      ]),
    ]);
  }
}

class _ImageSection extends StatelessWidget {
  final Item item;
  final int? index;
  final bool isCampaign;

  const _ImageSection({required this.item, this.index, this.isCampaign = false});

  @override
  Widget build(BuildContext context) {
    final bool showHalal = (item.isStoreHalalActive ?? false) && (item.isHalalItem ?? false);
    final bool isVeg = item.veg == 1;
    final double vegLeft = showHalal ? 46 : 8;

    return SizedBox(
      width: 115, height: 115,
      child: Stack(children: <Widget>[
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomImage(image: item.imageFullUrl ?? '', fit: BoxFit.cover, placeholder: Images.placeholder),
        )),
        if (showHalal)
          const Positioned(top: 8, left: 8,
            child: _DealBadge(assetPath: Images.halalTag, assetSize: 18),
          ),
        if (isVeg)
          Positioned(top: 8, left: vegLeft,
            child: const _DealBadge(assetPath: Images.vegTag, assetSize: 18),
          ),

        if(!isCampaign)
          AddFavouriteView(
            top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
            item: item, storeId: null, size: 18,
          ),

        Positioned(
          right: 8, bottom: 8,
          child: CartCountView(
            item: item, index: index,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.add, size: 22, color: Colors.black),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DealBadge extends StatelessWidget {
  final String assetPath;
  final double assetSize;

  const _DealBadge({required this.assetPath, required this.assetSize});

  @override
  Widget build(BuildContext context) {
    return Container(width: 20, height: 20,
      decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
      alignment: Alignment.center, padding: const EdgeInsets.all(1),
      child: CustomAssetImageWidget(assetPath, width: assetSize, height: assetSize, fit: BoxFit.contain),
    );
  }
}
