import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/coupon_section.dart';
import 'package:sixam_mart/features/checkout/widgets/delivery_section.dart';
import 'package:sixam_mart/features/checkout/widgets/deliveryman_tips_section.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_create_account.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_section.dart';
import 'package:sixam_mart/features/checkout/widgets/saver_delivery_time_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/time_slot_section.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/features/checkout/widgets_new/delivery_type_section.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

import 'upload_prescription_widget.dart';

class TopSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double charge;
  final double deliveryCharge;
  final List<DropdownItem<int>> addressList;
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  final  double price;
  final double discount;
  final double addOns;
  final int? storeId;
  final List<AddressModel> address;
  final List<CartModel?>? cartList;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final bool isOfflinePaymentActive;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final JustTheController tooltipController1;
  final JustTheController tooltipController2;
  final JustTheController dmTipsTooltipController;
  final TextEditingController guestPasswordController;
  final TextEditingController guestConfirmPasswordController;
  final FocusNode guestPasswordNode;
  final FocusNode guestConfirmPasswordNode;
  final double variationPrice;
  final String deliveryChargeForView;
  final double badWeatherCharge;
  final double extraChargeForToolTip;
  final bool proFreeDelivery;

  const TopSection({
    super.key, required this.deliveryCharge, required  this.charge, required this.tomorrowClosed,
    required this.todayClosed, required this.price, required this.discount, required this.addOns,
    required this.addressList, required this.checkoutController,
    this.module, this.storeId, required this.address, required this.cartList,
    required this.isCashOnDeliveryActive, required this.isDigitalPaymentActive, required this.isWalletActive,
    required this.total, required this.isOfflinePaymentActive, required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController, required this.guestNumberNode,
    required this.guestEmailController, required this.guestEmailNode, required this.tooltipController1,
    required this.tooltipController2, required this.dmTipsTooltipController, required this.guestPasswordController, required this.guestConfirmPasswordController,
    required this.guestPasswordNode, required this.guestConfirmPasswordNode, required this.variationPrice, required this.deliveryChargeForView,
    required this.badWeatherCharge, required this.extraChargeForToolTip, this.proFreeDelivery = false,
  });

  @override
  Widget build(BuildContext context) {
    bool takeAway = (checkoutController.orderType == 'take_away');
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();

    return Container(
      decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ) : null,
      child: Column(children: [

        !AuthHelper.isGuestLoggedIn() && storeId != null ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
          child: UploadPrescriptionWidget(
            checkoutController: checkoutController, storeId: storeId, isPrescriptionRequired: storeId != null,
            tooltipController1: tooltipController1, tooltipController2: tooltipController2,
          ),
        ) : const SizedBox(),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        // delivery option
        DeliveryTypeSection(
          homeDeliveryEnabled: storeId != null
              || (Get.find<SplashController>().configModel!.homeDeliveryStatus == 1 && checkoutController.store!.delivery!),
          takeAwayEnabled: storeId == null
              && Get.find<SplashController>().configModel!.takeawayStatus == 1
              && checkoutController.store!.takeAway!,
          total: total,
          charge: charge,
        ),

        /// Time Slot (with optional embedded Saver delivery options)
        GetBuilder<CheckoutController>(builder: (controller) {
          final bool showTimeSlot = TimeSlotSection.shouldRender(
            storeId: storeId, checkoutController: controller, cartList: cartList,
          );
          // Saver delivery options apply only to instant delivery — hide them once a schedule slot is chosen.
          final bool showSaver = controller.isInstantDelivery && SaverDeliveryTimeWidget.canShow(
            controller: controller, deliveryCharge: deliveryCharge, originalDeliveryCharge: charge, proFreeDelivery: proFreeDelivery,
          );

          if(showTimeSlot) {
            return Column(
              children: [
                TimeSlotSection(
                  storeId: storeId, checkoutController: controller, cartList: cartList, tooltipController2: tooltipController2,
                  tomorrowClosed: tomorrowClosed, todayClosed: todayClosed, module: module,
                  trailingContent: showSaver ? SaverDeliveryTimeWidget(
                    checkoutController: controller, deliveryCharge: deliveryCharge, originalDeliveryCharge: charge, proFreeDelivery: proFreeDelivery,
                  ) : null,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              ],
            );
          }

          if(showSaver) {
            return Column(children: [
              CustomCardCheckout(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: SaverDeliveryTimeWidget(
                  checkoutController: controller, deliveryCharge: deliveryCharge, originalDeliveryCharge: charge, proFreeDelivery: proFreeDelivery,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ]);
          }

          return const SizedBox();
        }),

        ///delivery section
        DeliverySection(checkoutController: checkoutController, address: address, addressList: addressList,
          guestNameTextEditingController: guestNameTextEditingController, guestNumberTextEditingController: guestNumberTextEditingController,
          guestNumberNode: guestNumberNode, guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
        ),

        SizedBox(height: !takeAway ? isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeLarge : takeAway && isGuestLoggedIn ? Dimensions.paddingSizeLarge : 0),

        ///Create Account with existing info
        isGuestLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus! ? GuestCreateAccount(
          guestPasswordController: guestPasswordController, guestConfirmPasswordController: guestConfirmPasswordController,
          guestPasswordNode: guestPasswordNode, guestConfirmPasswordNode: guestConfirmPasswordNode,
        ) : const SizedBox(),
        SizedBox(height: isGuestLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus! ? Dimensions.paddingSizeSmall : 0),

        /// Coupon..
        !isDesktop && !isGuestLoggedIn ? CouponSection(
          storeId: storeId, checkoutController: checkoutController, total: total, price: price,
          discount: discount, addOns: addOns, deliveryCharge: deliveryCharge, variationPrice: variationPrice,
        ) : const SizedBox(),

        ///DmTips..
        DeliveryManTipsSection(
          takeAway: takeAway, tooltipController3: dmTipsTooltipController,
          totalPrice: total, onTotalChange: (double price) => total + price, storeId: storeId,
        ),
        SizedBox(height: !takeAway && Get.find<SplashController>().configModel!.dmTipsStatus == 1 ? Dimensions.paddingSizeLarge : 0),

        ///Payment..
        CustomCardCheckout(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: PaymentSection(
            storeId: storeId, isCashOnDeliveryActive: isCashOnDeliveryActive, isDigitalPaymentActive: isDigitalPaymentActive,
            isWalletActive: isWalletActive, total: total, checkoutController: checkoutController, isOfflinePaymentActive: isOfflinePaymentActive,
          ),
        ),
        SizedBox(height: isDesktop ? Dimensions.paddingSizeLarge : 0),

      ]),
    );
  }
}
