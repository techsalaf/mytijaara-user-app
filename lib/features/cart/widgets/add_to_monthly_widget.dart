import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MonthlyReorderSection extends StatelessWidget {
  const MonthlyReorderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (controller) {
      final bool isChecked = controller.monthlySubscribe;
      final Color titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Colors.yellow.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Row(children: [
          Expanded(
            child: _MonthlyOrderTitle(titleColor: titleColor, onInfoTap: () => _showMonthlyPolicySheet(context, controller)),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          InkWell(
            onTap: controller.toggleMonthlySubscribe,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: Container(height: 24, width: 24,
              decoration: BoxDecoration(
                color: isChecked ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                border: Border.all(color: isChecked ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
              ),
              child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ),
        ]),
      );
    });
  }
}

class _MonthlyOrderTitle extends StatelessWidget {
  final Color titleColor;
  final VoidCallback onInfoTap;

  const _MonthlyOrderTitle({required this.titleColor, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: titleColor);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text('add_to_monthly_order'.tr, style: baseStyle),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      InkWell(
        onTap: onInfoTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: 18,
          width: 18,
          decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.info_outline, color: Colors.white, size: 12),
        ),
      ),
    ]);
  }
}

void _showMonthlyPolicySheet(BuildContext context, CheckoutController controller) {
  final List<String> policyKeys = controller.getMonthlyReorderPolicy();
  Get.bottomSheet(
    Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              height: 5,
              width: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => Get.back(),
              child: Icon(Icons.close, color: Theme.of(context).disabledColor),
            ),
          ),
          Text(
            'monthly_reorder_policy'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (int i = 0; i < policyKeys.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == policyKeys.length - 1 ? 0 : Dimensions.paddingSizeSmall),
                  child: _PolicyStep(stepNumber: i + 1, text: policyKeys[i].tr),
                ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Center(
            child: TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'got_it'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ]),
      ),
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _PolicyStep extends StatelessWidget {
  final int stepNumber;
  final String text;

  const _PolicyStep({required this.stepNumber, required this.text});

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '$stepNumber.',
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: textColor, height: 1.45),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Text(
          text,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: textColor, height: 1.45),
        ),
      ),
    ]);
  }
}
