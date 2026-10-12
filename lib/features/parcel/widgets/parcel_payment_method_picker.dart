import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelPaymentMethodPicker extends StatelessWidget {
  final ParcelController controller;
  final VoidCallback onTap;

  const ParcelPaymentMethodPicker({super.key, required this.controller, required this.onTap});

  String _label() {
    switch (controller.paymentIndex) {
      case 0:
        return 'cash_on_delivery'.tr;
      case 1:
        return 'wallet_payment'.tr;
      case 2:
        return '${'digital_payment'.tr} (${controller.digitalPaymentName?.replaceAll('_', ' ').toTitleCase() ?? ''})';
      case 3:
        return '${'offline_payment'.tr} (${controller.offlineMethodList?[controller.selectedOfflineBankIndex].methodName ?? ''})';
      default:
        return 'select_payment_method'.tr;
    }
  }

  String _icon() {
    switch (controller.paymentIndex) {
      case 1:
        return Images.wallet;
      case 2:
        return Images.digitalPayment;
      default:
        return Images.cash;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.paymentIndex == -1) {
      return InkWell(
        onTap: onTap,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashPattern: const [5, 4],
            radius: const Radius.circular(Dimensions.radiusDefault),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'add_payment_method'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 0.7),
        ),
        child: Row(children: [
          Image.asset(_icon(), width: 22, height: 22, color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              _label(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
        ]),
      ),
    );
  }
}

// SUMMARY
// The parcel payment-method picker shared by the set-location and request screens. Draws a
// dotted "add payment method" button while nothing is chosen and a bordered row naming the
// chosen method once one is, and reports a tap so the screen can open the methods sheet.
