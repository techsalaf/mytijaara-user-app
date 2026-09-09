import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class DeliveryTypeSection extends StatefulWidget {
  final bool homeDeliveryEnabled;
  final bool takeAwayEnabled;
  final double total;
  final double charge;

  const DeliveryTypeSection({super.key,
    required this.homeDeliveryEnabled,
    required this.takeAwayEnabled,
    required this.total,
    required this.charge,
  });

  @override
  State<DeliveryTypeSection> createState() => _DeliveryTypeSectionState();
}

class _DeliveryTypeSectionState extends State<DeliveryTypeSection> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Get.find<CheckoutController>().setOrderType(
        widget.homeDeliveryEnabled ? 'delivery' : 'take_away',
        notify: true,
      );
    });
  }

  void _onSelect(String value) {
    final controller = Get.find<CheckoutController>();
    controller.setOrderType(value);
    controller.setInstruction(-1);

    if (controller.orderType == 'take_away') {
      if (controller.isPartialPay) {
        double tips = 0;
        try {
          tips = double.parse(controller.tipController.text);
        } catch (_) {}
        controller.checkBalanceStatus(widget.total, widget.charge + tips);
      }
    } else {
      if (controller.isPartialPay) {
        controller.changePartialPayment();
      } else {
        controller.setPaymentMethod(-1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.homeDeliveryEnabled || !widget.takeAwayEnabled) {
      return const SizedBox.shrink();
    }

    return GetBuilder<CheckoutController>(builder: (controller) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
        child: CustomCardCheckout(
          child: Row(children: [
            Expanded(child: _DeliveryTypeSegment(
              title: 'home_delivery'.tr,
              selected: controller.orderType == 'delivery',
              onTap: () => _onSelect('delivery'),
            )),
            Expanded(child: _DeliveryTypeSegment(
              title: 'take_away'.tr,
              selected: controller.orderType == 'take_away',
              onTap: () => _onSelect('take_away'),
            )),
          ]),
        ),
      );
    });
  }
}

class _DeliveryTypeSegment extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryTypeSegment({required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall + 2),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: robotoMedium.copyWith(
            color: selected ? Colors.white : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}