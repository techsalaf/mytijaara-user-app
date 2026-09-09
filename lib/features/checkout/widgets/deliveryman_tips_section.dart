import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/tips_widget.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class DeliveryManTipsSection extends StatefulWidget {
  final bool takeAway;
  final JustTheController tooltipController3;
  final double totalPrice;
  final Function(double x) onTotalChange;
  final int? storeId;
  const DeliveryManTipsSection({
    super.key,
    required this.takeAway,
    required this.tooltipController3,
    required this.totalPrice,
    required this.onTotalChange,
    this.storeId,
  });

  @override
  State<DeliveryManTipsSection> createState() => _DeliveryManTipsSectionState();
}

class _DeliveryManTipsSectionState extends State<DeliveryManTipsSection> {
  bool canCheckSmall = false;

  @override
  Widget build(BuildContext context) {
    final bool dmTipsEnabled = Get.find<SplashController>().configModel!.dmTipsStatus == 1;
    if (widget.takeAway || !dmTipsEnabled) {
      return const SizedBox.shrink();
    }

    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      final bool isCustom = AppConstants.tips[checkoutController.selectedTips] == 'custom';
      final bool customFieldVisible = isCustom && checkoutController.canShowTipsField;

      return CustomCardCheckout(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _TipsHeader(tooltipController: widget.tooltipController3),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _TipsChipStrip(
            checkoutController: checkoutController,
            totalPrice: widget.totalPrice,
            customFieldVisible: customFieldVisible,
          ),

          if (customFieldVisible) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _CustomAmountRow(
              checkoutController: checkoutController,
              totalPrice: widget.totalPrice,
              onTotalChange: widget.onTotalChange,
              setCanCheckSmall: (v) => canCheckSmall = v,
              canCheckSmall: () => canCheckSmall,
            ),
          ] else ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _SaveForLaterRow(checkoutController: checkoutController),
          ],
        ]),
      );
    });
  }
}

class _TipsHeader extends StatelessWidget {
  final JustTheController tooltipController;

  const _TipsHeader({required this.tooltipController});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(
          'delivery_tips'.tr,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

        JustTheTooltip(
          backgroundColor: Colors.black87,
          controller: tooltipController,
          preferredDirection: AxisDirection.right,
          tailLength: 14,
          tailBaseWidth: 20,
          content: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Text(
              'it_s_a_great_way_to_show_your_appreciation_for_their_hard_work'.tr,
              style: robotoRegular.copyWith(color: Colors.white),
            ),
          ),
          child: InkWell(
            onTap: () => tooltipController.showTooltip(),
            child: Icon(Icons.info_outline, size: 18, color: Theme.of(context).disabledColor),
          ),
        ),
      ]),
      const SizedBox(height: 2),

      Text(
        'tips_goes_to_deliveryman'.tr,
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).disabledColor,
        ),
      ),
    ]);
  }
}

class _TipsChipStrip extends StatelessWidget {
  final CheckoutController checkoutController;
  final double totalPrice;
  final bool customFieldVisible;

  const _TipsChipStrip({
    required this.checkoutController,
    required this.totalPrice,
    required this.customFieldVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (customFieldVisible) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: AppConstants.tips.length,
        itemBuilder: (context, index) {
          final String raw = AppConstants.tips[index];
          final bool isCustomChip = raw == 'custom';
          final String label = raw == '0'
              ? 'not_now'.tr
              : isCustomChip
                  ? raw.tr
                  : PriceConverter.convertPrice(double.parse(raw), forDM: true);

          return TipsWidget(
            title: label,
            isSelected: checkoutController.selectedTips == index,
            isSuggested: raw != '0' && !isCustomChip
                && checkoutController.mostDmTipAmount != null
                && raw == checkoutController.mostDmTipAmount.toString(),
            onTap: () async {
              double total = totalPrice - checkoutController.tips;
              checkoutController.updateTips(index);
              if (!isCustomChip) {
                checkoutController.addTips(double.parse(raw));
              }
              if (isCustomChip) {
                checkoutController.showTipsField();
              }
              checkoutController.tipController.text = checkoutController.tips.toString();

              if (checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {
                checkoutController.checkBalanceStatus(total + checkoutController.tips, 0);
              }
            },
          );
        },
      ),
    );
  }
}

class _CustomAmountRow extends StatelessWidget {
  final CheckoutController checkoutController;
  final double totalPrice;
  final Function(double x) onTotalChange;
  final void Function(bool) setCanCheckSmall;
  final bool Function() canCheckSmall;

  const _CustomAmountRow({
    required this.checkoutController,
    required this.totalPrice,
    required this.onTotalChange,
    required this.setCanCheckSmall,
    required this.canCheckSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: CustomTextField(
          titleText: 'enter_amount'.tr,
          controller: checkoutController.tipController,
          inputAction: TextInputAction.done,
          inputType: TextInputType.number,
          onChanged: (String value) async {
            double total = totalPrice;
            if (value.isNotEmpty) {
              try {
                if (double.parse(value) >= 0) {
                  if (AuthHelper.isLoggedIn()) {
                    total = total - checkoutController.tips;
                    await checkoutController.addTips(double.parse(value));
                    total = total + checkoutController.tips;
                    onTotalChange(total);
                    final double walletBalance =
                        Get.find<ProfileController>().userInfoModel?.walletBalance ?? 0;
                    if (walletBalance < total && checkoutController.paymentMethodIndex == 1) {
                      checkoutController.checkBalanceStatus(total, 0);
                      setCanCheckSmall(true);
                    } else if (walletBalance > total && canCheckSmall() && checkoutController.isPartialPay) {
                      checkoutController.checkBalanceStatus(total, 0);
                    }
                  } else {
                    checkoutController.addTips(double.parse(value));
                  }
                } else {
                  showCustomSnackBar('tips_can_not_be_negative'.tr);
                }
              } catch (_) {
                showCustomSnackBar('invalid_input'.tr);
                checkoutController.addTips(0.0);
                if (checkoutController.tipController.text.isNotEmpty) {
                  checkoutController.tipController.text = checkoutController.tipController.text
                      .substring(0, checkoutController.tipController.text.length - 1);
                  checkoutController.tipController.selection = TextSelection.collapsed(
                    offset: checkoutController.tipController.text.length,
                  );
                }
              }
            } else {
              checkoutController.addTips(0.0);
            }
          },
        ),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      InkWell(
        onTap: () {
          checkoutController.updateTips(PriceConverter.noTipIndex);
          checkoutController.showTipsField();
          if (checkoutController.isPartialPay) {
            checkoutController.changePartialPayment();
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: const Icon(Icons.clear, color: Colors.white),
        ),
      ),
    ]);
  }
}

class _SaveForLaterRow extends StatelessWidget {
  final CheckoutController checkoutController;

  const _SaveForLaterRow({required this.checkoutController});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => checkoutController.toggleDmTipSave(),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
              width: 0.7,
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                'save_it_for_later'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            SizedBox(
              height: 22, width: 22,
              child: Checkbox(
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: Theme.of(context).primaryColor,
                value: checkoutController.isDmTipSave,
                onChanged: (_) => checkoutController.toggleDmTipSave(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
