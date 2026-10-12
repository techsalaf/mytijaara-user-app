import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/bogo_item_group_widget.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_card.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class OrderItemWidget extends StatelessWidget {
  final OrderModel order;
  final OrderDetailsModel orderDetails;
  const OrderItemWidget({super.key, required this.order, required this.orderDetails});
  
  @override
  Widget build(BuildContext context) {
    if(orderDetails.isBogoBundle) {
      return _BogoBundleOrderRow(orderDetails: orderDetails);
    }

    String addOnText = '';
    for (var addOn in orderDetails.addOns!) {
      addOnText = '$addOnText${(addOnText.isEmpty) ? '' : ',  '}${addOn.name} (${addOn.quantity})';
    }

    String? variationText = '';
    if(orderDetails.variation!.isNotEmpty) {
      if(orderDetails.variation!.isNotEmpty) {
        List<String> variationTypes = orderDetails.variation![0].type!.split('-');
        if(variationTypes.length == orderDetails.itemDetails!.choiceOptions!.length) {
          int index = 0;
          for (var choice in orderDetails.itemDetails!.choiceOptions!) {
            variationText = '${variationText!}${(index == 0) ? '' : ',  '}${choice.title} - ${variationTypes[index]}';
            index = index + 1;
          }
        }else {
          variationText = orderDetails.itemDetails!.variations![0].type;
        }
      }
    }else if(orderDetails.foodVariation!.isNotEmpty) {
      for(FoodVariation variation in orderDetails.foodVariation!) {
        variationText = '${variationText!}${variationText.isNotEmpty ? ', ' : ''}${variation.name} (';
        if(variation.variationValues != null){
          for(VariationValue value in variation.variationValues!) {
            variationText = '${variationText!}${variationText.endsWith('(') ? '' : ', '}${value.level}';
          }
        }
        variationText = '${variationText!})';
      }
    }

    return CustomCard(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: CustomImage(
              height: 50, width: 50, fit: BoxFit.cover,
              image: '${orderDetails.imageFullUrl}',
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  orderDetails.itemDetails!.name!,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                )),
                Text('${'quantity'.tr}: ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                Text(
                  orderDetails.quantity.toString(),
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Row(children: [
                Expanded(child: Text(
                  PriceConverter.convertPrice(orderDetails.price),
                  style: robotoMedium, textDirection: TextDirection.ltr,
                )),

                 Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().getModuleConfig(order.moduleType).newVariation! ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)
                  ),
                   padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                   child: Text(orderDetails.itemDetails!.veg == 0 ? 'Non-Veg' : 'Veg', style: robotoRegular.copyWith( fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
                ) : const SizedBox(),

                SizedBox(width: orderDetails.itemDetails!.isStoreHalalActive! && orderDetails.itemDetails!.isHalalItem! ? Dimensions.paddingSizeExtraSmall : 0),

                // orderDetails.itemDetails!.isStoreHalalActive! && orderDetails.itemDetails!.isHalalItem! ? const CustomAssetImageWidget(
                //  Images.halalTag, height: 13, width: 13) : const SizedBox(),

              ]),
            ]),
          ),
        ]),

        (Get.find<SplashController>().getModuleConfig(order.moduleType).addOn! && addOnText.isNotEmpty) ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 60),
            Text('${'addons'.tr}: ', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            Flexible(child: Text(addOnText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
          ]),
        ) : const SizedBox(),

        variationText!.isNotEmpty ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 60),
            Text('${'variations'.tr}: ', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            Flexible(child: Text(variationText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
          ]),
        ) : const SizedBox(),

      ]),
    );
  }
}

class _BogoBundleOrderRow extends StatelessWidget {
  final OrderDetailsModel orderDetails;
  const _BogoBundleOrderRow({required this.orderDetails});

  static String? _firstThumbnail(List<OrderBogoItemModel>? items) {
    for (final OrderBogoItemModel item in items ?? const <OrderBogoItemModel>[]) {
      if ((item.imageFullUrl ?? '').isNotEmpty) {
        return item.imageFullUrl;
      }
    }
    return null;
  }

  static List<String> _thumbnailsOf(List<OrderBogoItemModel>? items) {
    return (items ?? const <OrderBogoItemModel>[]).map((item) => item.imageFullUrl ?? '').where((url) => url.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final OrderBogoDetailsModel bogo = orderDetails.bogoDetails!;
    final String? thumbnail = _firstThumbnail(bogo.buyItems);

    return CustomCard(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: (thumbnail != null && thumbnail.isNotEmpty) ? CustomImage(
              height: 50, width: 50, fit: BoxFit.cover, image: thumbnail, placeholder: Images.placeholder,
            ) : Container(
              height: 50, width: 50,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
              child: const Center(child: CustomAssetImageWidget(Images.bogoOfferIcon, height: 24, width: 24, fit: BoxFit.contain)),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  bogo.offerTitle ?? 'bogo_offer'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                )),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(
                  '${'qty'.tr} : ${orderDetails.quantity ?? bogo.quantity ?? 0}',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                PriceConverter.convertPrice(bogo.totalPrice ?? 0),
                style: robotoMedium, textDirection: TextDirection.ltr,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BogoItemGroupWidget(label: 'buying_item'.tr, thumbnails: _thumbnailsOf(bogo.buyItems)),
          const SizedBox(width: Dimensions.paddingSizeExtraLarge),
          BogoItemGroupWidget(label: 'free_item'.tr, thumbnails: _thumbnailsOf(bogo.freeItems)),
        ]),
      ]),
    );
  }
}
