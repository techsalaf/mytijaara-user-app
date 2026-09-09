import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

// Shows the amount a user saved with Pro on this order, using the benefit data
// returned by the order response. Shown whenever the saved amount > 0 —
// independent of the pro config flag or the user's current pro status.
// NOTE: not currently wired into order details (mart already shows a pro savings
// row there); kept for parity with StackFood and future reuse.
class ProOrderSavingsBannerWidget extends StatelessWidget {
  final OrderModel order;
  const ProOrderSavingsBannerWidget({super.key, required this.order});

  double get _savedAmount {
    switch (order.benefitType) {
      case ProBenefitType.deliveryFee:
        return order.deliveryFeeReductionAmount ?? 0;
      case ProBenefitType.discount:
        return order.proDiscount ?? 0;
      case ProBenefitType.coupon:
        return order.couponDiscountAmount ?? 0;
      case null:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double saved = _savedAmount;
    if (saved <= 0) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: const Color(0xFFB57BEE),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(children: [
        const Text('\u{1F451}', style: TextStyle(fontSize: 14)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Text(
            '${'you_saved'.tr} ${PriceConverter.convertPrice(saved)} ${'with_pro'.tr}',
            style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
          ),
        ),
      ]),
    );
  }
}
