import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ConfirmationBottomSheet extends StatelessWidget {
  final String icon;
  final String description;
  final Function onYesPressed;

  const ConfirmationBottomSheet({super.key, required this.icon, required this.description, required this.onYesPressed});

  // Opened without a context so a caller outside a build — a slide action, a helper — can
  // ask the question as easily as a screen can.
  static Future<void> show({required String icon, required String description, required Function onYesPressed}) {
    return Get.bottomSheet(
      ConfirmationBottomSheet(icon: icon, description: description, onYesPressed: onYesPressed),
      backgroundColor: Colors.transparent, isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 550,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Align(alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Image.asset(icon, width: 50, height: 50, color: Theme.of(context).primaryColor),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: Text(
            description,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: SafeArea(
            child: Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  minimumSize: const Size(Dimensions.webMaxWidth, 50),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                ),
                child: Text(
                  'no'.tr,
                  textAlign: TextAlign.center,
                  style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              )),
              const SizedBox(width: Dimensions.paddingSizeLarge),

              Expanded(child: CustomButton(
                buttonText: 'yes'.tr,
                onPressed: () => onYesPressed(),
                radius: Dimensions.radiusSmall, height: 50,
              )),
            ]),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ]),
    );
  }
}

// SUMMARY
// Bottom sheet that asks a yes-or-no question, shown in place of a confirmation dialog.
// Holds the caller's mark and question, dismisses itself on No or the close mark, and
// reports a Yes so the caller can carry the action out.
