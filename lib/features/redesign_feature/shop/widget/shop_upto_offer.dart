import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/domain/models/top_offer_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/single_deal_widget.dart';
import 'package:sixam_mart/features/offer/offer_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';

enum TopOfferVariant { food, shop, grocery }

class ShopUpToOffer extends StatelessWidget {
  final TopOfferVariant variant;
  const ShopUpToOffer({super.key, required this.variant});

  // The top-offer API is loaded by the module home screens (food / grocery / shop)
  // in their initState, alongside their other module APIs — so this widget only
  // renders the already-fetched data.
  String get _prefixKey {
    switch(variant) {
      case TopOfferVariant.shop: return 'shop_up_to';
      case TopOfferVariant.food: return 'get_launch_up_to';
      case TopOfferVariant.grocery: return 'get_items_up_to';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (controller) {
      final TopOfferModel? topOffer = controller.topOffer;
      final double? discount = topOffer?.discount;
      if(topOffer == null || discount == null || discount <= 0) {
        return const SizedBox.shrink();
      }

      final String discountText = topOffer.discountType == 'percent'
          ? '${discount.toStringAsFixed(0)}%'
          : PriceConverter.convertPrice(discount);
      final String title = '${_prefixKey.tr} $discountText ${'off'.tr}!';

      return SingleDealWidget(
        beginColor: const Color(0xFFFFF1C2),
        endColor: const Color(0xFFFFF1C2).withValues(alpha: 0.9),
        title: title,
        subTitle: 'dont_miss_out_order_favorites'.tr,
        onTap: () {
          Get.to(() => const OfferScreen());
        },
      );
    });
  }
}
