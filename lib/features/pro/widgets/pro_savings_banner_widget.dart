import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

// "You save X as a pro member" banner for order/trip details (rental & ride-share).
// Mirrors the food/grocery order-details savings banner; hides itself when amount <= 0.
class ProSavingsBannerWidget extends StatelessWidget {
  final double amount;
  final EdgeInsetsGeometry margin;
  const ProSavingsBannerWidget({super.key,
    required this.amount,
    this.margin = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
  });

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox();
    final TextStyle textStyle = robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall);
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(color: const Color(0xFF4B6CE0), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Row(children: [
        Image.asset(Images.proPlanCrown, height: 18, width: 18),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('you_save'.tr, style: textStyle),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(PriceConverter.convertPrice(amount), style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text('as_a_pro_member'.tr, style: textStyle),
        ])),
      ]),
    );
  }
}
