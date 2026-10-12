import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/coupon_section.dart';
import 'package:sixam_mart/features/pro/widgets/pro_coupon_benefit_banner_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/upload_prescription_widget.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/delivery_fee_tooltip.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BottomSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double total;
  final Module module;
  final double subTotal;
  final double discount;

  /// What the cart's bundles save against their members' own prices.
  ///
  /// Display only, and added to both rows at once: a bundle is billed at its bundle
  /// price, so the subtotal shows the members' total and the discount line shows the
  /// saving, while every figure the order is actually built from stays untouched.
  final double bundleSaving;
  final CouponController couponController;
  final bool taxIncluded;
  final double tax;
  final double deliveryCharge;
  final bool todayClosed;
  final bool tomorrowClosed;
  final double orderAmount;
  final double? maxCodOrderAmount;
  final int? storeId;
  final double? taxPercent;
  final Widget? checkoutButton;
  final bool isPrescriptionRequired;
  final double referralDiscount;
  final double proDiscount;
  final double proDeliveryDiscount;
  // Signed, and already 0 wherever the quote priced the tier into the fee itself.
  final double saverDeliveryAdjustment;
  final JustTheController tooltipController1;
  final JustTheController tooltipController2;
  final String deliveryChargeForView;
  final double extraChargeForToolTip;

  const BottomSection({super.key, required this.checkoutController, required this.total, required this.module, required this.subTotal,
    required this.discount, this.bundleSaving = 0, required this.couponController, required this.taxIncluded, required this.tax,
    required this.deliveryCharge, required this.todayClosed, required this.tomorrowClosed,
    required this.orderAmount, this.maxCodOrderAmount, this.storeId, this.taxPercent,
    this.checkoutButton, required this.isPrescriptionRequired, required this.referralDiscount,
    required this.proDiscount, required this.proDeliveryDiscount, required this.saverDeliveryAdjustment,
    required this.tooltipController1, required this.tooltipController2,
    required this.deliveryChargeForView, required this.extraChargeForToolTip});

  @override
  Widget build(BuildContext context) {
    bool takeAway = checkoutController.orderType == 'take_away';
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    bool uploadPredcription = (storeId != null || Get.find<SplashController>().configModel!.moduleConfig!.module!.orderAttachment!);
    return Container(
      decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ) : null,
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Column(children: [

        isDesktop ? pricingView(context: context, takeAway: takeAway) : const SizedBox(),

        SizedBox(height: isDesktop && !isGuestLoggedIn ? Dimensions.paddingSizeSmall : 0),

        /// Coupon
        isDesktop && !isGuestLoggedIn ? CouponSection(
          storeId: storeId, checkoutController: checkoutController, total: total, subTotal: subTotal,
          discount: discount, deliveryCharge: deliveryCharge,
        ) : const SizedBox(),

        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault, isDesktop && !isGuestLoggedIn ? Dimensions.paddingSizeDefault : 0,
            Dimensions.paddingSizeDefault, isDesktop ? Dimensions.paddingSizeDefault : 0,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const SizedBox.shrink(),

            !isDesktop ? pricingView(context: context, takeAway: takeAway) : const SizedBox(),
            SizedBox(height: uploadPredcription ? Dimensions.paddingSizeLarge : 0),

            uploadPredcription ? UploadPrescriptionWidget(
              checkoutController: checkoutController,
              storeId: storeId,
              isPrescriptionRequired: isPrescriptionRequired,
              tooltipController1: tooltipController1,
              tooltipController2: tooltipController2,
            ) : const SizedBox.shrink(),

            uploadPredcription ? const SizedBox(height: Dimensions.paddingSizeDefault) :const SizedBox.shrink(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            const SizedBox(),

            ResponsiveHelper.isDesktop(context) ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text( 'total_amount'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
                      ((checkoutController.taxIncluded == 1) || ((checkoutController.orderTax ?? 0) > 0)) ? Text(' ${'vat_tax_inc'.tr}', style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall
                      )) : const SizedBox(),
                      storeId == null ? const SizedBox() : Text(
                        'Once_your_order_is_confirmed_you_will_receive'.tr,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeOverSmall, color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  storeId == null ? const SizedBox() : Text(
                    'a_notification_with_your_bill_total'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeOverSmall, color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
              PriceConverter.convertAnimationPrice(
                checkoutController.viewTotalPrice,
                textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: checkoutController.isPartialPay ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).primaryColor),
              ),
            ]) : const SizedBox(),
          ]),
        ),

        ResponsiveHelper.isDesktop(context) ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: checkoutButton,
        ) : const SizedBox(),

      ]),
    );
  }

  Widget pricingView({required BuildContext context, required bool takeAway}) {
    final ProActiveBenefit? proBenefit = Get.find<ProController>().activeOfferModel?.benefit;
    final bool isPro = (Get.find<ProfileController>().userInfoModel?.proStatus ?? false);

    final bool isFreeDelivery = deliveryCharge == 0 || (couponController.coupon != null && couponController.coupon!.couponType == 'free_delivery');
    final String? discountSourceMessage = discount > 0
        ? Get.find<HappyHourController>().discountSourceMessageFor(checkoutController.store?.id) : null;

    final saverDeliveryOption = checkoutController.selectedSaverDeliveryOption;
    final String? saverDeliveryType = checkoutController.saverDeliveryType;
    // A row of its own only while the tier moves the bill: a reduction clamped away by the
    // minimum delivery charge costs nothing, and a "(-) 0" line reads as one that applied.
    final bool showSaverDeliveryOption = saverDeliveryAdjustment != 0
        && (saverDeliveryType == 'express' || saverDeliveryType == 'slightly_delay');
    final String? surgeMessage = DeliveryFeeTooltip.surgeMessage(checkoutController.surgePrice);
    // What the minimum delivery charge would not let the tier take off — the client applies
    // the tier on every path, so it explains the shortfall on every path too.
    final String? saverLimitMessage = DeliveryFeeTooltip.blockedSaverReductionMessage(
      blockedAmount: checkoutController.getBlockedSaverDeliveryReduction(
        // The same base the charge itself is clamped against, so the shortfall it explains
        // is the shortfall the row shows.
        deliveryCharge: deliveryCharge, deliveryOption: saverDeliveryOption,
      ),
      minimumDeliveryCharge: checkoutController.saverMinimumDeliveryCharge,
    );

    return Column(children: [

      Padding(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0),
        child: const ProCouponBenefitBanner(),
      ),

      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Text('billing_summary'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
      ),

      Padding(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0),
        child: Column(
          children: [
            storeId == null ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(module.addOn! ? 'subtotal'.tr : 'item_price'.tr, style: robotoRegular),
              Text(PriceConverter.convertPrice(subTotal + bundleSaving), style: robotoMedium, textDirection: TextDirection.ltr),
            ]) : const SizedBox(),
            SizedBox(height: storeId == null ? Dimensions.paddingSizeSmall : 0),

            storeId == null ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('discount'.tr, style: robotoRegular),
                if(discountSourceMessage != null) ...[
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  CustomToolTip(
                    message: discountSourceMessage,
                    size: Dimensions.fontSizeLarge,
                    preferredDirection: AxisDirection.up,
                  ),
                ],
              ]),
              Text('(-) ${PriceConverter.convertPrice(discount + bundleSaving)}', style: robotoRegular, textDirection: TextDirection.ltr),
            ]) : const SizedBox(),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            (isPro && proBenefit?.type == ProBenefitType.discount && proDiscount > 0) ? Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('discount_pro'.tr, style: robotoRegular),
                Text('(-) ${PriceConverter.convertPrice(proDiscount)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ]) : const SizedBox(),

            (couponController.discount! > 0 || couponController.freeDelivery) ? Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(couponController.coupon?.couponType == 'pro_customer' ? 'coupon_discount_pro'.tr : 'coupon_discount'.tr, style: robotoRegular),
                (couponController.coupon != null && couponController.coupon!.couponType == 'free_delivery') ? Text(
                  'free_delivery'.tr, style: robotoRegular.copyWith(color: Theme.of(context).primaryColor),
                ) : Text(
                  '(-) ${PriceConverter.convertPrice(couponController.discount)}',
                  style: robotoRegular, textDirection: TextDirection.ltr,
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ]) : const SizedBox(),

            referralDiscount > 0 ? Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('referral_discount'.tr, style: robotoRegular),

                Text(
                  '(-) ${PriceConverter.convertPrice(referralDiscount)}',
                  style: robotoRegular, textDirection: TextDirection.ltr,
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ]) : const SizedBox(),

            ((checkoutController.taxIncluded == null) || taxIncluded || (checkoutController.orderTax == 0)) ? const SizedBox() : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('vat_tax'.tr, style: robotoRegular),
              Text(('(+) ') + PriceConverter.convertPrice(tax), style: robotoRegular, textDirection: TextDirection.ltr),
            ]),
            SizedBox(height: ((checkoutController.taxIncluded == null) || taxIncluded || (checkoutController.orderTax == 0)) ? 0 : Dimensions.paddingSizeSmall),

            (!takeAway && Get.find<SplashController>().configModel!.dmTipsStatus == 1) ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('delivery_man_tips'.tr, style: robotoRegular),
                Text('(+) ${PriceConverter.convertPrice(checkoutController.tips)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ],
            ) : const SizedBox.shrink(),
            SizedBox(height: !takeAway && Get.find<SplashController>().configModel!.dmTipsStatus == 1 ? Dimensions.paddingSizeSmall : 0.0),

            storeId == null ? (checkoutController.store!.extraPackagingStatus! && Get.find<CartController>().needExtraPackage) ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('extra_packaging'.tr, style: robotoRegular),
                Text('(+) ${PriceConverter.convertPrice(checkoutController.store!.extraPackagingAmount!)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ],
            ) : const SizedBox.shrink() : const SizedBox(),
            SizedBox(height: storeId == null ? (checkoutController.store!.extraPackagingStatus! && Get.find<CartController>().needExtraPackage) ? Dimensions.paddingSizeSmall : 0.0 : 0.0),

            // Nothing is being delivered on a pickup, so the row has no fee to report —
            // and with the charge at zero it read "Delivery Fee: Free", which offers a
            // saving that was never on the table.
            (takeAway || (AuthHelper.isGuestLoggedIn() && checkoutController.guestAddress == null)) ? const SizedBox() : Row( children: [
              Text('delivery_fee'.tr, style: robotoRegular),
              const SizedBox(width: 5),

              isFreeDelivery ? const SizedBox() : (checkoutController.orderType == 'delivery') && (checkoutController.store?.selfDeliverySystem == 0)
                  && surgeMessage != null ? CustomToolTip(
                message: <String>[surgeMessage, ?saverLimitMessage].join('\n\n'),
              ) : deliveryChargeForView != PriceConverter.convertPrice(0) && (checkoutController.orderType == 'delivery') && checkoutController.extraCharge != null && (deliveryChargeForView != '0') && extraChargeForToolTip > 0 ? CustomToolTip(
                message: <String>[
                  '${'this_charge_include_extra_vehicle_charge'.tr} ${PriceConverter.convertPrice(extraChargeForToolTip)}',
                  ?saverLimitMessage,
                ].join('\n\n'),
                preferredDirection: AxisDirection.right,
                child: const Icon(Icons.info, color: Colors.blue, size: 14),
              ) : saverLimitMessage != null ? CustomToolTip(
                message: saverLimitMessage,
                child: const Icon(Icons.info, color: Colors.blue, size: 14),
              ) : const SizedBox(),


              const Spacer(),

              (checkoutController.distance == -1 || checkoutController.summaryLoading) ? const _CalculatingText() : isFreeDelivery ? Text(
                'free'.tr, style: robotoRegular.copyWith(color: Theme.of(context).primaryColor),
              ) : Text(
                '(+) ${PriceConverter.convertPrice(deliveryCharge)}', style: robotoRegular, textDirection: TextDirection.ltr,
              ),
            ]),

            (isPro && proBenefit?.type == ProBenefitType.deliveryFee && proDeliveryDiscount > 0 && !takeAway && checkoutController.orderType != 'dine_in') ? Column(children: [
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('delivery_fee_discount_pro'.tr, style: robotoRegular),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  CustomToolTip(
                    message: '${proBenefit?.offerType == ProOfferType.fullFree ? '100' : (proBenefit?.chargeDiscountPercentage ?? 0).toStringAsFixed(0)}% ${'delivery_fee_discount_applied'.tr}',
                    size: Dimensions.fontSizeLarge,
                    preferredDirection: AxisDirection.up,
                  ),
                ]),
                Text('(-) ${PriceConverter.convertPrice(proDeliveryDiscount)}', style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
            ]) : const SizedBox(),

            showSaverDeliveryOption ? Column(children: [
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${saverDeliveryType!.tr.replaceAll('_', ' ').capitalize} ${'delivery'.tr}', style: robotoRegular),
                Text(
                  '${saverDeliveryType == 'express' ? '(+) ' : '(-) '}${PriceConverter.convertPrice(saverDeliveryAdjustment.abs())}',
                  style: robotoRegular, textDirection: TextDirection.ltr,
                ),
              ]),
            ]) : const SizedBox(),

            SizedBox(height: Get.find<SplashController>().configModel!.additionalChargeStatus! && !(AuthHelper.isGuestLoggedIn() && checkoutController.guestAddress == null) ? Dimensions.paddingSizeSmall : 0),

            Get.find<SplashController>().configModel!.additionalChargeStatus! ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(
                Get.find<SplashController>().configModel!.additionalChargeName != null && Get.find<SplashController>().configModel!.additionalChargeName!.isNotEmpty
                ? Get.find<SplashController>().configModel!.additionalChargeName!
                    : (module.isTaxi == true || module.isParcel == true) ? 'service_charge'.tr : 'additional_charge'.tr,
                style: robotoRegular, overflow: TextOverflow.ellipsis, maxLines: 1,
              )),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Text(
                '(+) ${PriceConverter.convertPrice(Get.find<SplashController>().configModel!.additionCharge)}',
                style: robotoRegular, textDirection: TextDirection.ltr,
              ),
            ]) : const SizedBox(),
            SizedBox(height: checkoutController.isPartialPay ? Dimensions.paddingSizeSmall : 0),

            checkoutController.isPartialPay ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('paid_by_wallet'.tr, style: robotoRegular),
              Text('(-) ${PriceConverter.convertPrice(Get.find<ProfileController>().userInfoModel!.walletBalance!)}', style: robotoRegular, textDirection: TextDirection.ltr),
            ]) : const SizedBox(),
            SizedBox(height: checkoutController.isPartialPay ? Dimensions.paddingSizeSmall : 0),

            checkoutController.isPartialPay ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                'due_payment'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: !ResponsiveHelper.isDesktop(context) ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).primaryColor),
              ),
              PriceConverter.convertAnimationPrice(
                checkoutController.viewTotalPrice,
                textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: !ResponsiveHelper.isDesktop(context) ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).primaryColor),
              )
            ]) : const SizedBox(),

            const SizedBox(height: Dimensions.paddingSizeDefault),
            const _PolicyAgreementBox(),
          ],
        ),
      ),
    ]);
  }
}


class _CalculatingText extends StatefulWidget {
  const _CalculatingText();

  @override
  State<_CalculatingText> createState() => _CalculatingTextState();
}

class _CalculatingTextState extends State<_CalculatingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Text('${'calculating'.tr}...', style: robotoMedium.copyWith(color: Colors.red)),
      builder: (BuildContext context, Widget? text) {
        final double sweep = _controller.value * 4 - 2;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => LinearGradient(
            colors: const [Colors.red, Colors.orangeAccent, Colors.red],
            begin: Alignment(sweep - 0.6, 0),
            end: Alignment(sweep + 0.6, 0),
          ).createShader(bounds),
          child: text,
        );
      },
    );
  }
}

class _PolicyAgreementBox extends StatefulWidget {
  const _PolicyAgreementBox();

  @override
  State<_PolicyAgreementBox> createState() => _PolicyAgreementBoxState();
}

class _PolicyAgreementBoxState extends State<_PolicyAgreementBox> {
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _refundTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.getPrivacyPolicyRoute());
    _termsTap = TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.getTermsAndConditionRoute());
    _refundTap = TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.getRefundPolicyRoute());
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    _refundTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bodyColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final TextStyle linkStyle = robotoBold.copyWith(
      fontSize: Dimensions.fontSizeSmall,
      color: bodyColor,
      decoration: TextDecoration.underline,
    );
    final TextStyle baseStyle = robotoRegular.copyWith(
      fontSize: Dimensions.fontSizeDefault,
      color: bodyColor,
      height: 1.5,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Get.find<ThemeController>().darkTheme ? Theme.of(context).cardColor : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Text.rich(
        TextSpan(style: baseStyle, children: [
          TextSpan(text: '${'by_continuing_you_will_agree_with'.tr} '),
          TextSpan(text: 'privacy_policy'.tr, style: linkStyle, recognizer: _privacyTap),
          const TextSpan(text: ', '),
          TextSpan(text: 'terms_and_conditions'.tr, style: linkStyle, recognizer: _termsTap),
          TextSpan(text: ' ${'and'.tr} '),
          TextSpan(text: 'refund_policy'.tr, style: linkStyle, recognizer: _refundTap),
        ]),
      ),
    );
  }
}

// SUMMARY
// Lower half of the checkout: the billing summary with every discount, fee, tip and
// charge line and their tooltips, the delivery fee that animates while the server is
// still calculating it, the prescription upload, the total row and the policy notice.
