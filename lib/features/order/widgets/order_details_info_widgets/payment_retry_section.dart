import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_method_bottom_sheet.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The "your payment was incomplete" prompt and its two retry buttons, shown on
/// the order details page when an order's payment never completed.
///
/// Ported from `order_info_widget.dart:805-921` — the pre-4.2 order details body,
/// which is still in the tree but orphaned (nothing references `OrderInfoWidget`).
/// The rewrite to `OrderDetailsNewScreen` dropped this block while keeping the
/// `getPaymentFailedDetails` call that feeds it, so the data was being fetched and
/// discarded and a customer whose payment failed had no way to retry.
///
/// The visibility rules are the original ones, in the original order:
///
///  1. partial payment whose second leg is unpaid and isn't cash on delivery
///     → always offer the buttons;
///  2. otherwise an offline payment → never offer them (the deposit is with the
///     store, and paying again would charge twice);
///  3. otherwise the general case — unpaid, not cancelled, and not a method that
///     settles elsewhere (cash on delivery, wallet).
///
/// Only the *retry* half of the original is ported. The payment-method rows and
/// the offline deposit panel that surrounded it in `order_info_widget` are not:
/// [PaymentMethodSection] already renders the method on this screen, so bringing
/// them across would show the same information twice.
class PaymentRetrySection extends StatelessWidget {
  final OrderModel order;

  const PaymentRetrySection({super.key, required this.order});

  /// The second payment leg of a partial payment, or null when the API didn't
  /// send one.
  ///
  /// The original indexed `payments![1]` unconditionally in five places;
  /// `payments` is legitimately `[]` on live orders (see
  /// `test/fixtures/live/order_track.json`), which made that a RangeError rather
  /// than a missed branch.
  Payments? get _partialDueLeg =>
      (order.payments?.length ?? 0) > 1 ? order.payments![1] : null;

  bool get _isPartialPayment => order.paymentMethod == 'partial_payment';

  /// Branch 1 — a partial payment still owing its second leg.
  ///
  /// The original excluded a `cash_on_delivery` second leg because there is
  /// nothing to settle online. `offline_payment` is excluded here for the same
  /// reason and is the one rule not carried over verbatim: this branch is
  /// evaluated *before* the offline branch below, so a partial payment being
  /// settled by bank deposit would otherwise reach the retry buttons and charge
  /// a customer who has already paid. The offline record cannot be used to tell
  /// the two apart — `stores/track` returns `offline_payment: null` even for an
  /// order with a deposit pending verification.
  bool get _showForPartialPayment {
    final Payments? dueLeg = _partialDueLeg;
    return _isPartialPayment
        && order.orderStatus != 'canceled'
        && dueLeg != null
        && dueLeg.paymentStatus == 'unpaid'
        && dueLeg.paymentMethod != 'cash_on_delivery'
        && dueLeg.paymentMethod != 'offline_payment';
  }

  /// Branch 2 — an offline payment sits at `unpaid` until the store verifies the
  /// deposit, so it must never reach the retry buttons.
  bool get _isOfflinePayment =>
      order.paymentMethod == 'offline_payment'
      || (_isPartialPayment && order.offlinePayment != null);

  /// Branch 3 — the general case, unchanged from the original.
  bool get _showForFailedPayment {
    final bool partialWithFailedDigitalLeg = _isPartialPayment
        && order.orderStatus == 'failed'
        && _partialDueLeg?.paymentMethod == 'digital_payment';

    final bool unpaidAndRetryable = order.paymentStatus == 'unpaid'
        && order.orderStatus != 'canceled'
        && order.paymentMethod != 'cash_on_delivery'
        && order.paymentMethod != 'wallet'
        && order.paymentMethod != 'partial_payment';

    return partialWithFailedDigitalLeg || unpaidAndRetryable;
  }

  /// Whether this order's payment can still be retried from here — the three
  /// branches above, in their original order.
  ///
  /// Public so the branch rules can be tested directly: each one is a money
  /// decision, and getting branch 2 wrong charges a customer twice.
  bool get offersRetry {
    if (_showForPartialPayment) return true;
    if (_isOfflinePayment) return false;
    return _showForFailedPayment;
  }

  @override
  Widget build(BuildContext context) {
    if (!offersRetry) return const SizedBox();
    return _PaymentRetryPrompt(trackOrderId: order.id?.toString());
  }
}

class _PaymentRetryPrompt extends StatelessWidget {
  /// The id of the order this screen is showing, used to re-track after a switch
  /// to cash. Deliberately not `paymentModel.orderID`: `timerTrackOrder` drops
  /// responses whose id doesn't match the active screen, so a differently
  /// formatted id would silently skip the refresh that hides this section.
  final String? trackOrderId;

  const _PaymentRetryPrompt({required this.trackOrderId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      // The original's three states: nothing to pay, mid-request, or the buttons.
      //
      // `paymentModel != null` was the original guard, and it is no longer
      // enough. `ApiClient.unwrapEnvelope` leaves the envelope intact when
      // `content` is null, so a "nothing to pay" answer now parses into a
      // non-null model with every field null instead of throwing into the
      // repository's bare catch — which is how it used to end up null.
      //
      // It must also be *this* order's payment. `paymentModel` is a singleton and
      // the dashboard fills it account-wide with `getPaymentFailedDetails(null)`,
      // so it can hold an unrelated purchase — including a rental trip, whose
      // `trip_id` lands in the same `orderID` field. Without the match, these
      // buttons would settle a different order than the one on screen.
      final PaymentModel? payment = orderController.paymentModel;
      final bool hasPayableOrder = payment?.orderID != null
          && !CheckoutController.isTripPayment(payment)
          && payment!.orderID == trackOrderId
          && orderController.trackModel?.orderStatus != 'canceled';
      if (!hasPayableOrder) return const SizedBox();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Text(
          'your_payment_was_incomplete_Please_choose_an_option_below_to_complete_your_transaction'.tr,
          style: robotoRegular, textAlign: TextAlign.start,
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        orderController.isPaymentLoading
            ? const Center(child: CircularProgressIndicator())
            : _PaymentRetryButtons(trackOrderId: trackOrderId),
      ]);
    });
  }
}

class _PaymentRetryButtons extends StatelessWidget {
  final String? trackOrderId;

  const _PaymentRetryButtons({required this.trackOrderId});

  /// Switching to cash settles the order without leaving this page: the order is
  /// re-tracked in place and the section disappears on the next build.
  void _switchToCod(OrderController orderController) {
    final double? maxCod = orderController.paymentModel!.maxCodOrderAmount;
    final double? amount = orderController.paymentModel!.orderAmount;
    final bool isParcel = orderController.paymentModel!.orderType == 'parcel';
    // Parcels have no cash ceiling; everything else is capped unless the config
    // leaves the cap unset or at zero.
    final bool withinCodLimit = isParcel
        || maxCod == null || maxCod == 0 || (amount != null && amount < maxCod);

    if (!withinCodLimit) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      showCustomSnackBar('${'you_cant_order_more_then'.tr} ${PriceConverter.convertPrice(maxCod)} ${'in_cash_on_delivery'.tr}');
      return;
    }

    // `fromOrderDetails: true` drives `isPaymentLoading` rather than the screen's
    // own loader, so the spinner replaces these buttons instead of blanking the
    // page.
    orderController.switchToCOD(
      orderController.paymentModel!.orderID,
      guestId: orderController.paymentModel!.guestId,
      fromOrderDetails: true,
    ).then((bool success) {
      if (!success) return;
      final String? refreshId = trackOrderId ?? orderController.paymentModel?.orderID;
      if (refreshId != null) {
        orderController.timerTrackOrder(refreshId, contactNumber: orderController.paymentModel?.contactNumber);
      }
      if (AuthHelper.isLoggedIn()) {
        orderController.getOrders(OrderListType.running, 1);
        orderController.getOrders(OrderListType.previous, 1);
        final double total = ((orderController.paymentModel!.orderAmount! / 100)
            * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
        Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
      }
    });
  }

  Future<void> _payAgain(BuildContext context, OrderController orderController) async {
    final Widget sheet = PaymentMethodBottomSheet(
      isCashOnDeliveryActive: orderController.paymentModel?.isCashOnDeliveryActive ?? false,
      isDigitalPaymentActive: orderController.paymentModel?.isDigitalPaymentActive ?? false,
      totalPrice: orderController.paymentModel?.orderAmount ?? 0,
      isOfflinePaymentActive: orderController.paymentModel?.isOfflinePaymentActive ?? false,
      paymentModel: orderController.paymentModel,
    );
    if (ResponsiveHelper.isDesktop(context)) {
      await Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    } else {
      await Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    }

    // Paying by cash or wallet settles the order without leaving this page, so
    // nothing else would refresh it — the section would linger until the
    // screen's 10s track timer happened to fire. Both sources this section reads
    // have to be re-fetched: the order for the visibility rules, and the payment
    // details, which are otherwise loaded once in initState and never again.
    if (trackOrderId == null) return;
    await orderController.getPaymentFailedDetails(trackOrderId);
    await orderController.timerTrackOrder(trackOrderId!, contactNumber: orderController.paymentModel?.contactNumber);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      final bool showCod = orderController.paymentModel?.isCashOnDeliveryActive ?? false;
      // A guest has no account to pay from, so only the cash switch is offered —
      // the same split the digital-payment-failed screen makes.
      final bool showPayAgain = !AuthHelper.isGuestLoggedIn();

      return Row(children: [
        if (showCod) Expanded(
          child: CustomButton(
            buttonText: 'switch_to_cod'.tr,
            onPressed: () => _switchToCod(orderController),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
            textColor: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        SizedBox(width: showCod && showPayAgain ? Dimensions.paddingSizeSmall : 0),

        if (showPayAgain) Expanded(
          child: CustomButton(
            buttonText: 'pay_again'.tr,
            onPressed: () => _payAgain(context, orderController),
          ),
        ),
      ]);
    });
  }
}
