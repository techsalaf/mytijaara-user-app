import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/confirmation_bottom_sheet.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/login_suggestion_bottomsheet.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/widgets/add_to_monthly_widget.dart';
import 'package:sixam_mart/features/cart/widgets/cart_item_widget.dart';
import 'package:sixam_mart/features/cart/widgets/extra_packaging_widget.dart';
import 'package:sixam_mart/features/cart/widgets/new_not_available_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/cart/widgets/not_available_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/dashboard/widgets/common_widget/dish_card.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_milestone_banner_widget.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/widgets/pro_cart_banner_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/zone_free_delivery_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// What the cart's discount row shows: the store's own discount as the server priced it,
/// plus whatever the cart's bundles save.
///
/// The two are added rather than resolved against each other. `discountAmountFor` answers
/// with the server's eligibility figure where there is one, and that prices the store's
/// discount on items alone — a bundle is billed at its bundle price and its saving never
/// appears there. The fallback has the bundle part taken back out so the client's own
/// figure is not counted twice.
///
/// File-level because the desktop panel and the mobile breakdown live in different
/// classes, and the two must not quote different discounts for one cart.
double _resolveItemDiscount({
  required CartController cartController,
  required HappyHourController happyHourController,
  required int? storeId,
  required bool discountResolved,
}) {
  final double bundleDiscount = cartController.bundleDiscount;
  if(!discountResolved || happyHourController.withholdsDiscount(storeId)) {
    return bundleDiscount;
  }
  return bundleDiscount + happyHourController.discountAmountFor(
    storeId: storeId, fallback: cartController.itemDiscountPrice - bundleDiscount,
  );
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key,
    required this.fromNav, this.storeId, this.storeName,
  });
  final bool fromNav;
  final int? storeId;
  final String? storeName;

  static void openAsBottomSheet(BuildContext context, {required int storeId}) {
    final MediaQueryData mq = MediaQuery.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaQuery(
        data: mq.copyWith(padding: mq.viewPadding),
        child: SizedBox(
          height: mq.size.height,
          child: CartScreen(fromNav: false, storeId: storeId),
        ),
      ),
    );
  }

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ScrollController scrollController = ScrollController();
  final Set<int> _cartHistoryIds = {};
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    final CartController cc = Get.find<CartController>();
    final int? viewStoreId = widget.storeId ?? cc.allCartsGroups?.firstOrNull?.store?.id;
    cc.setActiveCartScreen(viewStoreId);
    initCall();
  }

  @override
  void dispose() {
    Get.find<CartController>().clearActiveCartScreen();
    scrollController.dispose();
    super.dispose();
  }

  void _confirmClearCart(CartController cartController) {
    ConfirmationBottomSheet.show(
      icon: Images.warning,
      description: 'do_you_want_to_clear_cart'.tr,
      onYesPressed: () {
        Get.back();
        final int? storeId = widget.storeId
            ?? (cartController.cartList.isNotEmpty ? cartController.cartList[0].storeId : null);
        if (storeId != null) {
          cartController.removeStoreCart(storeId);
        }
      },
    );
  }

  Future<void> initCall() async {
    _showLoginSuggestionIfGuest();
    final CartController cartController = Get.find<CartController>();
    final int? effectiveStoreId = widget.storeId
        ?? cartController.allCartsGroups?.firstOrNull?.store?.id;
    await cartController.getCartDataOnline(storeId: effectiveStoreId);

    final int? lockedStoreId = effectiveStoreId
        ?? (cartController.cartList.isNotEmpty ? cartController.cartList.first.item?.storeId : null);
    if (lockedStoreId != null && lockedStoreId != cartController.activeCartScreenStoreId) {
      cartController.setActiveCartScreen(lockedStoreId);
      await cartController.getCartDataOnline(storeId: lockedStoreId);
    }

    if (mounted) {
      setState(() => _initializing = false);
    }

    if(Get.find<SplashController>().module == null && Get.find<CartController>().cartList.isNotEmpty) {
      final bool activated = await Get.find<SplashController>()
          .activateModuleById(Get.find<CartController>().cartModuleId);
      if(activated && !GetPlatform.isWeb) {
        HomeScreen.loadData(true);
      }
    }

    if(Get.find<CartController>().cartList.isNotEmpty){
      for (final c in Get.find<CartController>().cartList) {
        if (c.item?.id != null) _cartHistoryIds.add(c.item!.id!);
      }

      if (kDebugMode) {
        print('----cart item : ${Get.find<CartController>().cartList[0].toJson()}');
      }

      if(Get.find<CartController>().addCutlery){
        Get.find<CartController>().updateCutlery(willUpdate: false);
      }
      if(Get.find<CartController>().needExtraPackage){
        Get.find<CartController>().toggleExtraPackage(willUpdate: false);
      }
      Get.find<CartController>().setAvailableIndex(-1, willUpdate: false);
      Get.find<StoreController>().getCartStoreSuggestedItemList(Get.find<CartController>().cartStoreId);
      Get.find<StoreController>().getStoreDetails(Store(id: Get.find<CartController>().cartStoreId, name: null), false, fromCart: true);
      Get.find<CartController>().calculationCart();
      if(Get.find<ProfileController>().proStatus) {
        Get.find<ProController>().getProActiveOffer(moduleType: Get.find<SplashController>().module?.moduleType);
      }
      showReferAndEarnSnackBar();
    }
  }

  void _showLoginSuggestionIfGuest() {
    if(AuthHelper.isGuestLoggedIn() && (GetPlatform.isAndroid || GetPlatform.isIOS)) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        if(Get.currentRoute == RouteHelper.cart && Get.isBottomSheetOpen == false) {
          Get.bottomSheet(const LoginSuggestionBottomSheet(fromCartPage: true), isScrollControlled: true);
        }
      });
    }
  }

  String? _resolvedStoreName() {
    final CartController cartController = Get.find<CartController>();
    final int? expectedStoreId = widget.storeId ?? cartController.cartStoreId;
    // Every source is checked against the store this screen was opened for. The store and
    // cart controllers are singletons still holding the previous cart until the new one
    // answers, so an unchecked name is the last store's for as long as that takes.
    final Store? store = Get.find<StoreController>().store;
    if(store?.id != null && store!.id == expectedStoreId && (store.name?.isNotEmpty ?? false)) {
      return store.name;
    }
    if(widget.storeName?.isNotEmpty ?? false) {
      return widget.storeName;
    }
    final CartModel? firstCart = cartController.cartList.firstOrNull;
    if(firstCart?.storeId == expectedStoreId && (firstCart?.item?.storeName?.isNotEmpty ?? false)) {
      return firstCart!.item!.storeName;
    }
    // A bundle row carries no item, so its store is named by the all-carts group instead.
    return cartController.allCartsGroups
        ?.firstWhereOrNull((AllCartsModel group) => group.store?.id == expectedStoreId)?.store?.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: GetBuilder<CartController>(
          builder: (cartController) {
            return GetBuilder<StoreController>(
              builder: (storeController) {
                final String? storeName = _resolvedStoreName();
                final bool isNamePending = storeName == null && (_initializing || cartController.cartList.isNotEmpty);

                return Container(
                  color: Theme.of(context).cardColor,
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Row(
                    children: [
                      // Close button
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Get.back(),
                        child: Container(
                          height: 36, width: 36,
                          margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault-1, bottom: Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      // Title and subtitle
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(
                                'cart'.tr,
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              if(storeName != null)
                                Flexible(child: Text(
                                  ' - $storeName', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                                ))
                              else if(isNamePending) ...[
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                const _ShimmerBar(width: 90, height: 14),
                              ],
                            ]),
                            const SizedBox(height: 2),
                            _initializing
                                ? const _ShimmerBar(width: 60, height: 12)
                                : Text(
                                    '${cartController.cartList.length} ${'items_added'.tr}',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      // Clear button — hidden when cart is empty
                      if (cartController.cartList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap: () => _confirmClearCart(cartController),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(Images.delete, height: 24, width: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<StoreController>(builder: (storeController) {
        return GetBuilder<CartController>(builder: (cartController) {
          for (final c in cartController.cartList) {
            if (c.item?.id != null) _cartHistoryIds.add(c.item!.id!);
          }

          if (_initializing || (cartController.isLoading && cartController.cartList.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartController.cartList.isEmpty) {
            return const NoDataScreen(isCart: true, text: '', showFooter: true);
          }

          return _buildMobileBody(cartController, storeController);
        });
      }),
    );
  }

  // ── Mobile layout ───────────────────────────────────────────────────────────
  Widget _buildMobileBody(CartController cartController, StoreController storeController) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(children: [

            // Cart items card
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeDefault,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                // boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: cartController.cartList.length,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  separatorBuilder: (context, index) {
                    return Divider(height: 20, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.3));
                  },
                  itemBuilder: (context, index) {
                    return CartItemWidget(
                      cart: cartController.cartList[index],
                      cartIndex: index,
                      addOns: cartController.addOnsList.isNotEmpty ? cartController.addOnsList[index] : [],
                      isAvailable: cartController.availableList.isNotEmpty ? cartController.availableList[index] : false,
                    );
                  },
                ),

                // Add more items
                Divider(height: 2, thickness: 0.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                  child: TextButton.icon(
                    onPressed: () {
                      cartController.forcefullySetModule(cartController.cartModuleId!);
                      Get.toNamed(
                        RouteHelper.getStoreRoute(id: cartController.cartStoreId, page: 'item', slug: Get.find<StoreController>().store?.slug ?? ''),
                        arguments: StoreScreen(store: Store(id: cartController.cartStoreId), fromModule: false),
                      );
                      Get.offNamed(RouteHelper.getStoreRoute(id: cartController.cartStoreId, page: 'item', slug: Get.find<StoreController>().store?.slug ?? ''));
                    },
                    icon: Icon(Icons.add_circle_outline_sharp, color: Theme.of(context).textTheme.bodyLarge!.color),
                    label: Text('add_more_items'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeDefault)),
                  ),
                ),
              ]),
            ),

            if (_isGroceryOrPharmacy(cartController) && !_hasCampaignOrFlashSaleItem(cartController) && !_hasBogoBundle(cartController) && (AuthHelper.isLoggedIn() && Get.find<SplashController>().configModel?.monthlyOrderRemainder == 1)) ...[
              const MonthlyReorderSection(),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],

            // Extra packaging + Cutlery + Not available — single grouped card
            GetBuilder<StoreController>(builder: (sc) {
              final bool showPackaging = sc.store?.extraPackagingStatus ?? false;
              final bool showCutlery = Get.find<SplashController>().getModuleConfig(
                    cartController.cartModuleType,
                  ).newVariation! && (sc.store?.cutlery ?? false);

              return Container(
                margin: const EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeLarge,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  // boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0)],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [

                  // Extra packaging row
                  if (showPackaging) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('need_extra_packaging'.tr, style: robotoBold),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: '${'additional'.tr} ',
                                  style: robotoRegular.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                                TextSpan(
                                  text: PriceConverter.convertPrice(sc.store?.extraPackagingAmount),
                                  style: robotoMedium.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge!.color,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${'change_will_be_added_for_extra_packaging'.tr}',
                                  style: robotoRegular.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                        Checkbox(
                          activeColor: Theme.of(context).primaryColor,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          value: cartController.needExtraPackage,
                          onChanged: (_) => cartController.toggleExtraPackage(),
                        ),
                      ]),
                    ),
                    Divider(height: 1, thickness: 0.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                  ],

                  // Cutlery row
                  if (showCutlery) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('add_cutlery'.tr, style: robotoBold),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            Text(
                              'do_not_have_cutlery'.tr,
                              style: robotoRegular.copyWith(
                                color: Theme.of(context).disabledColor,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ]),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: CupertinoSwitch(
                            value: cartController.addCutlery,
                            activeTrackColor: Theme.of(context).primaryColor,
                            onChanged: (_) => cartController.updateCutlery(),
                            inactiveTrackColor: Theme.of(context).disabledColor.withValues(alpha: 0.25),
                          ),
                        ),
                      ]),
                    ),
                    Divider(height: 1, thickness: 0.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                  ],

                  // Not available row
                  InkWell(
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                      builder: (_) => const NewNotAvailableBottomSheetWidget(),
                    ),
                    borderRadius: (showPackaging || showCutlery)
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(Dimensions.radiusDefault),
                            bottomRight: Radius.circular(Dimensions.radiusDefault),
                          )
                        : BorderRadius.circular(Dimensions.radiusDefault),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Expanded(
                            child: Text('if_any_product_is_not_available'.tr, style: robotoBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ]),
                        if (cartController.notAvailableIndex != -1) ...[
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Container(
                            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface, 
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(
                                cartController.notAvailableList[cartController.notAvailableIndex].tr,
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                              ),
                              IconButton(
                                onPressed: () => cartController.setAvailableIndex(-1),
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  ),

                ]),
              );
            }),

            // Suggested items
            suggestedItemView(cartController.cartList),

            _ProCartBanner(
              subtotal: cartController.subTotal, forMembers: false,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            ),

          ]),
        ),
      ),

      // Sticky bottom checkout bar
      CheckoutButton(cartController: cartController, availableList: cartController.availableList),
    ]);
  }

  Widget pricingView(CartController cartController, Item? item){
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Container(
      decoration: isDesktop ? BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ) : null,
      child: GetBuilder<StoreController>(
        builder: (storeController) {
          return GetBuilder<HappyHourController>(builder: (happyHourController) {
          final bool discountResolved = storeController.store != null
              && !happyHourController.discountPending(storeController.store?.id, storeController.store?.isHappyHourRunning);
          // Resolved once for both panels, so the two cannot quote different discounts
          // for one cart.
          final double itemDiscount = _resolveItemDiscount(
            cartController: cartController, happyHourController: happyHourController,
            storeId: storeController.store?.id, discountResolved: discountResolved,
          );

          return Column(children: [

            isDesktop ? ExtraPackagingWidget(cartController: cartController) : const SizedBox(),

            isDesktop ? Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                child: Text('order_summary'.tr, style: robotoBold),
              ),
            ) : const SizedBox(),

            isDesktop && Get.find<SplashController>().getModuleConfig(item?.moduleType ?? cartController.cartModuleType).newVariation!
            && (storeController.store?.cutlery ?? false) ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, spreadRadius: 1, offset: const Offset(0, 1))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Image.asset(Images.cutlery, height: 18, width: 18),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('add_cutlery'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text('do_not_have_cutlery'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
                  ]),
                ),

                Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    value: cartController.addCutlery,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (_) => cartController.updateCutlery(),
                    inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ]),
            ) : const SizedBox(),

            isDesktop ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('item_price'.tr, style: robotoRegular),
                  PriceConverter.convertAnimationPrice(cartController.itemPrice, textStyle: robotoRegular),
                ]),
                SizedBox(height: cartController.variationPrice > 0 ? Dimensions.paddingSizeSmall : 0),

                Get.find<SplashController>().getModuleConfig(item?.moduleType).newVariation! && cartController.variationPrice > 0 ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('variations'.tr, style: robotoRegular),
                    Text('(+) ${PriceConverter.convertPrice(cartController.variationPrice)}', style: robotoRegular, textDirection: TextDirection.ltr),
                  ],
                ) : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('discount'.tr, style: robotoRegular),
                  discountResolved ? Row(children: [
                    Text('(-)', style: robotoRegular),
                    PriceConverter.convertAnimationPrice(itemDiscount, textStyle: robotoRegular),
                  ]) : Text('calculating'.tr, style: robotoRegular),
                ]),
                SizedBox(height: Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn! ? 10 : 0),

                Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn! ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('addons'.tr, style: robotoRegular),
                    Text('(+) ${PriceConverter.convertPrice(cartController.addOns)}', style: robotoRegular, textDirection: TextDirection.ltr),
                  ],
                ) : const SizedBox(),

                (storeController.store != null && storeController.store!.extraPackagingStatus! && cartController.needExtraPackage) ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('extra_packaging'.tr, style: robotoRegular),
                      Text('(+) ${PriceConverter.convertPrice(storeController.store!.extraPackagingAmount!)}', style: robotoRegular, textDirection: TextDirection.ltr),
                    ],
                  ),
                ) : const SizedBox.shrink(),
              ]),
            ) : const SizedBox(),

            isDesktop ? Container(
              width: Dimensions.webMaxWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                color: Theme.of(context).cardColor,
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 0.5),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Get.dialog(const Dialog(child: NotAvailableBottomSheetWidget())),
                    child: Row(children: [
                      Expanded(child: Text('if_any_product_is_not_available'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Container(
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    ),
                    child: cartController.notAvailableIndex != -1 ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(cartController.notAvailableList[cartController.notAvailableIndex].tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                      IconButton(
                        onPressed: () => cartController.setAvailableIndex(-1),
                        icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                      ),
                    ]) : const SizedBox(),
                  ),
                ],
              ),
            ) : const SizedBox(),

            isDesktop && Get.find<SplashController>().getModuleConfig(cartController.cartModuleType).newVariation! && storeController.store != null && storeController.store!.deliveryTime != null ? Container(
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
              child: Row(children: [
                Image.asset(Images.carDelivery, height: 20, width: 20, color: Colors.orange),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                RichText(text: TextSpan(children: [
                  TextSpan(text: '${'estimated_delivery_time'.tr} : ', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                  TextSpan(text: '${storeController.store?.deliveryTime}', style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                ])),
              ]),
            ) : const SizedBox(),

            isDesktop ? Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: ProCartBannerWidget(subtotal: cartController.subTotal, redirectRoute: RouteHelper.getCartRoute()),
            ) : const SizedBox.shrink(),
            
            isDesktop ? CheckoutButton(cartController: cartController, availableList: cartController.availableList) : const SizedBox.shrink(),
          ]);
          });
        },
      ),
    );
  }

  Widget suggestedItemView(List<CartModel> cartList) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(300, math.min(viewportWidth * 0.82, 360));

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GetBuilder<StoreController>(builder: (storeController) {
          List<Item>? suggestedItems;
          if(storeController.cartSuggestItemModel != null){
            suggestedItems = [];
            final List<int> cartIds = cartList.where((c) => c.item?.id != null).map((c) => c.item!.id!).toList();
            for (Item item in storeController.cartSuggestItemModel!.items!) {
              if(!cartIds.contains(item.id) && !_cartHistoryIds.contains(item.id)){
                suggestedItems.add(item);
              }
            }
          }
          return storeController.cartSuggestItemModel != null && suggestedItems!.isNotEmpty ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                child: Text('you_may_also_like'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              ),

              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedItems.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                  itemBuilder: (context, index) {
                    final Item item = suggestedItems![index];
                    return CustomInkWell(
                      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context),
                      child: DishCard(item: item, width: cardWidth, isBorder: true, index: index),
                    );
                  },
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
          ) : const SizedBox();
        }),
      ]),
    );
  }

  Future<void> showReferAndEarnSnackBar() async {
    final String text = 'your_referral_discount_added_on_your_first_order'.tr;
    if(Get.find<ProfileController>().userInfoModel != null && Get.find<ProfileController>().userInfoModel!.isValidForDiscount!) {
      showCustomSnackBar(text, isError: false);
    }
  }

  bool _isGroceryOrPharmacy(CartController cartController) {
    final String? moduleType = cartController.firstCartItem?.moduleType;
    return moduleType == AppConstants.grocery || moduleType == AppConstants.pharmacy;
  }

  bool _hasBogoBundle(CartController cartController) {
    return cartController.cartList.any((cart) => cart.isBogoBundle);
  }

  bool _hasCampaignOrFlashSaleItem(CartController cartController) {
    return cartController.cartList.any((cart) => (cart.isCampaign ?? false) || (cart.item?.flashSale ?? 0) > 0);
  }
}

// The cart's pro banner, drawn only in the slot that suits who is looking: a member's
// benefit is priced off the subtotal and belongs above the checkout bar, while the
// subscribe pitch rides at the end of the list rather than pinned over the total.
class _ProCartBanner extends StatelessWidget {
  final double subtotal;
  final bool forMembers;
  final EdgeInsetsGeometry padding;

  const _ProCartBanner({required this.subtotal, required this.forMembers, required this.padding});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isPro = profileController.userInfoModel?.proStatus ?? false;
      if (isPro != forMembers) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: padding,
        child: ProCartBannerWidget(subtotal: subtotal, redirectRoute: RouteHelper.getCartRoute()),
      );
    });
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        width: width, height: height,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
      ),
    );
  }
}

class CheckoutButton extends StatefulWidget {
  final CartController cartController;
  final List<bool> availableList;
  const CheckoutButton({super.key, required this.cartController, required this.availableList});

  @override
  State<CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<CheckoutButton> {
  bool _isPriceBreakdownExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: Dimensions.webMaxWidth,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isDesktop ? Dimensions.radiusDefault : 0),
      ),
      child: GetBuilder<StoreController>(
        builder: (storeController) {
          return GetBuilder<HappyHourController>(builder: (happyHourController) {
          final ZoneFreeDeliveryStatus? freeDelivery = ZoneFreeDeliveryHelper.progressFor(
            store: storeController.store, subtotal: widget.cartController.subTotal,
          );

          final bool discountResolved = storeController.store != null
              && !happyHourController.discountPending(storeController.store?.id, storeController.store?.isHappyHourRunning);

          final double clientDiscount = widget.cartController.itemDiscountPrice;
          final double itemDiscount = _resolveItemDiscount(
            cartController: widget.cartController, happyHourController: happyHourController,
            storeId: storeController.store?.id, discountResolved: discountResolved,
          );

          // The row above may quote the server's figure instead of the cart's own, so the
          // cart's is added back before the shown one is taken off.
          double subTotal = widget.cartController.subTotal + clientDiscount - itemDiscount;
          if(storeController.store != null && storeController.store!.extraPackagingStatus! && widget.cartController.needExtraPackage) {
            subTotal = subTotal + storeController.store!.extraPackagingAmount!;
          }

          return Column(mainAxisSize: MainAxisSize.min, children: [
            // Free delivery progress (mobile + desktop)
            if(!isDesktop && freeDelivery != null) ...[
              _FreeDeliveryBanner(status: freeDelivery),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],

            // ── Collapsible price breakdown (mobile only) ────────────────────
            if (!isDesktop) ...[

              // Pro benefit banner — above subtotal, members only
              _ProCartBanner(
                subtotal: subTotal, forMembers: true,
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              ),

              HappyHourMilestoneBannerWidget(
                subtotal: widget.cartController.subTotal,
                isHappyHourRunning: storeController.store?.isHappyHourRunning,
                storeId: storeController.store?.id,
                roundedBottom: true, bottomSpacing: Dimensions.paddingSizeSmall,
                showCountdown: false,
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _isPriceBreakdownExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeSmall,
                    0,
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('item_price'.tr, style: robotoRegular),
                      PriceConverter.convertAnimationPrice(widget.cartController.itemPrice, textStyle: robotoRegular),
                    ]),

                    if (widget.cartController.variationPrice > 0 && ModuleHelper.getModuleConfig(widget.cartController.cartModuleType).newVariation!) ...[
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('variations'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverter.convertPrice(widget.cartController.variationPrice)}', style: robotoRegular, textDirection: TextDirection.ltr),
                      ]),
                    ],

                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('discount'.tr, style: robotoRegular),
                      discountResolved ? Row(children: [
                        Text('(-)', style: robotoRegular),
                        PriceConverter.convertAnimationPrice(itemDiscount, textStyle: robotoRegular),
                      ]) : Text('calculating'.tr, style: robotoRegular),
                    ]),

                    if (Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn!) ...[
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('addons'.tr, style: robotoRegular),
                        Row(children: [
                          Text('(+)', style: robotoRegular),
                          PriceConverter.convertAnimationPrice(widget.cartController.addOns, textStyle: robotoRegular),
                        ]),
                      ]),
                    ],

                    if (storeController.store != null && storeController.store!.extraPackagingStatus! && widget.cartController.needExtraPackage) ...[
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('extra_packaging'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverter.convertPrice(storeController.store!.extraPackagingAmount!)}', style: robotoRegular, textDirection: TextDirection.ltr),
                      ]),
                    ],

                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), height: 1),
                  ]),
                ),
                secondChild: const SizedBox(width: double.infinity),
              ),

              // Subtotal row — tapping toggles price breakdown
              InkWell(
                onTap: () => setState(() => _isPriceBreakdownExpanded = !_isPriceBreakdownExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Text('subtotal'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      AnimatedRotation(
                        turns: _isPriceBreakdownExpanded ? 0.0 : 0.5,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                    ]),
                    PriceConverter.convertAnimationPrice(subTotal, textStyle: robotoBold),
                  ]),
                ),
              ),
            ],

            // Desktop subtotal row (unchanged)
            if (isDesktop) ...[
              const Divider(height: 1),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('subtotal'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                  PriceConverter.convertAnimationPrice(subTotal, textStyle: robotoBold),
                ]),
              ),
            ],

            // Desktop-only: cutlery switch
            if (isDesktop && Get.find<SplashController>().getModuleConfig(widget.cartController.cartModuleType).newVariation!
              && storeController.store != null && storeController.store!.cutlery!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Image.asset(Images.cutlery, height: 18, width: 18),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('add_cutlery'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text('do_not_have_cutlery'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
                    ]),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: widget.cartController.addCutlery,
                      activeTrackColor: Theme.of(context).primaryColor,
                      onChanged: (_) => widget.cartController.updateCutlery(),
                      inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                ]),
              ),

            // Desktop-only: not available
            if (isDesktop)
              Container(
                width: Dimensions.webMaxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 0.5),
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  InkWell(
                    onTap: () => Get.dialog(const Dialog(child: NotAvailableBottomSheetWidget())),
                    child: Row(children: [
                      Expanded(child: Text('if_any_product_is_not_available'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Container(
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    ),
                    child: widget.cartController.notAvailableIndex != -1 ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.cartController.notAvailableList[widget.cartController.notAvailableIndex].tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                      IconButton(
                        onPressed: () => widget.cartController.setAvailableIndex(-1),
                        icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                      ),
                    ]) : const SizedBox(),
                  ),
                ]),
              ),

            // Desktop-only: delivery time
            if (isDesktop && Get.find<SplashController>().getModuleConfig(widget.cartController.cartModuleType).newVariation!
              && storeController.store != null && storeController.store!.deliveryTime != null)
              Container(
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                child: Row(children: [
                  Image.asset(Images.carDelivery, height: 20, width: 20, color: Colors.orange),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '${'estimated_delivery_time'.tr} : ', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                    TextSpan(text: '${storeController.store?.deliveryTime}', style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                  ])),
                ]),
              ),

            // Desktop free delivery progress
            if (isDesktop && freeDelivery != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _FreeDeliveryBanner(status: freeDelivery),
            ],

            const SizedBox(height: Dimensions.paddingSizeSmall),

            SafeArea(
              child: CustomButton(
                buttonText: 'confirm_delivery_details'.tr,
                fontSize: isDesktop ? Dimensions.fontSizeSmall : Dimensions.fontSizeLarge,
                isBold: !isDesktop,
                radius: isDesktop ? Dimensions.radiusSmall : Dimensions.radiusDefault,
                onPressed: () async {
                  Get.find<CheckoutController>().updateFirstTime();
                  Get.find<CheckoutController>().updateFirstTimeCodActive();
                  if(!(widget.cartController.firstCartItem?.scheduleOrder ?? true) && widget.availableList.contains(false)) {
                    showCustomSnackBar('one_or_more_product_unavailable'.tr);
                  } else {
                    if(Get.find<SplashController>().module == null) {
                      // The module is null whenever something else cleared it while
                      // the cart stayed on the stack. Resolving it here used to index
                      // past the end of `moduleList` when the cart's module was not
                      // in the list, and that RangeError — swallowed by this async
                      // handler — is why the button did nothing at all.
                      final bool activated = await Get.find<SplashController>()
                          .activateModuleById(widget.cartController.cartModuleId);
                      if(!activated) {
                        showCustomSnackBar('no_module_found'.tr);
                        return;
                      }
                      HomeScreen.loadData(true);
                    }
                    Get.find<CouponController>().removeCouponData(false);
                    Get.toNamed(RouteHelper.getCheckoutRoute('cart'), preventDuplicates: false);
                  }
                },
              ),
            ),
          ]);
          });
        },
      ),
    );
  }
}

class _FreeDeliveryBanner extends StatelessWidget {
  final ZoneFreeDeliveryStatus status;

  const _FreeDeliveryBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Image.asset(Images.percentTag, height: 20, width: 20, color: Colors.orange),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

        if(status.isFree)
          Text('free_delivery'.tr, style: robotoMedium.copyWith(color: Colors.orange))
        else ...[
          Text(
            PriceConverter.convertPrice(status.remaining),
            style: robotoMedium.copyWith(color: Colors.orange), textDirection: TextDirection.ltr,
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text('more_for_free_delivery'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
        ],
      ]),

      // Nothing left to fill once it is free, so the bar goes with the amount.
      if(!status.isFree) ...[
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        LinearProgressIndicator(
          backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          value: status.percentage,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ],
    ]);
  }
}

// SUMMARY
// Cart screen for one store. Lists the cart rows with add-ons, packaging, cutlery and
// not-available options, suggests more items, shows the price breakdown and subtotal, and
// clears the cart or moves on to checkout.
