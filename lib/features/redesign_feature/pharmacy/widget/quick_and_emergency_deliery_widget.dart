import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

// Item tiles are sized so the bundle card shows 3 full tiles + a peek of the 4th.
const double _kVisibleTiles = 3.2;

// Tile width that fits [_kVisibleTiles] inside the given card width, accounting for
// the strip's left padding and the separators between the three full tiles.
double _tileWidthFor(double cardWidth) {
  return (cardWidth - Dimensions.paddingSizeSmall * 4) / _kVisibleTiles;
}

// Height of a tile's content: square image (== tile width) + gap + 2-line name +
// gap + price + struck price, scaled by the device text scale so nothing clips and
// the prices stay aligned across tiles.
double _tileContentHeight(BuildContext context, double tileWidth) {
  final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final double nameHeight = Dimensions.fontSizeSmall * 1.3 * 2 * textScale;
  final double priceHeight = (Dimensions.fontSizeLarge * 1.3 + Dimensions.fontSizeSmall * 1.3) * textScale;
  return tileWidth + Dimensions.paddingSizeSmall + nameHeight + Dimensions.paddingSizeExtraSmall + priceHeight;
}

// Full bundle-card height: top spacer + item strip (+ its padding) + divider + store row.
// The store row grows with the text scale (logo vs. its two text lines), so the card
// never overflows even with large accessibility fonts.
double _bundleCardHeight(BuildContext context, double tileWidth) {
  final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final double storeRowContent = math.max(
    40, // store logo
    (Dimensions.fontSizeDefault * 1.3 + Dimensions.fontSizeSmall * 1.3) * textScale, // name + delivery line
  );
  return _tileContentHeight(context, tileWidth)
      + Dimensions.paddingSizeExtraSmall                   // top spacer
      + Dimensions.paddingSizeSmall * 2                    // strip vertical padding
      + 2                                                  // divider
      + storeRowContent + Dimensions.paddingSizeSmall * 2  // store row + its padding
      + Dimensions.paddingSizeExtraSmall;                  // safety buffer
}

class QuickAndEmergencyDeliveryWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final bool isQuick;
  const QuickAndEmergencyDeliveryWidget({super.key, required this.title, this.isQuick = false, this.subTitle});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.sizeOf(context).width * 0.80;
    // Item tile width sized so the card shows 3 full tiles + a peek of the 4th, and
    // the card height derived from that tile content (so it scales and never clips).
    final double tileWidth = _tileWidthFor(cardWidth);
    final double sectionHeight = _bundleCardHeight(context, tileWidth);

    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? stores = storeController.quickDeliveryStoreList?.stores;
      final bool isLoading = storeController.quickDeliveryStoreList == null;
      if(!isLoading && (stores == null || stores.isEmpty)) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Row(children: [
              if(isQuick) ...[
                Image.asset(Images.quickDelivery, height: 31, width: 40),
                const SizedBox(width: Dimensions.paddingSizeSmall),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleWidget(title: title),
                  if(subTitle != null) Text(
                    subTitle!,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          SizedBox(
            height: sectionHeight,
            child: isLoading
                ? _QuickDeliveryShimmer(cardWidth: cardWidth)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    itemCount: stores!.length,
                    separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                    itemBuilder: (context, index) => _StoreBundleCard(
                      store: stores[index], width: cardWidth, tileWidth: tileWidth,
                    ),
                  ),
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      );
    });
  }
}

class _StoreBundleCard extends StatelessWidget {
  final Store store;
  final double width;
  final double tileWidth;
  const _StoreBundleCard({required this.store, required this.width, required this.tileWidth});

  void _openStore() {
    Get.toNamed(
      RouteHelper.getStoreRoute(id: store.id, page: 'store_new', slug: store.slug ?? 'store_${store.id}'),
      arguments: StoreScreen(store: Store(id: store.id), fromModule: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
              blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 5),
            ),
          ],
        ),
        margin: const EdgeInsets.only(bottom: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Expanded(child: _TopItemsStrip(items: store.topItems ?? const <TopItem>[], tileWidth: tileWidth)),

            Divider(color: Theme.of(context).disabledColor.withAlpha(80), height: 2, thickness: 1),

            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Row(children: [
                ClipOval(
                  child: CustomImage(image: store.logoFullUrl ?? '', height: 40, width: 40),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              store.name ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                            ),
                          ),
                          const SizedBox(width: 4),

                          store.verifiedSeller == 1 ? Image.asset(Images.verifiedBadge2, width: 16, height: 16) : const SizedBox.shrink(),
                        ],
                      ),
                      Row(children: [
                        Icon(Icons.directions_bike_outlined, size: 16, color: Theme.of(context).disabledColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _deliveryInfo(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                const Icon(Icons.keyboard_arrow_right),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _deliveryInfo() {
    final String time = store.deliveryTime ?? '';
    final double? km = store.distanceKm;
    if(km == null) return time;
    final String distance = '${km.toStringAsFixed(1)} km';
    return time.isEmpty ? distance : '$time ($distance)';
  }
}

class _TopItemsStrip extends StatelessWidget {
  final List<TopItem> items;
  final double tileWidth;
  const _TopItemsStrip({required this.items, required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    if(items.isEmpty) {
      return Center(
        child: Text(
          'no_items_found'.tr,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall + 5, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) => _TopItemTile(item: items[index], tileWidth: tileWidth),
    );
  }
}

class _TopItemTile extends StatelessWidget {
  final TopItem item;
  final double tileWidth;
  const _TopItemTile({required this.item, required this.tileWidth});

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = (item.discount ?? 0) > 0;
    // Reserve two lines for the name so the prices line up across tiles.
    final double nameHeight = Dimensions.fontSizeSmall * 1.3 * 2 * MediaQuery.textScalerOf(context).scale(1.0);
    return SizedBox(
      width: tileWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: tileWidth, width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withAlpha(20),
              border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), width: 1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault - 2),
              child: CustomImage(image: item.imageFullUrl ?? '', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, height: 1.2),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                // Price must stay on one line — scale the font down to fit (no wrap, no ellipsis).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    PriceConverter.convertPrice(item.price ?? 0, discount: hasDiscount ? item.discount : null, discountType: item.discountType),
                    maxLines: 1, softWrap: false,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),

                hasDiscount ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    PriceConverter.convertPrice(item.price ?? 0),
                    maxLines: 1, softWrap: false,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough, decorationColor: Theme.of(context).disabledColor),
                  ),
                ) : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDeliveryShimmer extends StatelessWidget {
  final double cardWidth;
  const _QuickDeliveryShimmer({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
        ),
      ),
    );
  }
}
