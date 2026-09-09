import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class SaverDeliveryTimeWidget extends StatelessWidget {
  final CheckoutController checkoutController;
  final double deliveryCharge;
  final double originalDeliveryCharge;
  // True when the Pro membership fully covers the delivery fee (full-free or 100% off);
  // the saver charge options become meaningless, so they are disabled just like a free-delivery coupon.
  final bool proFreeDelivery;

  const SaverDeliveryTimeWidget({super.key,
    required this.checkoutController, required this.deliveryCharge, required this.originalDeliveryCharge, this.proFreeDelivery = false,
  });

  static bool _disableSaverOptions({
    required CheckoutController controller, required double deliveryCharge, required double originalDeliveryCharge, bool proFreeDelivery = false,
  }) {
    final Modules? saverModule = controller.saverModule;
    final double? minimumDeliveryCharge = saverModule?.pivot?.minimumDeliveryCharge;
    final bool isFreeDeliveryCouponApplied = Get.find<CouponController>().freeDelivery;
    final bool belowOriginalDeliveryCharge = minimumDeliveryCharge != null
        && originalDeliveryCharge >= 0
        && originalDeliveryCharge < minimumDeliveryCharge;
    final bool hadEligibleOriginalDeliveryCharge = originalDeliveryCharge > 0 && !belowOriginalDeliveryCharge;
    return proFreeDelivery || (isFreeDeliveryCouponApplied && deliveryCharge == 0 && hadEligibleOriginalDeliveryCharge);
  }

  static bool canShow({
    required CheckoutController controller, required double deliveryCharge, required double originalDeliveryCharge, bool proFreeDelivery = false,
  }) {
    final ZoneData? saverZoneData = controller.saverZoneData;
    print("========> ${saverZoneData?.toJson()}");
    final Modules? saverModule = controller.saverModule;
    final double? minimumDeliveryCharge = saverModule?.pivot?.minimumDeliveryCharge;
    final bool belowCurrentDeliveryCharge = minimumDeliveryCharge != null
        && deliveryCharge >= 0
        && deliveryCharge < minimumDeliveryCharge;
    final bool hasCurrentEligibleDeliveryCharge = deliveryCharge > 0 && !belowCurrentDeliveryCharge;
    final bool disableSaverOptions = _disableSaverOptions(
      controller: controller, deliveryCharge: deliveryCharge, originalDeliveryCharge: originalDeliveryCharge, proFreeDelivery: proFreeDelivery,
    );
    return controller.orderType == 'delivery'
        && saverZoneData != null
        && saverModule?.deliveryOptions != null
        && saverZoneData.status == 1
        && (saverModule?.additionalDeliveryOptionStatus ?? false)
        && (hasCurrentEligibleDeliveryCharge || disableSaverOptions);
  }

  @override
  Widget build(BuildContext context) {
    final bool disableSaverOptions = _disableSaverOptions(
      controller: checkoutController, deliveryCharge: deliveryCharge, originalDeliveryCharge: originalDeliveryCharge, proFreeDelivery: proFreeDelivery,
    );

    if(disableSaverOptions && checkoutController.saverDeliveryType != 'standard') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(checkoutController.saverDeliveryType != 'standard') {
          checkoutController.setSaverDeliveryType('standard');
        }
      });
    }

    final Modules? saverModule = checkoutController.saverModule;
    return Column(children: [
      AbsorbPointer(
        absorbing: disableSaverOptions,
        child: Opacity(
          opacity: disableSaverOptions ? 0.55 : 1,
          child: RadioGroup<String>(
            groupValue: checkoutController.saverDeliveryType,
            onChanged: (String? value) {
              if(value != null && !disableSaverOptions) {
                checkoutController.setSaverDeliveryType(value);
              }
            },
            child: ResponsiveHelper.isDesktop(context) ? SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: saverModule!.deliveryOptions!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: SizedBox(
                      width: 270,
                      child: _saverCard(context, index, isDesktop: true),
                    ),
                  );
                },
              ),
            ) : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: saverModule!.deliveryOptions!.length,
              separatorBuilder: (_, _) => Divider(
                height: 1, thickness: 0.5,
                color: Theme.of(context).disabledColor.withValues(alpha: 1),
              ),
              itemBuilder: (context, index) {
                return _saverCard(context, index);
              },
            ),
          ),
        ),
      ),

      if(disableSaverOptions) ...[
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(child: Text(
            'free_delivery_applies_to_this_order_amount_so_delivery_type_charge_options_are_disabled'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
          )),
        ]),
      ],
    ]);
  }

  Widget _saverCard(BuildContext context, int index, {bool isDesktop = false}) {
    final DeliveryOptions deliveryOption = checkoutController.saverModule!.deliveryOptions![index];
    print("-------> ${deliveryOption.toJson()}");
    final bool isFreeDeliveryCouponApplied = Get.find<CouponController>().freeDelivery;
    final bool select = checkoutController.saverDeliveryType == deliveryOption.deliveryType;
    final String storeDeliveryTime = _finalizeDeliveryTime(checkoutController.store?.deliveryTime ?? '', deliveryOption);
    double totalDeliveryCharge = checkoutController.getSaverDeliveryChargeAdjustment(
      deliveryOption: deliveryOption,
    ) + (isFreeDeliveryCouponApplied ? originalDeliveryCharge : deliveryCharge);
    totalDeliveryCharge = totalDeliveryCharge < 0 ? 0 : totalDeliveryCharge;
    final String deliveryChargeText = PriceConverter.convertPrice(totalDeliveryCharge);

    final Widget chargeBadge = (deliveryOption.extraCharge != null || deliveryOption.reduceCharge != null)
        ? Container(
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
            child: Text(
              deliveryOption.extraCharge != null ? '+ ${PriceConverter.convertPrice(deliveryOption.extraCharge)}'
                  : deliveryOption.reduceCharge != null ? '- ${PriceConverter.convertPrice(deliveryOption.reduceCharge)}'
                  : '',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          )
        : const SizedBox.shrink();

    final Widget radio = Radio<String>(
      value: deliveryOption.deliveryType ?? '',
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: Theme.of(context).primaryColor,
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
    );

    final Widget content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(
        '${deliveryOption.deliveryType?.tr} ${'delivery'.tr}',
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      const SizedBox(height: 4),
      Text(
        storeDeliveryTime,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
      ),
      const SizedBox(height: 2),
      Text(
        '${'charge'.tr}: $deliveryChargeText',
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
      ),
    ]);

    return InkWell(
      onTap: deliveryOption.deliveryType == null ? null : () {
        checkoutController.setSaverDeliveryType(deliveryOption.deliveryType!);
      },
      child: Container(
        decoration: isDesktop ? BoxDecoration(
          color: select ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: select ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, width: 0.5),
        ) : null,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? Dimensions.paddingSizeSmall : 0,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: content),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          chargeBadge,
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          radio,
        ]),
      ),
    );
  }

  String _finalizeDeliveryTime(String storeDeliveryTime, DeliveryOptions deliveryOption) {
    String time = '';
    if(storeDeliveryTime.isNotEmpty) {
      int minTime = 0;
      int maxTime = 0;
      try {
        // Accepts: "20-30 min", "15-20", "20-30-min", "15 - 25 hour"
        final match = RegExp(r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*(\w+)?', caseSensitive: false).firstMatch(storeDeliveryTime);
        if(match == null) {
          throw const FormatException('Invalid delivery time format');
        }
        minTime = int.parse(match.group(1)!);
        maxTime = int.parse(match.group(2)!);
        final String timeUnit = match.group(3) ?? 'min';

        minTime = _convertToMinutes(minTime, timeUnit);
        maxTime = _convertToMinutes(maxTime, timeUnit);

        int saverMinTime = checkoutController.saverModule?.pivot?.minimumDeliveryTime?.value ?? 0;
        final String saverMinTimeType = checkoutController.saverModule?.pivot?.minimumDeliveryTime?.unit ?? 'min';
        saverMinTime = _convertToMinutes(saverMinTime, saverMinTimeType);

        if(minTime > saverMinTime) {
          minTime = saverMinTime;
        }

        if(maxTime < saverMinTime) {
          maxTime = saverMinTime;
        }

        if(deliveryOption.deliveryType == 'standard') {
          time = _formatDeliveryTime(minTime, maxTime);
        } else if(deliveryOption.deliveryType == 'express') {
          int reduceTime = deliveryOption.reduceDeliveryTime?.value ?? 0;
          final String reduceTimeType = deliveryOption.reduceDeliveryTime?.unit ?? timeUnit;
          reduceTime = _convertToMinutes(reduceTime, reduceTimeType);
          time = _formatDeliveryTime(minTime, (maxTime - reduceTime).clamp(minTime, 9999999));
        } else if(deliveryOption.deliveryType == 'slightly_delay') {
          int addTime = deliveryOption.addDeliveryTime?.value ?? 0;
          final String addTimeType = deliveryOption.addDeliveryTime?.unit ?? timeUnit;
          addTime = _convertToMinutes(addTime, addTimeType);
          time = _formatDeliveryTime(minTime, maxTime + addTime);
        }
      } catch(_) {}
    }
    return time;
  }

  int _convertToMinutes(int value, String? unit) {
    final normalizedUnit = unit?.toLowerCase() ?? 'min';
    if (normalizedUnit.contains('day')) {
      return value * 24 * 60;
    }
    if (normalizedUnit.contains('hour') ||
        normalizedUnit.contains('hr')) {
      return value * 60;
    }
    return value;
  }

  String _formatDeliveryTime(int minTime, int maxTime) {
    String left = _getSlidTime(minTime);
    String right = _getSlidTime(maxTime);

    final bool isLeftContainMin = left.contains('min');
    final bool isRightContainMin = right.contains('min');
    final bool isLeftContainHour = left.contains('hr');
    final bool isRightContainHour = right.contains('hr');

    if(isLeftContainMin && isRightContainMin && !isLeftContainHour && !isRightContainHour) {
      left = left.replaceAll(' min', '');
      right = right.replaceAll(' min', '');
      if(left == right) {
        return '(${'upto'.tr} $left min)';
      }
      return '($left - $right) min';
    }
    if(!isLeftContainMin && !isRightContainMin && isLeftContainHour && isRightContainHour) {
      left = left.replaceAll(' hr', '');
      right = right.replaceAll(' hr', '');
      if(left == right) {
        return '(${'upto'.tr} $left hr)';
      }
      return '($left - $right) hr';
    }
    if(left == right) {
      return '(${'upto'.tr} $left)';
    }
    return '($left - $right)';
  }

  String _getSlidTime(int value) {
    if(value >= 60) {
      final int h = value ~/ 60;
      final int m = value % 60;
      if(m == 0) {
        return '$h hr';
      }
      return '$h hr $m min';
    }
    return '$value min';
  }
}
