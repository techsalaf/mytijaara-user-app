import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/offline_success_dialog.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/cancellation_dialogue_widget.dart';
import 'package:sixam_mart/features/order/widgets/parcel_cancelation/cancellation_reason_bottom_sheet.dart';
import 'package:sixam_mart/features/order/widgets/parcel_cancelation/slider_button_widget.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_savings_banner_widget.dart';
import 'package:sixam_mart/features/order/model/billing_value.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/addess_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/billing_summery_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/deliveryman_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/item_info_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/note_collapsible_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/order_item_status_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/parcel_type_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/payment_method_section.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/scheduled_order_banner.dart';
import 'package:sixam_mart/features/order/widgets/order_status_history_sheet.dart';
import 'package:sixam_mart/features/review/screens/rate_review_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

part '../widgets/order_details_appbar.dart';
part '../widgets/order_details_info.dart';
part '../widgets/order_details_status.dart';

class OrderDetailsNewScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final int? orderId;
  final bool fromNotification;
  final bool fromOfflinePayment;
  final String? contactNumber;
  const OrderDetailsNewScreen({super.key, required this.orderModel, required this.orderId, this.fromNotification = false, this.fromOfflinePayment = false, this.contactNumber});

  @override
  OrderDetailsNewScreenState createState() => OrderDetailsNewScreenState();
}

class OrderDetailsNewScreenState extends State<OrderDetailsNewScreen> {
  Timer? _timer;
  final ScrollController scrollController = ScrollController();
  GoogleMapController? _mapController;
  Set<Marker> _markers = HashSet<Marker>();
  bool _mapLoading = true;

  void _loadData(BuildContext context, bool reload) async {
    Get.find<OrderController>().getPaymentFailedDetails(widget.orderId.toString());
    await Get.find<OrderController>().trackOrder(widget.orderId.toString(), reload ? null : widget.orderModel, false, contactNumber: widget.contactNumber).then((value) {
      if (widget.fromOfflinePayment) {
        Future.delayed(const Duration(seconds: 2), () => showAnimatedDialog(Get.context!, OfflineSuccessDialog(orderId: widget.orderId)));
      }
    });
    Get.find<OrderController>().timerTrackOrder(widget.orderId.toString(), contactNumber: widget.contactNumber);
    Get.find<OrderController>().getOrderDetails(widget.orderId.toString());
  }

  void _startApiCall() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await Get.find<OrderController>().timerTrackOrder(widget.orderId.toString(), contactNumber: widget.contactNumber);
    });
  }

  ({bool? isCodActive, double? maxAmount}) _resolveCodConfig(OrderModel order, bool parcel) {
    if (parcel || order.store == null) {
      return (isCodActive: false, maxAmount: null);
    }
    bool? isCodActive = false;
    double? maxAmount;
    final zones = AddressHelper.getUserAddressFromSharedPref()?.zoneData;
    if (zones != null) {
      for (ZoneData zData in zones) {
        if (zData.id == order.store!.zoneId) {
          isCodActive = zData.cashOnDelivery;
        }
        for (Modules m in zData.modules ?? []) {
          if (m.id == order.store!.moduleId) {
            maxAmount = m.pivot!.maximumCodOrderAmount;
            break;
          }
        }
      }
    }
    return (isCodActive: isCodActive, maxAmount: maxAmount);
  }

  Future<void> _handleTrackOrder(OrderModel order) async {
    _timer?.cancel();
    await Get.toNamed(RouteHelper.getOrderTrackingRoute(order.id, widget.contactNumber))?.whenComplete(() => _startApiCall());
  }

  Future<void> _setMarkers(OrderModel order) async {
    final bool isRestaurant = order.moduleType == 'food';
    try {
      final results = await Future.wait([
        MarkerHelper.createLabeledMarker(
          label: isRestaurant ? 'restaurant'.tr : 'store'.tr,
          imagePath: Images.restaurantMarkerIcon,
          iconSize: 32
        ),
        MarkerHelper.createLabeledMarker(
          label: 'rider'.tr,
          imagePath: Images.riderMarkerIcon,
          iconSize: 32
        ),
        MarkerHelper.createLabeledMarker(
          label: 'my_location'.tr,
          imagePath: Images.userMarkerIcon,
          iconSize: 32
        ),
      ]);
      final BitmapDescriptor storeIcon = results[0];
      final BitmapDescriptor dmIcon = results[1];
      final BitmapDescriptor userIcon = results[2];

      final Set<Marker> markers = HashSet<Marker>();

      if (order.store?.latitude != null && order.store?.longitude != null) {
        markers.add(Marker(
          markerId: const MarkerId('store'),
          position: LatLng(double.parse(order.store!.latitude!), double.parse(order.store!.longitude!)),
          icon: storeIcon,
          infoWindow: InfoWindow(title: order.store!.name ?? ''),
        ));
      }

      if (order.deliveryAddress?.latitude != null && order.deliveryAddress?.longitude != null) {
        markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(double.parse(order.deliveryAddress!.latitude!), double.parse(order.deliveryAddress!.longitude!)),
          icon: userIcon,
          infoWindow: InfoWindow(title: 'your_location'.tr),
        ));
      }

      final String? dmLat = order.deliveryMan?.lat;
      final String? dmLng = order.deliveryMan?.lng;
      if (dmLat != null && dmLng != null && dmLat.isNotEmpty && dmLng.isNotEmpty) {
        markers.add(Marker(
          markerId: const MarkerId('delivery_boy'),
          position: LatLng(double.parse(dmLat), double.parse(dmLng)),
          icon: dmIcon,
          infoWindow: InfoWindow(title: 'delivery_man'.tr),
        ));
      }

      if (_mapController != null
          && order.deliveryAddress?.latitude != null
          && order.store?.latitude != null) {
        final double addrLat = double.parse(order.deliveryAddress!.latitude!);
        final double addrLng = double.parse(order.deliveryAddress!.longitude!);
        final double storeLat = double.parse(order.store!.latitude!);
        final double storeLng = double.parse(order.store!.longitude!);
        final LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            addrLat < storeLat ? addrLat : storeLat,
            addrLng < storeLng ? addrLng : storeLng,
          ),
          northeast: LatLng(
            addrLat > storeLat ? addrLat : storeLat,
            addrLng > storeLng ? addrLng : storeLng,
          ),
        );
        _mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      }

      if (mounted) setState(() { _markers = markers; _mapLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _mapLoading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData(context, false);
    _startApiCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.fromNotification || widget.fromOfflinePayment) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          return;
        }
      },
      child: GetBuilder<OrderController>(builder: (orderController) {
        double deliveryCharge = 0;
        double itemsPrice = 0;
        double discount = 0;
        double couponDiscount = 0;
        double tax = 0;
        double addOns = 0;
        double dmTips = 0;
        double additionalCharge = 0;
        double extraPackagingCharge = 0;
        double referrerBonusAmount = 0;
        double proDiscount = 0;
        double deliveryTypeCharge = 0;
        OrderModel? order = orderController.trackModel;
        bool parcel = false;
        bool prescriptionOrder = false;
        bool taxIncluded = false;
        bool ongoing = false;
        bool isCashOnDeliveryActive = false;
        double? maxCodOrderAmount;

        if (orderController.orderDetails != null && order != null) {
          parcel = order.orderType == 'parcel';
          prescriptionOrder = order.prescriptionOrder!;
          deliveryCharge = order.deliveryCharge!;
          couponDiscount = order.couponDiscountAmount!;
          discount = order.storeDiscountAmount! + order.flashAdminDiscountAmount! + order.flashStoreDiscountAmount!;
          tax = order.totalTaxAmount!;
          dmTips = order.dmTips!;
          taxIncluded = order.taxStatus!;
          additionalCharge = order.additionalCharge!;
          extraPackagingCharge = order.extraPackagingAmount!;
          referrerBonusAmount = order.referrerBonusAmount!;
          proDiscount = (order.benefitType == ProBenefitType.discount && (order.proDiscount ?? 0) > 0) ? order.proDiscount! : 0;
          if((order.deliveryType == 'slightly_delay' || order.deliveryType == 'express') && order.deliveryTypeCharge != null) {
            deliveryTypeCharge = order.deliveryType == 'slightly_delay' ? -order.deliveryTypeCharge! : order.deliveryTypeCharge!;
          }
          if (prescriptionOrder) {
            final orderAmount = order.orderAmount ?? 0;
            itemsPrice = (orderAmount + discount) - ((taxIncluded ? 0 : tax) + deliveryCharge) - dmTips - additionalCharge;
          } else {
            for (OrderDetailsModel orderDetails in orderController.orderDetails!) {
              for (AddOn addOn in orderDetails.addOns!) {addOns = addOns + (addOn.price! * addOn.quantity!);}
              itemsPrice = itemsPrice + (orderDetails.price! * orderDetails.quantity!);
            }
          }

          final cod = _resolveCodConfig(order, parcel);
          isCashOnDeliveryActive = cod.isCodActive ?? false;
          maxCodOrderAmount = cod.maxAmount;

          ongoing = (order.orderStatus != 'delivered' && order.orderStatus != 'failed' && order.orderStatus != 'canceled' && order.orderStatus != 'refund_requested'
              && order.orderStatus != 'refunded' && order.orderStatus != 'refund_request_canceled');
        }
        final subTotal = itemsPrice + addOns;
        final total = itemsPrice + addOns - discount + (taxIncluded ? 0 : tax) + deliveryCharge + deliveryTypeCharge - couponDiscount + dmTips + additionalCharge + extraPackagingCharge - referrerBonusAmount - proDiscount;
        final isReady = orderController.orderDetails != null && order != null && orderController.trackModel != null;

        final billing = BillingValues(parcel: parcel,  prescriptionOrder: prescriptionOrder, itemsPrice: itemsPrice, addOns: addOns,
          subTotal: subTotal, discount: discount, couponDiscount: couponDiscount, referrerBonusAmount: referrerBonusAmount,
          additionalCharge: additionalCharge, tax: tax, taxIncluded: taxIncluded, dmTips: dmTips, extraPackagingCharge: extraPackagingCharge,
          deliveryCharge: deliveryCharge, deliveryTypeCharge: deliveryTypeCharge, total: total);

        final bool hasDeliveryMan = order?.deliveryMan != null;

        return Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: _OrderDetailsAppBar(deliveryManAssigned: hasDeliveryMan),

          body: SafeArea(
            child: !isReady
              ? const Center(child: CircularProgressIndicator())
              : hasDeliveryMan && ongoing
                ? Stack(children: [
                    Positioned.fill(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            double.tryParse(order.deliveryAddress?.latitude ?? '') ?? 0.0,
                            double.tryParse(order.deliveryAddress?.longitude ?? '') ?? 0.0,
                          ),
                          zoom: 15,
                        ),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _setMarkers(order);
                        },
                        style: Get.find<ThemeController>().darkTheme
                            ? Get.find<ThemeController>().darkMap
                            : Get.find<ThemeController>().lightMap,
                      ),
                    ),

                    if (_mapLoading) const Center(child: CircularProgressIndicator()),

                    Positioned.fill(child: DraggableScrollableSheet(
                      initialChildSize: 0.45,
                      minChildSize: 0.25,
                      maxChildSize: 1,
                      snap: true,
                      snapSizes: const [0.45, 0.92],
                      builder: (ctx, sheetScrollController) => CustomScrollView(
                        controller: sheetScrollController,
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _OrderDetailsStatus(order: order, ongoing: ongoing)),
                          SliverToBoxAdapter(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                                  topRight: Radius.circular(Dimensions.radiusExtraLarge),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeExtraSmall),
                                    width: 40, height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  _OrderDetailsInfo(
                                    order: order,
                                    total: total,
                                    orderDetails: orderController.orderDetails ?? const [],
                                    billing: billing,
                                    isDragable: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _BottomView(
                              orderController: orderController, order: order, parcel: parcel, totalPrice: total, subtotal: subTotal,
                              billing: billing, isCashOnDeliveryActive: isCashOnDeliveryActive, maxCodOrderAmount: maxCodOrderAmount,
                              contactNumber: widget.contactNumber, onTrackOrder: () => _handleTrackOrder(order),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ])
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).canvasColor.withValues(alpha: 3), Theme.of(context).cardColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
                            controller: scrollController,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: SizedBox(
                                width: Dimensions.webMaxWidth,
                                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  _OrderDetailsStatus(order: order, ongoing: ongoing),
                                  _OrderDetailsInfo(
                                    order: order,
                                    total: total,
                                    orderDetails: orderController.orderDetails ?? const [],
                                    billing: billing,
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }),
                      ),
                      _BottomView(
                        orderController: orderController, order: order, parcel: parcel, totalPrice: total, subtotal: subTotal,
                        billing: billing, isCashOnDeliveryActive: isCashOnDeliveryActive, maxCodOrderAmount: maxCodOrderAmount,
                        contactNumber: widget.contactNumber, onTrackOrder: () => _handleTrackOrder(order),
                      ),
                    ]),
                  ),
          ),
        );
      }),
    );
  }
}
