import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/last_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/last_order_card.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class LastOrdersSectionWidget extends StatelessWidget {
  final String? moduleType;
  final bool fromStore;
  final bool showTitleFirst;

  const LastOrdersSectionWidget({super.key, this.moduleType, this.fromStore = false, this.showTitleFirst = false});

  @override
  Widget build(BuildContext context) {
    final bool isParcel = moduleType == AppConstants.parcel;
    final bool isPharmacy = moduleType == AppConstants.pharmacy;

    if(!AuthHelper.isLoggedIn() || !Get.isRegistered<OrderController>()) {
      return const SizedBox();
    }

    return GetBuilder<OrderController>(builder: (orderController) {
      final List<LastOrderModel> source = fromStore
          ? (orderController.storeLastOrders ?? const <LastOrderModel>[])
          : ((moduleType == null ? orderController.lastOrdersHome : orderController.lastOrders) ?? const <LastOrderModel>[]);
      final List<OrderModel> orders = source.take(10).map(_toOrderModel).toList();

      if(orders.isEmpty) {
        return const SizedBox();
      }

      final double cardWidth = MediaQuery.sizeOf(context).width * 0.70;
      final double cardHeight = (cardWidth * 0.48).clamp(120.0, double.infinity).toDouble();
      return !showTitleFirst ? Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: "your_last_order".tr),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
                    right: (orders.length == index + 1) ? Dimensions.paddingSizeDefault : 0,
                    bottom: Dimensions.paddingSizeExtraSmall + 2,
                  ),
                  child: LastOrderCard(order: orders[index], width: cardWidth, showBorder: true, isParcel: isParcel, isPharmacy: isPharmacy),
                );
              },
            ),
          ),
        ],
      ) :
      Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge),
        child: Container(
          height: 138,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: orders.length + 1,
            itemBuilder: (context, index) {
              final bool isTitle = index == 0;
              return Padding(
                padding: EdgeInsets.only(right: index == orders.length ? 0 : Dimensions.paddingSizeDefault),
                child: isTitle ? SizedBox(
                  width: 62,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your\nLast\nOrders',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, height: 1.12),
                    ),
                  ),
                ) : LastOrderCard(order: orders[index - 1], width: cardWidth, isParcel: isParcel),
              );
            },
          ),
        ),
      );
    });
  }

  OrderModel _toOrderModel(LastOrderModel src) {
    final List<Items> items = src.itemsPreview.map((p) => Items(
      id: p.id, name: p.name, imageFullUrl: p.imageFullUrl,
    )).toList();
    return OrderModel(
      id: src.orderId,
      moduleId: src.moduleId,
      orderAmount: src.orderAmount,
      createdAt: src.createdAt,
      canReorder: src.canReorder,
      store: Store(
        id: src.store?.id,
        name: src.store?.name,
        moduleId: src.moduleId,
        slug: src.store?.slug,
        logoFullUrl: src.store?.logoFullUrl,
        items: items,
      ),
    );
  }
}
