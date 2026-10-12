import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/last_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/dashboard/widgets/common_widget/last_order_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
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

    // Last orders are only ever fetched when repeat ordering is enabled. Without
    // this the loading shimmer below would have nothing to wait for and would show
    // forever wherever this widget is rendered unconditionally (the Home tab).
    if(!fromStore && Get.find<SplashController>().configModel?.repeatOrderOption != 1) {
      return const SizedBox();
    }

    return GetBuilder<OrderController>(builder: (orderController) {
      final List<LastOrderModel>? source = fromStore
          ? orderController.storeLastOrders
          : (moduleType == null ? orderController.lastOrdersHome : orderController.lastOrders);

      // null means "not fetched yet", empty means "fetched, nothing to show". On a
      // lazy module this section fetches when it scrolls into view, so it has to
      // keep its height while loading — a zero-height placeholder would leave every
      // section below it inside the viewport and make them all fetch at once.
      if(source == null) {
        return _LastOrdersShimmer(showTitleFirst: showTitleFirst, isPharmacy: isPharmacy);
      }

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
            child: TitleWidget(title: (isPharmacy ? "refill_your_medicine" : "your_last_order").tr),
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
                      (isPharmacy ? "refill_your_medicine_compact" : "your_last_orders_compact").tr,
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

// Loading placeholder. Mirrors the height of each loaded layout so the section
// holds its space while its data is in flight.
class _LastOrdersShimmer extends StatelessWidget {
  final bool showTitleFirst;
  final bool isPharmacy;

  const _LastOrdersShimmer({required this.showTitleFirst, required this.isPharmacy});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.sizeOf(context).width * 0.70;
    final double cardHeight = (cardWidth * 0.48).clamp(120.0, double.infinity).toDouble();

    if(showTitleFirst) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge),
        child: Container(
          height: 138,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: _ShimmerCardList(cardWidth: cardWidth),
        ),
      );
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: TitleWidget(title: (isPharmacy ? "refill_your_medicine" : "your_last_order").tr),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      SizedBox(height: cardHeight, child: _ShimmerCardList(cardWidth: cardWidth)),
    ]);
  }
}

class _ShimmerCardList extends StatelessWidget {
  final double cardWidth;

  const _ShimmerCardList({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
      ),
    );
  }
}
