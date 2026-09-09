import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_widget.dart';
import 'package:sixam_mart/common/widgets/login_suggestion_bottomsheet.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/widgets/add_to_monthly_widget.dart';
import 'package:sixam_mart/features/cart/widgets/cart_item_widget.dart';
import 'package:sixam_mart/features/cart/widgets/extra_packaging_widget.dart';
import 'package:sixam_mart/features/cart/widgets/not_available_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/cart/widgets/web_cart_items_widget.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/widgets/pro_cart_banner_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/cart/widgets/new_not_available_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key,
    required this.fromNav, this.storeId, this.storeName,
  });
  final bool fromNav;
  final int? storeId;
  final String? storeName;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ScrollController scrollController = ScrollController();
  // Accumulates every item ID that has ever been in the cart this session.
  // Never shrinks — ensures removed items don't re-appear as suggestions.
  final Set<int> _cartHistoryIds = {};
  // True until the screen's initial store-scoped fetch finishes. Gates the loader
  // so the controller's previous (stale) _cartList is never flashed on entry.
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

  void _showClearCartDialog(CartController cartController) {
    Get.dialog(ConfirmationDialog(
      icon: Images.warning,
      description: 'do_you_want_to_clear_cart'.tr,
      onYesPressed: () {
        Get.back();
        final int? storeId = widget.storeId
            ?? (cartController.cartList.isNotEmpty ? cartController.cartList[0].item?.storeId : null);
        if (storeId != null) {
          cartController.removeStoreCart(storeId);
        }
      },
    ));
  }

  Future<void> initCall() async {
    _showLoginSuggestionIfGuest();
    final CartController cartController = Get.find<CartController>();
    // Derive the store to display. Priority: explicit param → first global-cart group.
    // Always re-fetch so concurrent getAllCarts() calls never leak mixed-store items into the view.
    final int? effectiveStoreId = widget.storeId
        ?? cartController.allCartsGroups?.firstOrNull?.store?.id;
    await cartController.getCartDataOnline(storeId: effectiveStoreId);

    // Lock the screen to the real store of the loaded items so any later
    // getAllCarts() (e.g. triggered by add-to-cart) keeps the list scoped to this
    // one store instead of widening to the whole module.
    final int? lockedStoreId = effectiveStoreId
        ?? (cartController.cartList.isNotEmpty ? cartController.cartList.first.item?.storeId : null);
    if (lockedStoreId != null && lockedStoreId != cartController.activeCartScreenStoreId) {
      cartController.setActiveCartScreen(lockedStoreId);
      await cartController.getCartDataOnline(storeId: lockedStoreId);
    }

    // Store-scoped cart is now loaded — reveal the list (drops the entry loader).
    if (mounted) {
      setState(() => _initializing = false);
    }

    if(Get.find<SplashController>().module == null && Get.find<CartController>().cartList.isNotEmpty) {
      await Get.find<SplashController>().getModules();
      int i = 0;
      for(i = 0; i < Get.find<SplashController>().moduleList!.length; i++){
        if(Get.find<CartController>().cartList[0].item!.moduleId == Get.find<SplashController>().moduleList![i].id){
          break;
        }
      }
      Get.find<SplashController>().setModule(Get.find<SplashController>().moduleList![i]);
      if(!GetPlatform.isWeb) {
        HomeScreen.loadData(true);
      }
    }

    if(Get.find<CartController>().cartList.isNotEmpty){
      // Seed history with the initial cart so these items are never shown as suggestions.
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
      Get.find<StoreController>().getCartStoreSuggestedItemList(Get.find<CartController>().cartList[0].item!.storeId);
      Get.find<StoreController>().getStoreDetails(Store(id: Get.find<CartController>().cartList[0].item!.storeId, name: null), false, fromCart: true);
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

  String getStoreName(){
    final storeController = Get.find<StoreController>();
    final cartController = Get.find<CartController>();
    return storeController.store?.name ?? widget.storeName ?? (cartController.cartList.isNotEmpty ? cartController.cartList[0].item?.storeName : null) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: GetBuilder<CartController>(
          builder: (cartController) {
            return GetBuilder<StoreController>(
              builder: (storeController) {
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
                            RichText(
                              text: TextSpan( children: [
                                TextSpan(text: "${'cart'.tr} ${getStoreName().isNotEmpty ? ' - ' : ''}", style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                TextSpan(text: getStoreName(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              ])
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_initializing ? 0 : cartController.cartList.length} ${'items_added'.tr}',
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
                            onTap: () => _showClearCartDialog(cartController),
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
          // Accumulate current cart IDs so items added via suggestions are also
          // excluded from future suggestion lists once they enter the cart.
          for (final c in cartController.cartList) {
            if (c.item?.id != null) _cartHistoryIds.add(c.item!.id!);
          }

          // Show loader during the initial store-scoped fetch (so the previous,
          // stale cart is never flashed) and while any later fetch has no data yet.
          if (_initializing || (cartController.isLoading && cartController.cartList.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartController.cartList.isEmpty) {
            return const NoDataScreen(isCart: true, text: '', showFooter: true);
          }

          if (isDesktop) {
            return _buildDesktopBody(cartController, storeController, isDesktop);
          }

          return _buildMobileBody(cartController, storeController);
        });
      }),
    );
  }

  // ── Desktop layout ──────────────────────────────────────────────────────────
  Widget _buildDesktopBody(CartController cartController, StoreController storeController, bool isDesktop) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: FooterView(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Column(children: [
                WebScreenTitleWidget(title: 'cart_list'.tr),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WebCardItemsWidget(cartList: cartController.cartList),
                  const SizedBox(width: Dimensions.paddingSizeLarge),
                  Expanded(flex: 4, child: pricingView(cartController, cartController.cartList[0].item!)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    ]);
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
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: cartController.cartList.length,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  itemBuilder: (context, index) {
                    return CartItemWidget(
                      cart: cartController.cartList[index],
                      cartIndex: index,
                      addOns: cartController.addOnsList.isNotEmpty ? cartController.addOnsList[index] : [],
                      isAvailable: cartController.availableList.isNotEmpty ? cartController.availableList[index] : false,
                      showDivider: index != cartController.cartList.length - 1,
                    );
                  },
                ),

                // Add more items
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                  child: TextButton.icon(
                    onPressed: () {
                      cartController.forcefullySetModule(cartController.cartList[0].item!.moduleId!);
                      Get.toNamed(
                        RouteHelper.getStoreRoute(id: cartController.cartList[0].item!.storeId, page: 'item', slug: Get.find<StoreController>().store?.slug ?? ''),
                        arguments: StoreScreen(store: Store(id: cartController.cartList[0].item!.storeId), fromModule: false),
                      );
                      Get.offNamed(RouteHelper.getStoreRoute(id: cartController.cartList[0].item!.storeId, page: 'item', slug: Get.find<StoreController>().store?.slug ?? ''));
                    },
                    icon: Icon(Icons.add_circle_outline_sharp, color: Theme.of(context).textTheme.bodyLarge!.color),
                    label: Text('add_more_items'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeDefault)),
                  ),
                ),
              ]),
            ),

            if (_isGroceryOrPharmacy(cartController) && !_hasCampaignOrFlashSaleItem(cartController) && (AuthHelper.isLoggedIn() && Get.find<SplashController>().configModel?.monthlyOrderRemainder == 1)) ...[
              const MonthlyReorderSection(),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],

            // Extra packaging + Cutlery + Not available — single grouped card
            GetBuilder<StoreController>(builder: (sc) {
              final bool showPackaging = sc.store?.extraPackagingStatus ?? false;
              final bool showCutlery = Get.find<SplashController>().getModuleConfig(
                    cartController.cartList[0].item!.moduleType,
                  ).newVariation! && (sc.store != null && sc.store!.cutlery!);

              return Container(
                margin: const EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeLarge,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0)],
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

          ]),
        ),
      ),

      // Sticky bottom checkout bar
      CheckoutButton(cartController: cartController, availableList: cartController.availableList),
    ]);
  }

  Widget pricingView(CartController cartController, Item item){
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Container(
      decoration: isDesktop ? BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ) : null,
      child: GetBuilder<StoreController>(
        builder: (storeController) {
          return Column(children: [

            isDesktop ? ExtraPackagingWidget(cartController: cartController) : const SizedBox(),

            isDesktop ? Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                child: Text('order_summary'.tr, style: robotoBold),
              ),
            ) : const SizedBox(),

            isDesktop && Get.find<SplashController>().getModuleConfig(item.moduleType).newVariation!
            && (storeController.store != null && storeController.store!.cutlery!) ? Container(
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

                Get.find<SplashController>().getModuleConfig(item.moduleType).newVariation! && cartController.variationPrice > 0 ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('variations'.tr, style: robotoRegular),
                    Text('(+) ${PriceConverter.convertPrice(cartController.variationPrice)}', style: robotoRegular, textDirection: TextDirection.ltr),
                  ],
                ) : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('discount'.tr, style: robotoRegular),
                  storeController.store != null ? Row(children: [
                    Text('(-)', style: robotoRegular),
                    PriceConverter.convertAnimationPrice(cartController.itemDiscountPrice, textStyle: robotoRegular),
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

            isDesktop && Get.find<SplashController>().getModuleConfig(cartController.cartList[0].item!.moduleType).newVariation! && storeController.store != null && storeController.store!.deliveryTime != null ? Container(
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
        },
      ),
    );
  }

  Widget suggestedItemView(List<CartModel> cartList) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GetBuilder<StoreController>(builder: (storeController) {
          List<Item>? suggestedItems;
          if(storeController.cartSuggestItemModel != null){
            suggestedItems = [];
            final List<int> cartIds = cartList.map((c) => c.item!.id!).toList();
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
                child: Text('you_may_also_like'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
              ),

              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedItems.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeExtraSmall),
                        margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                        child: ItemWidget(
                          isStore: false, item: suggestedItems![index], fromCartSuggestion: true,
                          store: null, index: index, length: null, isCampaign: false, inStore: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
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
    final String? moduleType = cartController.cartList.isNotEmpty ? cartController.cartList[0].item?.moduleType : null;
    return moduleType == AppConstants.grocery || moduleType == AppConstants.pharmacy;
  }

  bool _hasCampaignOrFlashSaleItem(CartController cartController) {
    return cartController.cartList.any((cart) => (cart.isCampaign ?? false) || (cart.item?.flashSale ?? 0) > 0);
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
    double percentage = 0;

    return Container(
      width: Dimensions.webMaxWidth,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isDesktop ? Dimensions.radiusDefault : 0),
      ),
      child: GetBuilder<StoreController>(
        builder: (storeController) {
          if(storeController.store != null && !storeController.store!.freeDelivery!
            && (Get.find<SplashController>().configModel?.adminFreeDelivery?.status == true
              && Get.find<SplashController>().configModel?.adminFreeDelivery?.type == 'free_delivery_by_order_amount'
              && Get.find<SplashController>().configModel!.adminFreeDelivery?.freeDeliveryOver != null)) {
            percentage = widget.cartController.subTotal / Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver!;
          }

          double subTotal = widget.cartController.subTotal;
          if(storeController.store != null && storeController.store!.extraPackagingStatus! && widget.cartController.needExtraPackage) {
            subTotal = subTotal + storeController.store!.extraPackagingAmount!;
          }

          return Column(mainAxisSize: MainAxisSize.min, children: [

            // Free delivery progress (mobile + desktop)
            if(!isDesktop && storeController.store != null && !storeController.store!.freeDelivery!
              && (Get.find<SplashController>().configModel?.adminFreeDelivery?.status == true
                && Get.find<SplashController>().configModel?.adminFreeDelivery?.type == 'free_delivery_by_order_amount'
                && Get.find<SplashController>().configModel!.adminFreeDelivery?.freeDeliveryOver != null)
              && percentage < 1)
              Column(children: [
                Row(children: [
                  Image.asset(Images.percentTag, height: 20, width: 20, color: Colors.orange),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text(
                    PriceConverter.convertPrice(Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver! - widget.cartController.subTotal),
                    style: robotoMedium.copyWith(color: Colors.orange), textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text('more_for_free_delivery'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                LinearProgressIndicator(
                  backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  value: percentage,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              ]),

            // ── Collapsible price breakdown (mobile only) ────────────────────
            if (!isDesktop) ...[

              // Pro plan promo / benefit banner — above subtotal
              Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: ProCartBannerWidget(subtotal: subTotal, redirectRoute: RouteHelper.getCartRoute()),
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

                    if (widget.cartController.variationPrice > 0 && ModuleHelper.getModuleConfig(widget.cartController.cartList.first.item!.moduleType).newVariation!) ...[
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('variations'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverter.convertPrice(widget.cartController.variationPrice)}', style: robotoRegular, textDirection: TextDirection.ltr),
                      ]),
                    ],

                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('discount'.tr, style: robotoRegular),
                      storeController.store != null ? Row(children: [
                        Text('(-)', style: robotoRegular),
                        PriceConverter.convertAnimationPrice(widget.cartController.itemDiscountPrice, textStyle: robotoRegular),
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
            if (isDesktop && Get.find<SplashController>().getModuleConfig(widget.cartController.cartList[0].item!.moduleType).newVariation!
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
            if (isDesktop && Get.find<SplashController>().getModuleConfig(widget.cartController.cartList[0].item!.moduleType).newVariation!
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
            if (isDesktop && storeController.store != null && !storeController.store!.freeDelivery!
              && (Get.find<SplashController>().configModel?.adminFreeDelivery?.status == true
                && Get.find<SplashController>().configModel?.adminFreeDelivery?.type == 'free_delivery_by_order_amount'
                && Get.find<SplashController>().configModel!.adminFreeDelivery?.freeDeliveryOver != null)
              && percentage < 1) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(children: [
                Image.asset(Images.percentTag, height: 20, width: 20, color: Colors.orange),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(
                  PriceConverter.convertPrice(Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver! - widget.cartController.subTotal),
                  style: robotoMedium.copyWith(color: Colors.orange), textDirection: TextDirection.ltr,
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text('more_for_free_delivery'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              LinearProgressIndicator(
                backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                value: percentage,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ],

            if (isDesktop) const SizedBox(height: Dimensions.paddingSizeSmall),

            // Checkout button
            SafeArea(
              child: CustomButton(
                buttonText: 'confirm_delivery_details'.tr,
                fontSize: isDesktop ? Dimensions.fontSizeSmall : Dimensions.fontSizeLarge,
                isBold: !isDesktop,
                radius: isDesktop ? Dimensions.radiusSmall : Dimensions.radiusDefault,
                onPressed: () async {
                  Get.find<CheckoutController>().updateFirstTime();
                  Get.find<CheckoutController>().updateFirstTimeCodActive();
                  if(!widget.cartController.cartList.first.item!.scheduleOrder! && widget.availableList.contains(false)) {
                    showCustomSnackBar('one_or_more_product_unavailable'.tr);
                  } else {
                    if(Get.find<SplashController>().module == null) {
                      await Get.find<SplashController>().getModules();
                      int i = 0;
                      for(i = 0; i < Get.find<SplashController>().moduleList!.length; i++){
                        if(widget.cartController.cartList[0].item!.moduleId == Get.find<SplashController>().moduleList![i].id){
                          break;
                        }
                      }
                      Get.find<SplashController>().setModule(Get.find<SplashController>().moduleList![i]);
                      HomeScreen.loadData(true);
                    }
                    Get.find<CouponController>().removeCouponData(false);
                    Get.toNamed(RouteHelper.getCheckoutRoute('cart'));
                  }
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
