part of '../screens/order_details_new_screen.dart';

class _OrderDetailsInfo extends StatefulWidget {
  final OrderModel order;
  final double total;
  final List<OrderDetailsModel> orderDetails;
  final BillingValues billing;
  final bool? isDragable;

  const _OrderDetailsInfo({
    required this.order,
    required this.total,
    required this.orderDetails,
    required this.billing,
    this.isDragable = false,
  });

  @override
  State<_OrderDetailsInfo> createState() => _OrderDetailsInfoState();
}

class _OrderDetailsInfoState extends State<_OrderDetailsInfo> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.08);
    final hasItems = widget.orderDetails.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: widget.isDragable! ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.isDragable! && widget.order.deliveryMan != null) ...[
          DeliveryManSection(order: widget.order),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        OrderItemStatusSection(order: widget.order, total: widget.total),

        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(
              PriceConverter.convertPrice(widget.total),
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            AnimatedRotation(
              turns: _isExpanded ? 0 : -0.5,
              duration: const Duration(milliseconds: 300),
              child: Container(width: 24, height: 24,
                decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ]),
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Divider(height: 20, thickness: 1, color: dividerColor),

              if (widget.order.scheduled == 1) ...[
                ScheduledOrderBanner(order: widget.order),
                Divider(height: 20, thickness: 1, color: dividerColor),
              ],

              if (!widget.isDragable! && widget.order.deliveryMan != null) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                DeliveryManSection(order: widget.order),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],

              StoreUserAddressBlock(order: widget.order),

              if ((widget.order.deliveryInstruction != null || widget.order.unavailableItemNote != null || widget.order.orderNote != null || (widget.order.bringChangeAmount != null && widget.order.bringChangeAmount! > 0))) ...[
                const SizedBox(height: Dimensions.paddingSizeDefault),
                NotesCollapsible(order: widget.order),
              ],
            ]),
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        if (hasItems) ...[
          Divider(height: 40, thickness: 1, color: dividerColor),
          ItemInfoSection(orderDetails: widget.orderDetails),
        ],

        if((widget.order.payments != null && widget.order.payments!.isNotEmpty) || (widget.order.paymentMethod != null && widget.order.paymentMethod!.isNotEmpty)) ...[
          Divider(height: 40, thickness: 1, color: dividerColor),
          if(widget.order.payments != null && widget.order.payments!.isNotEmpty)
            PaymentMethodSection(payments: widget.order.payments!)
          else
            PaymentMethodSection(payments: [Payments(paymentMethod: widget.order.paymentMethod, amount: widget.order.orderAmount)]),
        ],

        if (widget.order.orderType == 'parcel' && widget.order.parcelCategory != null) ...[
          Divider(height: 40, thickness: 1, color: dividerColor),
          ParcelTypeSection(order: widget.order),
        ],

        Divider(height: 40, thickness: 1, color: dividerColor),
        BillingSummarySection(order: widget.order, billing: widget.billing),

      ]),
    );
  }
}

class _BottomView extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final bool parcel;
  final double totalPrice;
  final double subtotal;
  final BillingValues billing;
  final bool isCashOnDeliveryActive;
  final double? maxCodOrderAmount;
  final String? contactNumber;
  final VoidCallback onTrackOrder;

  const _BottomView({
    required this.orderController,
    required this.order,
    required this.parcel,
    required this.totalPrice,
    required this.subtotal,
    required this.billing,
    required this.isCashOnDeliveryActive,
    required this.maxCodOrderAmount,
    required this.contactNumber,
    required this.onTrackOrder,
  });

  @override
  Widget build(BuildContext context) {
    return parcel ? _ParcelBottomView(orderController: orderController, order: order, totalPrice: totalPrice, subtotal: subtotal, billing: billing, isCashOnDeliveryActive: isCashOnDeliveryActive,
    maxCodOrderAmount: maxCodOrderAmount, contactNumber: contactNumber, onTrackOrder: onTrackOrder)
    : _RegularBottomView(orderController: orderController, order: order, totalPrice: totalPrice, subtotal: subtotal, billing: billing, isCashOnDeliveryActive: isCashOnDeliveryActive,
    maxCodOrderAmount: maxCodOrderAmount, contactNumber: contactNumber, onTrackOrder: onTrackOrder);
  }
}

class _RegularBottomView extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final double totalPrice;
  final double subtotal;
  final BillingValues billing;
  final bool isCashOnDeliveryActive;
  final double? maxCodOrderAmount;
  final String? contactNumber;
  final VoidCallback onTrackOrder;

  const _RegularBottomView({required this.orderController, required this.order, required this.totalPrice, required this.subtotal, required this.billing,
  required this.isCashOnDeliveryActive, required this.maxCodOrderAmount, required this.contactNumber, required this.onTrackOrder});

  @override
  Widget build(BuildContext context) {
    final showCancelButton = _ButtonVisibilityHelper.shouldShowCancelButton(order, orderController);
    final showReviewButton = _ButtonVisibilityHelper.shouldShowReviewButton(order, orderController);
    final showProButton = _ButtonVisibilityHelper.isProOrder(order);
    final showAnything = orderController.showCancelled || showCancelButton || showReviewButton || showProButton;
    final proSavings = _ButtonVisibilityHelper.proSavings(order, billing);

    if (!showAnything) return const SizedBox.shrink();

    return _StickyBottomBar(
      child: Column(children: [
        if (!orderController.showCancelled) ...[
          if (proSavings > 0) ProSavingsBannerWidget(amount: proSavings, margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall)),

          if (showCancelButton)
            _CancelButtonRow(
              parcel: false,
              onCancelPressed: () {
                orderController.setOrderCancelReason('');
                Get.dialog(CancellationDialogueWidget(
                  orderId: order.id,
                  contactNumber: contactNumber,
                ));
              },
            ),
        ] else
          const _CancelledOrderView(),

        if (showReviewButton)
          _ReviewButton(orderController: orderController, order: order),
      ]),
    );
  }
}

class _ParcelBottomView extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final double totalPrice;
  final double subtotal;
  final BillingValues billing;
  final bool isCashOnDeliveryActive;
  final double? maxCodOrderAmount;
  final String? contactNumber;
  final VoidCallback onTrackOrder;

  const _ParcelBottomView({
    required this.orderController,
    required this.order,
    required this.totalPrice,
    required this.subtotal,
    required this.billing,
    required this.isCashOnDeliveryActive,
    required this.maxCodOrderAmount,
    required this.contactNumber,
    required this.onTrackOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final showCancelButton = _ButtonVisibilityHelper.shouldShowParcelCancelButton(order, orderController);
    final showReturnOtp = _ButtonVisibilityHelper.shouldShowParcelReturnOtp(order);
    final showReviewButton = _ButtonVisibilityHelper.shouldShowParcelReviewButton(order);
    final showSwitchToCodButton = _ButtonVisibilityHelper.shouldShowSwitchToCodButton(order, isCashOnDeliveryActive);
    final showProButton = _ButtonVisibilityHelper.isProOrder(order);
    final showAnything = orderController.showCancelled
        || showCancelButton
        || showReturnOtp
        || showReviewButton
        || showSwitchToCodButton
        || showProButton;
    final proSavings = _ButtonVisibilityHelper.proSavings(order, billing);

    if (!showAnything) return const SizedBox.shrink();

    return _StickyBottomBar(
      child: Column(children: [
        if (!orderController.showCancelled) ...[
          if (proSavings > 0) ProSavingsBannerWidget(amount: proSavings, margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall)),

          if (showCancelButton)
            _CancelButtonRow(
              parcel: true,
              onCancelPressed: () {
                final isBeforePickup = ['pending', 'accepted', 'confirmed'].contains(order.orderStatus);
                final cancellationSheet = CancellationReasonBottomSheet(
                  isBeforePickup: isBeforePickup,
                  orderId: order.id,
                  contactNumber: contactNumber,
                  chargePayerSender: order.chargePayer == 'sender',
                  orderAmount: order.orderAmount ?? 0,
                  dmTips: order.dmTips ?? 0,
                );
                if (isDesktop) {
                  Get.dialog(Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: cancellationSheet,
                  ));
                } else {
                  showCustomBottomSheet(child: cancellationSheet);
                }
              },
            ),

          if (showSwitchToCodButton)
            _SwitchToCodButton(
              orderController: orderController,
              order: order,
              parcel: true,
              totalPrice: totalPrice,
              maxCodOrderAmount: maxCodOrderAmount,
            ),
        ] else
          const _CancelledOrderView(),

        if (showReturnOtp) ...[
          _ParcelReturnOtpDisplay(order: order),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          _ParcelReturnSlider(
            orderController: orderController,
            order: order,
            contactNumber: contactNumber,
          ),
        ],

        if (showReviewButton)
          _ReviewButton(orderController: orderController, order: order),
      ]),
    );
  }
}

class _StickyBottomBar extends StatelessWidget {
  final Widget child;

  const _StickyBottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: child,
    );
  }
}

class _CancelButtonRow extends StatelessWidget {
  final bool parcel;
  final VoidCallback onCancelPressed;

  const _CancelButtonRow({required this.parcel, required this.onCancelPressed});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Row(children: [
        Expanded(
          child: CustomButton(
            color: errorColor.withValues(alpha: 0.10),
            onPressed: onCancelPressed,
            buttonText: parcel ? 'cancel_delivery'.tr : 'cancel_order'.tr,
            textColor: errorColor,
          ),
        ),
      ]),
    );
  }
}

class _SwitchToCodButton extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;
  final bool parcel;
  final double totalPrice;
  final double? maxCodOrderAmount;

  const _SwitchToCodButton({
    required this.orderController,
    required this.order,
    required this.parcel,
    required this.totalPrice,
    required this.maxCodOrderAmount,
  });

  bool _canSwitchToCashOnDelivery() {
    if (parcel) return true;
    return (maxCodOrderAmount != null && totalPrice < maxCodOrderAmount!) || maxCodOrderAmount == null || maxCodOrderAmount == 0;
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      buttonText: 'switch_to_cod'.tr,
      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      onPressed: () {
        Get.dialog(ConfirmationDialog(
          icon: Images.warning,
          description: 'are_you_sure_to_switch'.tr,
          onYesPressed: () {
            if (_canSwitchToCashOnDelivery()) {
              orderController.switchToCOD(order.id.toString());
            } else {
              if (Get.isDialogOpen!) Get.back();
              showCustomSnackBar('${'you_cant_order_more_then'.tr} ${PriceConverter.convertPrice(maxCodOrderAmount)} ${'in_cash_on_delivery'.tr}');
            }
          },
        ));
      },
    );
  }
}

class _CancelledOrderView extends StatelessWidget {
  const _CancelledOrderView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Text(
        'order_cancelled'.tr,
        style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final OrderController orderController;
  final OrderModel order;

  const _ReviewButton({required this.orderController, required this.order});

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      buttonText: 'review'.tr,
      onPressed: () {
        final orderDetailsList = <OrderDetailsModel>[];
        final orderDetailsIdList = <int?>[];

        for (var orderDetail in orderController.orderDetails!) {
          if (!orderDetailsIdList.contains(orderDetail.itemDetails!.id)) {
            orderDetailsList.add(orderDetail);
            orderDetailsIdList.add(orderDetail.itemDetails!.id);
          }
        }

        Get.toNamed(RouteHelper.getReviewRoute(), arguments: RateReviewScreen(
          orderDetailsList: orderDetailsList,
          deliveryMan: order.deliveryMan,
          orderID: order.id,
          reviews: order.reviews,
        ));
      },
    );
  }
}

class _ParcelReturnOtpDisplay extends StatelessWidget {
  final OrderModel order;

  const _ParcelReturnOtpDisplay({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(
        'parcel_returned_otp'.tr,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
      ),

      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraSmall,
            vertical: 2,
          ),
          child: Text(
            order.parcelCancellation!.returnOtp.toString(),
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
        ),
      ),
    ]);
  }
}

class _ParcelReturnSlider extends StatefulWidget {
  final OrderController orderController;
  final OrderModel order;
  final String? contactNumber;

  const _ParcelReturnSlider({
    required this.orderController,
    required this.order,
    required this.contactNumber,
  });

  @override
  State<_ParcelReturnSlider> createState() => _ParcelReturnSliderState();
}

class _ParcelReturnSliderState extends State<_ParcelReturnSlider> {
  static const double _sliderHeight = 60;
  static const double _sliderButtonSize = 50;
  static const double _sliderRadius = 10;
  static const double _sliderIconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - (Dimensions.paddingSizeDefault * 2);
    return SliderButton(
      label: Text(
        'parcel_received'.tr,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
      ),
      dismissThresholds: 0.5,
      dismissible: false,
      shimmer: true,
      width: width,
      height: _sliderHeight,
      buttonSize: _sliderButtonSize,
      radius: _sliderRadius,
      icon: Center(
        child: Icon(
          Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_arrow_left,
          color: Theme.of(context).cardColor,
          size: _sliderIconSize,
        ),
      ),
      isLtr: Get.find<LocalizationController>().isLtr,
      boxShadow: const BoxShadow(blurRadius: 0),
      buttonColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
      baseColor: Theme.of(context).primaryColor,
      action: () async {
        final isSuccess = await widget.orderController.submitParcelReturn(
          orderId: widget.order.id!,
          returnOtp: widget.order.parcelCancellation!.returnOtp!,
          contactNumber: widget.contactNumber,
        );

        if (mounted && isSuccess) {
          showCustomSnackBar('parcel_returned_successfully'.tr, isError: false);
        }
      },
    );
  }
}

class _ButtonVisibilityHelper {
  static bool isProOrder(OrderModel order) {
    return (order.proDiscount ?? 0) > 0
        || (order.deliveryFeeReductionAmount ?? 0) > 0
        || (order.benefitType == ProBenefitType.coupon && (order.couponDiscountAmount ?? 0) > 0);
  }

  static double proSavings(OrderModel order, BillingValues billing) {
    final isProDiscount = order.benefitType == ProBenefitType.discount && (order.proDiscount ?? 0) > 0;
    final isProCoupon = order.benefitType == ProBenefitType.coupon && (billing.couponDiscount > 0 || (order.couponDiscountAmount ?? 0) > 0);
    final isProDeliveryFee = order.benefitType == ProBenefitType.deliveryFee && (order.deliveryFeeReductionAmount ?? 0) > 0;

    if (isProDiscount) {
      return order.proDiscount ?? 0;
    } else if (isProCoupon) {
      return (order.couponDiscountAmount ?? 0) > 0 ? (order.couponDiscountAmount ?? 0) : billing.couponDiscount;
    } else if (isProDeliveryFee) {
      return order.deliveryFeeReductionAmount ?? 0;
    }
    return 0;
  }

  static bool shouldShowCancelButton(OrderModel order, OrderController orderController) {
    final isUserLoggedIn = Get.find<AuthController>().isLoggedIn();
    final hasGuestOrderDetails = orderController.orderDetails != null && orderController.orderDetails!.isNotEmpty && orderController.orderDetails![0].isGuest == 1;

    final canCancel = isUserLoggedIn || hasGuestOrderDetails;

    return (order.orderStatus == 'pending' || order.orderStatus == 'failed') && canCancel;
  }

  static bool shouldShowParcelCancelButton(OrderModel order, OrderController orderController) {
    final isUserLoggedIn = Get.find<AuthController>().isLoggedIn();
    final isGuestLoggedIn = Get.find<AuthController>().isGuestLoggedIn();
    final hasGuestOrderDetails = orderController.orderDetails != null && orderController.orderDetails!.isNotEmpty && orderController.orderDetails![0].isGuest == 1;

    final canCancel = isUserLoggedIn || hasGuestOrderDetails;
    final cancellableStatuses = ['pending', 'accepted', 'confirmed', 'processing', 'handover', 'picked_up', 'failed'];

    if (isGuestLoggedIn) {
      return (order.orderStatus == 'pending' || order.orderStatus == 'failed') && canCancel;
    } else {
      return cancellableStatuses.contains(order.orderStatus) && canCancel;
    }
  }

  static bool shouldShowTrackDeliveryButton(OrderModel? order) {
    if (order == null) return false;
    final trackableStatuses = ['pending', 'accepted', 'confirmed', 'processing', 'handover', 'picked_up'];
    final isPendingWithoutDigitalPayment = order.orderStatus == 'pending' && order.paymentMethod != 'digital_payment';
    return isPendingWithoutDigitalPayment || trackableStatuses.contains(order.orderStatus);
  }

  static bool shouldShowReviewButton(OrderModel order, OrderController orderController) {
    if (AuthHelper.isGuestLoggedIn()) return false;
    if (order.orderStatus != 'delivered') return false;
    return orderController.orderDetails!.isNotEmpty && orderController.orderDetails![0].itemCampaignId == null && _canReview(order.reviews, orderController);
  }

  static bool shouldShowParcelReviewButton(OrderModel order) {
    if (AuthHelper.isGuestLoggedIn()) return false;
    final canReview = order.orderStatus == 'delivered' || order.orderStatus == 'returned';
    if (!canReview) return false;
    return order.deliveryMan != null;
  }

  static bool _canReview(List<Reviews>? reviews, OrderController orderController) {
    if (AuthHelper.isLoggedIn()) {
      if (reviews != null && reviews.isNotEmpty) {
        for (int i = 0; i < orderController.orderDetails!.length; i++) {
          for (int j = 0; j < reviews.length; j++) {
            if (orderController.orderDetails![i].itemId == reviews[j].itemId) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  static bool shouldShowSwitchToCodButton(OrderModel order, bool isCashOnDeliveryActive) {
    return order.orderStatus == 'pending' && order.paymentStatus == 'unpaid' && order.paymentMethod == 'digital_payment' && isCashOnDeliveryActive;
  }

  static bool shouldShowParcelReturnOtp(OrderModel order) {
    return order.orderStatus != 'returned' && order.parcelCancellation != null && order.parcelCancellation!.beforePickup == 0 && order.parcelCancellation!.returnOtp != null;
  }
}
