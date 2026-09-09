import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/screens/order_details_new_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

import '../../../../store/domain/models/store_model.dart';

class LastOrderCard extends StatelessWidget {
  final OrderModel order;
  final double width;
  final bool showBorder;
  final bool isParcel;
  final bool? isPharmacy;

  const LastOrderCard({super.key, required this.order, required this.width, this.showBorder = false, required this.isParcel, this.isPharmacy = false});
  final showItemStackCount = 3;

  @override
  Widget build(BuildContext context) {
    final String storeName = order.store?.name ?? 'Last Order';
    final String storeLogo = order.store?.logoFullUrl ?? '' ;
    final List<String> itemImages = _getItemImages();
    final String orderAmount = PriceConverter.convertPrice(order.orderAmount ?? 0);

    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: _openOrderDetails,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isPharmacy! ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: showBorder ? Border.all(
              color: Theme.of(context).disabledColor.withAlpha(50)
          ) : null,
        ),
        child: Column(children: [
          Row(children: [
            SizedBox(
              height: 42,
              width: 42,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isParcel ? 42 : Dimensions.radiusSmall),
                child: storeLogo.isEmpty
                    ? Container(
                        color: Theme.of(context).disabledColor.withAlpha(50),
                        child: const Center(child: Icon(Icons.store, size: 24)),
                      )
                    : CustomImage(image: storeLogo, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isParcel ? (order.receiverDetails?.contactPersonName ?? '') :  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(height: 2),
                Text(
                  isParcel ? (order.receiverDetails?.address ?? '') : _formatOrderDate(order.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                ),
              ]),
            ),
          ]),
          const Spacer(),

          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                margin: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: isPharmacy! ? Theme.of(context).cardColor : Theme.of(context).disabledColor.withAlpha(50),
                ),

                child: Row(children: [
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: isParcel ? ParcelTile(order: order, imageSize: 34,) : LastOrderItemsPreview(images: (itemImages.length > showItemStackCount) ?  itemImages.getRange(0, showItemStackCount).toList() : itemImages, extraCount: itemImages.length - showItemStackCount),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  Text(
                    orderAmount, maxLines: 1,
                    textDirection: TextDirection.ltr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                  ),
                ]),
              ),
            ),

            GetBuilder<SplashController>(builder: (splashController) {
                final repeatOrder = splashController.configModel?.repeatOrderOption;
                final canReorder = order.canReorder ?? false;

               return (repeatOrder == 1 && canReorder) ? GetBuilder<OrderController>(builder: (orderController) {
                  final bool busy = orderController.reorderingOrderId == order.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    onTap: busy ? null : _reorder,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                    ),
                  );
                }) : const SizedBox.shrink();
              }
            ),
          ]),
        ]),
      ),
    );
  }

  List<String> _getItemImages() {
    return order.store?.items?.map((item) => item.imageFullUrl ?? '').where((image) => image.isNotEmpty).take(3).toList() ?? <String>[];
  }

  void _openOrderDetails() {
    Get.toNamed(
    RouteHelper.getStoreRoute(id: order.store!.id!, page: 'store', slug: order.store?.slug??'store_${order.store?.id}'),
      arguments: StoreScreen(store: Store(id: order.store!.id!), fromModule: false, slug: order.store?.slug??'store_${order.store?.id}',),
    );
  }

  void _reorder() {
    Get.find<OrderController>().reorder(order);
  }
}

class LastOrderItemsPreview extends StatelessWidget {
  final List<String?> images;
  final int extraCount;
  final double imageSize;

  const LastOrderItemsPreview({super.key, required this.images, required this.extraCount, this.imageSize = 30});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).cardColor;

    if (images.isEmpty) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: imageSize,
          width: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cardColor,
            border: Border.all(color: Colors.black12, width: 0.4),
          ),
          child: const Center(child: Icon(Icons.image, size: 14)),
        ),
      ]);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: imageSize,
        width: (images.length * (imageSize-5)) + 5,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: List.generate(images.length, (index) {
            final image = images[index];
            return Positioned(
              left: index * (imageSize-10),
              child: Container(
                height: imageSize,
                width: imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                  border: Border.all(color: Colors.black12, width: 0.4),
                ),
                child: (image ?? '').isEmpty
                    ? const Center(child: Icon(Icons.image, size: 16))
                    : ClipOval(child: CustomImage(image: image ?? '', fit: BoxFit.cover)),
              ),
            );
          }),
        ),
      ),
      if(extraCount > 0) ...[
        Text('+$extraCount', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall,),),
      ],
    ]);
  }
}


class ParcelTile extends StatelessWidget {
  final OrderModel order;
  final double imageSize;

  const ParcelTile({super.key, required this.order, this.imageSize = 30});

  @override
  Widget build(BuildContext context) {
    // final Color cardColor = Theme.of(context).cardColor;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: imageSize,
        child: Row(children: [

          SizedBox(
            height: imageSize,
            width: imageSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: (order.parcelCategory?.imageFullUrl ?? '').isEmpty
                  ? Container(
                      color: Theme.of(context).disabledColor.withAlpha(50),
                      child: const Center(child: Icon(Icons.local_shipping, size: 16)),
                    )
                  : CustomImage(image: order.parcelCategory?.imageFullUrl ?? '', fit: BoxFit.cover),
            ),
          ),

          const SizedBox(width: Dimensions.paddingSizeExtraSmall,),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              order.parcelCategory?.name ?? 'unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            Text(
              _formatOrderDate(order.createdAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
            ),
          ]),
        ]),
      )
    ]);
  }
}

String _formatOrderDate(String? dateTime) {
  if(dateTime == null || dateTime.isEmpty) {
    return '';
  }

  try {
    return DateConverter.dateToReadableDate(DateTime.parse(dateTime));
  } catch(_) {
    try {
      return DateConverter.dateToReadableDate(DateConverter.dateTimeStringToDate(dateTime));
    } catch(_) {
      return dateTime;
    }
  }
}

