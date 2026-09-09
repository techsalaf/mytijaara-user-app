import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/restaurant_offer_chip.dart';
import 'package:sixam_mart/features/search/domain/models/food_item.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/restaurant_item_card.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/restaurant_summary_row.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/gaps.dart';
import 'package:sixam_mart/util/styles.dart';

class StoreOfferGroupData {
  final Store store;
  final String restaurantName;
  final String restaurantLogoUrl;
  final String deliveryInfoText;
  final List<RestaurantOfferChipData> offers;
  final List<FoodItem> items;
  final List<TopItem> rawItems;

  const StoreOfferGroupData({
    required this.store, required this.restaurantName, required this.restaurantLogoUrl, required this.deliveryInfoText, required this.offers,
    required this.items, required this.rawItems,
  });

  factory StoreOfferGroupData.fromStore(Store store) {
    final double? km = store.distanceKm ?? (store.distance != null ? store.distance! / 1000 : null);
    final String distanceText = km != null ? '${km.toStringAsFixed(1)} km' : '';
    final String deliveryInfo = <String>[
      if((store.deliveryTime ?? '').isNotEmpty) store.deliveryTime!,
      if(distanceText.isNotEmpty) '($distanceText)',
    ].join(' ');

    final double? discountPercent = store.discount?.discount ?? store.avgItemDiscountPercentage;
    final List<RestaurantOfferChipData> offers = <RestaurantOfferChipData>[
      if((discountPercent ?? 0) > 0)
        RestaurantOfferChipData(label: '-${discountPercent!.toStringAsFixed(0)}%'),
      if(store.freeDelivery == true)
        RestaurantOfferChipData(label: 'free_delivery'.tr, icon: Icons.local_shipping_outlined),
    ];

    final List<TopItem> rawItems = (store.topItems != null && store.topItems!.isNotEmpty)
        ? store.topItems!
        : (store.items ?? const <Items>[]).map((Items it) => TopItem(
            id: it.id, name: it.name, imageFullUrl: it.imageFullUrl, price: it.price, discountedPrice: it.price,
            discount: it.discount, discountType: it.discountType,
          )).toList();

    final List<FoodItem> mappedItems = rawItems.map((TopItem item) {
      final double currentPrice = item.discountedPrice ?? item.price ?? 0;
      final double? originalPrice = (item.discount ?? 0) > 0 ? item.price : null;
      return FoodItem(
        imageUrl: item.imageFullUrl ?? '',
        restaurantName: store.name ?? '',
        restaurantLogoUrl: store.logoFullUrl ?? '',
        rating: store.avgRating ?? 0,
        itemName: item.name ?? '',
        price: currentPrice,
        originalPrice: originalPrice,
        discountPercent: item.discount,
      );
    }).toList();

    return StoreOfferGroupData(
      store: store,
      restaurantName: store.name ?? '',
      restaurantLogoUrl: store.logoFullUrl ?? '',
      deliveryInfoText: deliveryInfo,
      offers: offers,
      items: mappedItems,
      rawItems: rawItems,
    );
  }
}

class StoreOfferGroup extends StatelessWidget {
  final StoreOfferGroupData data;
  final bool showBottomDivider;
  final VoidCallback onStoreTap;
  final ValueChanged<TopItem> onItemTap;

  const StoreOfferGroup({super.key, required this.data, required this.showBottomDivider, required this.onStoreTap, required this.onItemTap});

  static const int _maxInlineItems = 4;

  @override
  Widget build(BuildContext context) {
    final int total = data.items.length;
    final bool showViewAll = total >= 5;
    final int count = showViewAll ? _maxInlineItems + 1 : total;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: RestaurantSummaryRow(
            restaurantName: data.restaurantName,
            verifiedSeller: data.store.verifiedSeller,
            restaurantLogoUrl: data.restaurantLogoUrl,
            deliveryInfoText: data.deliveryInfoText,
            offers: data.offers,
            onTap: onStoreTap,
            onArrowTap: onStoreTap,
          ),
        ),
        if(total > 0) ...<Widget>[
          Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: count,
              separatorBuilder: (BuildContext context, int index) => Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
              itemBuilder: (BuildContext context, int index) {
                if(showViewAll && index == _maxInlineItems) {
                  return _ViewAllCard(onTap: onStoreTap);
                }
                return RestaurantItemCard(
                  item: data.items[index],
                  onTap: () => onItemTap(data.rawItems[index]),
                );
              },
            ),
          ),
        ],
        if(showBottomDivider)
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              indent: 16,
            ),
          ),
      ]),
    );
  }
}

class _ViewAllCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color borderColor = Theme.of(context).disabledColor.withValues(alpha: 0.2);
    final Color iconBg = Theme.of(context).disabledColor.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 100,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          Container(height: 100, width: 100,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Container(
                height: 36, width: 36,
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, border: Border.all(color: borderColor)),
                child: Icon(Icons.arrow_forward, size: 18, color: primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('view_all'.tr,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: primary),
          ),
        ]),
      ),
    );
  }
}
