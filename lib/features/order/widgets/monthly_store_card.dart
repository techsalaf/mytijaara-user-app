import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/screens/my_items_detail_screen.dart';
import 'package:sixam_mart/features/order/widgets/monthly_item_tile.dart';
import 'package:sixam_mart/features/order/widgets/monthly_order_menu_button.dart';
import 'package:sixam_mart/features/order/widgets/monthly_order_actions.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MonthlyStoreCard extends StatelessWidget {
  final MonthlyOrder order;
  const MonthlyStoreCard({super.key, required this.order});

  static const double _tileWidth = 95;
  static const double _stripHeight = 175;

  void _openDetail() => Get.to(() => MyItemsDetailScreen(order: order));

  void _onMenuSelected(MonthlyOrderMenuAction action) {
    switch(action) {
      case MonthlyOrderMenuAction.addToCart:
        MonthlyOrderActions.addToCart(order);
      case MonthlyOrderMenuAction.view:
        _openDetail();
      case MonthlyOrderMenuAction.remove:
        MonthlyOrderActions.confirmRemove(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MonthlyOrderItemPreview> items = order.itemsPreview;
    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StoreHeader(order: order, onMenuSelected: _onMenuSelected),

            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, 0, Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall),
              child: items.isEmpty
                  ? SizedBox(
                      height: _stripHeight,
                      child: Center(child: Text(
                        'no_items_found'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                      )),
                    )
                  : SizedBox(
                      height: _stripHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
                        itemBuilder: (context, index) => SizedBox(
                          width: _tileWidth,
                          child: MonthlyItemTile(item: items[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final MonthlyOrder order;
  final void Function(MonthlyOrderMenuAction action) onMenuSelected;
  const _StoreHeader({required this.order, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeSmall),
      child: Row(children: [
        ClipOval(child: CustomImage(image: order.store?.logoFullUrl ?? '', height: 36, width: 36)),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.store?.name ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              if(MonthlyOrderActions.refillDate(order) != null) Text(
                '${'next_refill_date_is'.tr} ${MonthlyOrderActions.refillDate(order)}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),

        MonthlyOrderMenuButton(onSelected: onMenuSelected),
      ]),
    );
  }
}
