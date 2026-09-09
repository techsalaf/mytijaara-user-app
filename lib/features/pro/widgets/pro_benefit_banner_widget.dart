import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ProBenefitBannerWidget extends StatelessWidget {
  final ProActiveBenefit benefit;
  final double subtotal;
  final double discount;
  final double couponDiscount;
  // Promo mode: used on screens that have no cart/subtotal yet (e.g. parcel set-location).
  // Forces the achieved benefit text ("you get X% off…") instead of the cart-progress
  // "spend more to unlock…" message that the min-order check would otherwise produce.
  final bool assumeMinOrderMet;
  const ProBenefitBannerWidget({super.key,
    required this.benefit, required this.subtotal, this.discount = 0, this.couponDiscount = 0, this.assumeMinOrderMet = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = _buildSpans();
    if (spans.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(color: const Color(0xFF4B6CE0), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Row(children: [
        Image.asset(Images.proPlanCrown, height: 18, width: 18),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text.rich(
          TextSpan(children: spans),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }

  List<InlineSpan> _buildSpans() {
    final TextStyle textStyle = robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall);
    final TextStyle boldStyle = robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall);

    TextSpan text(String value) => TextSpan(text: value, style: textStyle);
    TextSpan bold(String value) => TextSpan(text: value, style: boldStyle);

    List<InlineSpan> minOrderSuffix() {
      if (benefit.minOrderStatus == true && (benefit.minOrderAmount ?? 0) > 0) {
        return [text(' - ${ModuleHelper.proMinSpendLabel(fallbackKey: 'min_order')} ${PriceConverter.convertPrice(benefit.minOrderAmount)}')];
      }
      return [];
    }

    if (benefit.type == ProBenefitType.coupon) {
      return [text('you_have_a_coupon_as_a_pro_member'.tr)];

    } else if (benefit.type == ProBenefitType.discount) {
      final bool meetsMinOrder = assumeMinOrderMet || benefit.minOrderStatus != true || subtotal >= (benefit.minOrderAmount ?? 0);
      final bool hasMax = benefit.maxAmount != null && benefit.maxAmount! > 0;
      if (!meetsMinOrder) {
        final double remaining = (benefit.minOrderAmount ?? 0) - subtotal;
        return [
          bold(PriceConverter.convertPrice(remaining)),
          text(' ${'more_to_unlock_pro_discount'.tr}'),
          if (hasMax) text(' ${'up_to'.tr.toLowerCase()} '),
          if (hasMax) bold(PriceConverter.convertPrice(benefit.maxAmount)),
          ...minOrderSuffix(),
        ];
      }
      // Calculate on the net base so the preview matches the checkout's _calculateProDiscount.
      final double base = (subtotal - discount - couponDiscount).clamp(0, double.infinity).toDouble();
      double savings = base * ((benefit.percentage ?? 0) / 100);
      if (benefit.maxAmount != null && benefit.maxAmount! > 0 && savings > benefit.maxAmount!) savings = benefit.maxAmount!;
      if (savings > base) savings = base;
      return [
        text('${'you_save'.tr} '),
        bold(PriceConverter.convertPrice(savings)),
        text(' ${'as_a_pro_member'.tr}'),
      ];

    } else if (benefit.type == ProBenefitType.deliveryFee) {
      final bool meetsMinOrder = assumeMinOrderMet || benefit.minOrderStatus != true || subtotal >= (benefit.minOrderAmount ?? 0);
      if (!meetsMinOrder) {
        final double remaining = (benefit.minOrderAmount ?? 0) - subtotal;
        return [
          bold(PriceConverter.convertPrice(remaining)),
          text(' ${benefit.offerType == ProOfferType.fullFree ? 'more_to_unlock_free_delivery'.tr : 'more_to_unlock_delivery_discount'.tr}'),
          ...minOrderSuffix(),
        ];
      }
      if (benefit.offerType == ProOfferType.fullFree) {
        return [text('you_get_free_delivery_as_a_pro_member'.tr)];
      }
      return [
        text('${'you_get'.tr} ${(benefit.chargeDiscountPercentage ?? 0).toStringAsFixed(0)}% ${'off_on_delivery_charge_as_a_pro_member'.tr}'),
      ];
    }
    return [];
  }
}
