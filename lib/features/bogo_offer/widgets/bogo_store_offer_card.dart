import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/helper/bogo_helper.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_details_bottom_sheet.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoStoreOfferCard extends StatelessWidget {
  final BogoBundleModel bundle;
  final String? offerTitle;
  final String? offerLabel;
  final String? validUntil;
  final int? remainingUses;
  final int? offerModuleId;

  const BogoStoreOfferCard({super.key,
    required this.bundle, this.offerTitle, this.offerLabel, this.validUntil, this.remainingUses,
    this.offerModuleId,
  });

  void _openDetailsBottomSheet(BuildContext context) {
    BogoOfferDetailsBottomSheet.show(context, bundle: bundle, offerTitle: offerTitle, offerLabel: offerLabel, validUntil: validUntil, remainingUses: remainingUses, offerModuleId: offerModuleId);
  }

  @override
  Widget build(BuildContext context) {
    final int buyCount = bundle.buyCount ?? bundle.buyItems.length;
    final int getCount = bundle.getCount ?? bundle.freeItems.length;

    final double price = bundle.bundlePrice ?? 0;
    // final double? originalPrice = bundle.originalPrice;
    // final bool hasDiscount = originalPrice != null && originalPrice > price;

    final String? distance = BogoHelper.distanceLabel(bundle.store);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall-3.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        color: Theme.of(context).cardColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _openDetailsBottomSheet(context),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                color: Theme.of(context).colorScheme.surface,
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Center(child: _PairedImages(buyCount: buyCount, buyItems: bundle.buyItems, getCount: getCount, getItems: bundle.freeItems))
            ),
          ),

          GestureDetector(
            onTap: () => BogoHelper.openStore(bundle.store, offerModuleId: offerModuleId),
            child: Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 2),
                  ),
                  child: ClipOval(
                    child: CustomImage(
                      image: bundle.store?.logoFullUrl ?? '', height: 40, width: 40, fit: BoxFit.cover,
                      cacheWidth: ImageCacheHelper.pixels(context, 40),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(bundle.store?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Row(children: [
                        if(bundle.store?.deliveryTime != null && bundle.store!.deliveryTime!.isNotEmpty) ...[
                          Icon(Icons.access_time, size: 14, color: Theme.of(context).disabledColor),
                          const SizedBox(width: 2),
                          Text(bundle.store!.deliveryTime!, style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                          const SizedBox(width: 2),
                        ],
                        if(distance != null)
                          Text('($distance)', style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                      ]),
                    ],
                  ),
                ),

                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Dimensions.paddingSizeExtraSmall,
                  runSpacing: Dimensions.paddingSizeExtraSmall,
                  children: [
                    Text(PriceConverter.convertPrice(price), textDirection: TextDirection.ltr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),

                    // if(hasDiscount) Text(
                    //   PriceConverter.convertPrice(originalPrice),
                    //   textDirection: TextDirection.ltr,
                    //   style: robotoRegular.copyWith(
                    //     fontSize: Dimensions.fontSizeDefault,
                    //     color: Theme.of(context).disabledColor,
                    //     decoration: TextDecoration.lineThrough,
                    //     decorationColor: Theme.of(context).disabledColor,
                    //   ),
                    // ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PairedImages extends StatelessWidget {
  final int buyCount;
  final List<BogoOfferItemModel> buyItems;
  final int getCount;
  final List<BogoOfferItemModel> getItems;

  const _PairedImages({required this.buyCount, required this.buyItems, required this.getCount, required this.getItems});

  @override
  Widget build(BuildContext context) {
    // Each cluster centres in its own half, whatever it is carrying.
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

      Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: _LabelledCluster(items: buyItems, label: 'buy_item'.tr))),

      SizedBox(
        width: 54,
        child: Icon(
          Directionality.of(context) == TextDirection.ltr ? Icons.arrow_forward : Icons.arrow_back,
          size: 24, color: Theme.of(context).hintColor,
        ),
      ),

      Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: _LabelledCluster(items: getItems, label: 'get_item'.tr))),
    ]);
  }
}

class _LabelledCluster extends StatelessWidget {
  final List<BogoOfferItemModel> items;
  final String label;

  const _LabelledCluster({required this.items, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _OverlappingImageCluster(items: items),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
    
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
    ]);
  }
}

class _OverlappingImageCluster extends StatelessWidget {
  final List<BogoOfferItemModel> items;

  const _OverlappingImageCluster({required this.items});

  static const double _size = 46;
  static const double _borderWidth = 2;
  static const double _innerSize = _size - (_borderWidth * 2);
  static const int _maxVisible = 3;

  static const double _overlap = 12;
  static const double _step = _size - _overlap;

  @override
  Widget build(BuildContext context) {
    if(items.isEmpty) {
      return const SizedBox(height: _size, width: _size);
    }

    final int visibleCount = items.length > _maxVisible ? _maxVisible : items.length;
    final int overflowCount = items.length - visibleCount;
    final int circleCount = visibleCount + (overflowCount > 0 ? 1 : 0);

    return SizedBox(
      height: _size,
      width: _size + (circleCount - 1) * _step,
      child: Stack(children: [
        for(int index = 0; index < visibleCount; index++)
          Positioned(
            left: index * _step,
            child: _ClusterCircle(child: CustomImage(
              image: items[index].item.imageFullUrl ?? '',
              height: _innerSize, width: _innerSize, fit: BoxFit.cover, placeholder: Images.placeholder,
              cacheWidth: ImageCacheHelper.pixels(context,  _size + (circleCount - 1) * _step),
            )),
          ),

        if(overflowCount > 0) Positioned(
          left: visibleCount * _step,
          child: _ClusterCircle(
            background: Theme.of(context).colorScheme.surface,
            child: Center(child: Text('+$overflowCount', style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color))),
          ),
        ),
      ]),
    );
  }
}

class _ClusterCircle extends StatelessWidget {
  final Widget child;
  final Color? background;

  const _ClusterCircle({required this.child, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _OverlappingImageCluster._size,
      width: _OverlappingImageCluster._size,
      padding: const EdgeInsets.all(_OverlappingImageCluster._borderWidth),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
      child: ClipOval(
        child: SizedBox(
          height: _OverlappingImageCluster._innerSize,
          width: _OverlappingImageCluster._innerSize,
          child: ColoredBox(color: background ?? Theme.of(context).cardColor, child: child),
        ),
      ),
    );
  }
}

// SUMMARY
// Card for one bundle in an offer's store list. Shows the buy and get item images as
// two overlapping clusters, the store's logo, name, delivery time and distance, and the
// bundle price against its original, opening the bundle sheet or the store on tap.
