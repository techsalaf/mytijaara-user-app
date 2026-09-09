import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/checkout/screens/digital_payment_failed_screen.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class OrderSuccessfulScreen extends StatefulWidget {
  final String? orderID;
  final String? contactPersonNumber;
  final bool? createAccount;
  final String guestId;
  const OrderSuccessfulScreen({super.key, required this.orderID, this.contactPersonNumber, this.createAccount = false, required this.guestId});

  @override
  State<OrderSuccessfulScreen> createState() => _OrderSuccessfulScreenState();
}

class _OrderSuccessfulScreenState extends State<OrderSuccessfulScreen> {

  String? orderId;

  @override
  void initState() {
    super.initState();

    orderId = widget.orderID!;
    if(widget.orderID != null) {
      if(widget.orderID!.contains('?')){
        var parts = widget.orderID!.split('?');
        String id = parts[0].trim();
        orderId = id;
      }
    }

    if(GetPlatform.isWeb) {
      Get.find<OrderController>().getPaymentFailedDetails(orderId);
    } else if(!widget.createAccount! && !GetPlatform.isWeb) {
      OrderController orderController = Get.find<OrderController>();

      Get.find<OrderController>().trackOrder(orderId.toString(), null, false, contactNumber: widget.contactPersonNumber).then((v) {
        if(orderController.trackModel != null) {
          bool success = orderController.trackModel!.paymentStatus == 'paid' || orderController.trackModel!.paymentMethod == 'cash_on_delivery'
              || orderController.trackModel!.paymentMethod == 'partial_payment' || orderController.trackModel!.paymentMethod == 'wallet';

          if (!success && !Get.isDialogOpen! && orderController.trackModel!.orderStatus != 'canceled' && Get.currentRoute.startsWith(RouteHelper.orderSuccess)) {
            Get.find<OrderController>().getPaymentFailedDetails(orderId);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await Get.offAllNamed(RouteHelper.getInitialRoute());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
        body: GetBuilder<OrderController>(builder: (orderController){
          double total = 0;
          bool success = true;
          bool parcel = false;
          bool takeAway = false;
          // double? maximumCodOrderAmount;
          if(orderController.trackModel != null) {
            total = ((orderController.trackModel!.orderAmount! / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
            success = orderController.trackModel!.paymentStatus == 'paid' || orderController.trackModel!.paymentMethod == 'cash_on_delivery'
              || orderController.trackModel!.paymentMethod == 'partial_payment' || orderController.trackModel!.paymentMethod == 'wallet';
            parcel = orderController.trackModel!.orderType == 'parcel';
            takeAway = orderController.trackModel!.orderType == 'take_away';
          }

          if(orderController.paymentModel != null && GetPlatform.isWeb) {
            success = orderController.paymentModel!.paymentStatus == 'paid'|| orderController.paymentModel!.paymentMethod == 'cash_on_delivery'
                /*|| orderController.trackModel!.paymentMethod == 'partial_payment' */ || orderController.paymentModel!.paymentMethod == 'wallet';
            total = ((orderController.paymentModel!.orderAmount! / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
            parcel = orderController.paymentModel!.orderType == 'parcel';
            takeAway = orderController.paymentModel!.orderType == 'take_away';

          }

          if(GetPlatform.isWeb) {
            return orderController.paymentModel != null ? SingleChildScrollView(
              child: FooterView(child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: success
                    ? _orderSuccessfulContent(total: total, parcel: parcel, takeAway: takeAway, success: success)
                    : const PaymentIncompleteView(),
              )),
            ) : const Center(child: CircularProgressIndicator());
          }

          return orderController.trackModel != null || widget.createAccount! ? Center(
            child: SingleChildScrollView(
              child: FooterView(child: SizedBox(width: Dimensions.webMaxWidth,
                  child: GetPlatform.isWeb && orderController.paymentModel != null
                      ? const PaymentIncompleteView()
                      : _orderSuccessfulContent(total: total, parcel: parcel, takeAway: takeAway, success: success),
              )),
            ),
          ) : const Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }

  Widget _orderSuccessfulContent({required double total, required bool parcel, required bool takeAway, required bool success}) {
    return Container(
      decoration: !ResponsiveHelper.isDesktop(context) ? null : BoxDecoration(
        borderRadius: const  BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 5, spreadRadius: 1)],
      ),
      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        Image.asset(success ? Images.checked : Images.warning, width: 70, height: 100),

        !AuthHelper.isGuestLoggedIn() ? SelectableText('${'order'.tr} #$orderId', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)) : const SizedBox(),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        AuthHelper.isGuestLoggedIn() ? SelectableText(
          '${'order_id'.tr}: $orderId',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
        ) : const SizedBox(),

        Text(
          success ? parcel ? 'you_placed_the_parcel_request_successfully'.tr
              : 'you_placed_the_order_successfully'.tr : 'your_order_is_failed_to_place'.tr,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        widget.createAccount! ? Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              'and_create_account_successfully'.tr,
              style: robotoMedium,
            ),
            InkWell(
              onTap: () {
                if(ResponsiveHelper.isDesktop(context)){
                  Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                }else{
                  Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Text('sign_in'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
              ),
            ),
          ]),
        ) : const SizedBox(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
          child: Text(
            success ? parcel ? 'your_parcel_request_is_placed_successfully'.tr : takeAway ? 'your_takeaway_order_has_been_placed_successfully'.tr
                : 'your_order_is_placed_successfully'.tr : 'your_order_is_failed_to_place_because'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            textAlign: TextAlign.center,
          ),
        ),

        _ProSavingsView(success: success),

        ResponsiveHelper.isDesktop(context) && (success && Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 && total.floor() > 0 ) && AuthHelper.isLoggedIn()  ? Column(children: [

          Image.asset(Get.find<ThemeController>().darkTheme ? Images.congratulationDark : Images.congratulationLight, width: 150, height: 150),

          Text('congratulations'.tr , style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Text(
              '${'you_have_earned'.tr} ${total.floor().toString()} ${'points_it_will_add_to'.tr}',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge,color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center,
            ),
          ),

        ]) : const SizedBox.shrink() ,
        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: CustomButton(
              width: ResponsiveHelper.isDesktop(context) ? 300 : double.infinity,
              color: /*ResponsiveHelper.isDesktop(context) ? Theme.of(context).disabledColor :*/ Theme.of(context).primaryColor,
              buttonText: 'back_to_home'.tr, onPressed: () {
            if(AuthHelper.isLoggedIn()) {
              Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
            }
            Get.offAllNamed(RouteHelper.getInitialRoute());
          }),
        ),
      ]),
    );
  }
}

// Shows the amount the user saved as a pro member on this order.
// Visible only when the pro feature is enabled, the user is a pro member,
// the order succeeded and the order carries a positive pro saving.
class _ProSavingsView extends StatelessWidget {
  final bool success;
  const _ProSavingsView({required this.success});

  @override
  Widget build(BuildContext context) {
    final OrderModel? order = Get.find<OrderController>().trackModel;
    final double proSavings = (order?.proDiscount ?? 0) + (order?.deliveryFeeReductionAmount ?? 0);
    final bool isProUser = Get.find<SplashController>().proStaus && Get.find<ProfileController>().proStatus;

    if (!success || !isProUser || proSavings <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Image.asset(Images.proPlanCrown, height: 18, width: 18, color: const Color(0xFFFFC107)),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Flexible(
          child: Text(
            '${'you_saved'.tr} ${PriceConverter.convertPrice(proSavings)} ${'with_pro'.tr}',
            textAlign: TextAlign.center,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.deepPurpleAccent),
          ),
        ),
      ]),
    );
  }
}
