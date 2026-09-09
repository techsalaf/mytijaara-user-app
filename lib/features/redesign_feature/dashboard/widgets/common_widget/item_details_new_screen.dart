import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/readmore_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/screens/global_cart_screen.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_review_model.dart';
import 'package:sixam_mart/features/item/widgets/details_web_view_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/food_item_card.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/item_media_carousel_new_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ItemDetailsNewScreen extends StatefulWidget {
  final int itemId;
  final bool inStorePage;
  final bool isCampaign;
  const ItemDetailsNewScreen({
    super.key,
    required this.itemId,
    required this.inStorePage,
    this.isCampaign = false,
  });

  @override
  State<ItemDetailsNewScreen> createState() => _ItemDetailsNewScreenState();
}

class _ItemDetailsNewScreenState extends State<ItemDetailsNewScreen> {
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  Future<void> _handleBackNavigation() async {
    ItemMediaCarouselNewWidget.stopAllVideo();
    await WidgetsBinding.instance.endOfFrame;
    if (Get.find<SplashController>().deeplinkRoute != null) {
      Get.find<SplashController>().setDeeplink(null);
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else {
      Get.back();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFavorite(Item item) {
    if (AuthHelper.isLoggedIn()) {
      final fav = Get.find<FavouriteController>();
      if (fav.wishItemIdList.contains(item.id)) {
        fav.removeFromFavouriteList(item.id, false);
      } else {
        fav.addToFavouriteList(item, null, false);
      }
    } else {
      showCustomSnackBar('you_are_not_logged_in'.tr);
    }
  }

  @override
  void initState() {
    super.initState();

    Get.find<ItemController>().getItemDetails(
      itemId: widget.itemId,
      isCampaign: widget.isCampaign,
    );
    Get.find<ItemController>().setSelect(0, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackNavigation();
        }
      },
      child: GetBuilder<CartController>(
        builder: (cartController) {
          return GetBuilder<ItemController>(
            builder: (itemController) {
              Item? item = itemController.item;

              int? stock = 0;
              CartModel? cartModel;
              OnlineCart? cart;
              double priceWithAddons = 0;
              int? cartId = cartController.getCartId(itemController.cartIndex);
              if (item != null && itemController.variationIndex != null) {
                List<String> variationList = [];
                for (int index = 0; index < item.choiceOptions!.length; index++) {
                  variationList.add(
                    item.choiceOptions![index].options![itemController.variationIndex![index]].replaceAll(' ', ''),
                  );
                }
                String variationType = '';
                bool isFirst = true;
                for (var variation in variationList) {
                  if (isFirst) {
                    variationType = '$variationType$variation';
                    isFirst = false;
                  } else {
                    variationType = '$variationType-$variation';
                  }
                }

                double? price = item.price;
                Variation? variation;
                stock = item.stock ?? 0;
                for (Variation v in item.variations!) {
                  if (v.type == variationType) {
                    price = v.price;
                    variation = v;
                    stock = v.stock;
                    break;
                  }
                }

                double? discount = item.discount;
                String? discountType = item.discountType;
                double priceWithDiscount = PriceConverter.convertWithDiscount(price, discount, discountType)!;
                double priceWithQuantity = priceWithDiscount * itemController.quantity!;
                double addonsCost = 0;
                List<AddOn> addOnIdList = [];
                List<AddOns> addOnsList = [];
                for (int index = 0; index < item.addOns!.length; index++) {
                  if (itemController.addOnActiveList[index]) {
                    addonsCost = addonsCost + (item.addOns![index].price! * itemController.addOnQtyList[index]!);
                    addOnIdList.add(
                      AddOn(
                        id: item.addOns![index].id,
                        quantity: itemController.addOnQtyList[index],
                      ),
                    );
                    addOnsList.add(item.addOns![index]);
                  }
                }

                cartModel = CartModel(
                  null, price, priceWithDiscount, variation != null ? [variation] : [], [],
                  (price! - PriceConverter.convertWithDiscount(price, discount, discountType)!),
                  itemController.quantity, addOnIdList, addOnsList, item.availableDateStarts != null, stock,
                  item, item.quantityLimit
                );

                List<int?> listOfAddOnId = _getSelectedAddonIds(addOnIdList: addOnIdList);
                List<int?> listOfAddOnQty = _getSelectedAddonQtnList(addOnIdList: addOnIdList);

                cart = OnlineCart(
                  cartId, widget.itemId, null, priceWithDiscount.toString(), '', variation != null ? [variation] : [],
                  null, itemController.cartIndex != -1 ? cartController.cartList[itemController.cartIndex].quantity : itemController.quantity,
                  listOfAddOnId, addOnsList, listOfAddOnQty, 'Item',
                );
                priceWithAddons = priceWithQuantity + (Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn! ? addonsCost : 0);
              }

              final String? stockIndicateText = (item != null && (stock ?? 0) > 0 &&
                  (item.storeDetails?.showLowStockCount ?? false) && (stock ?? 0) <= (item.storeDetails?.minimumStockForWarning ?? 0))
                  ? "${'only'.tr} ${stock ?? 0} ${'products_left'.tr}"
                  : null;

              final bool isDesktop = ResponsiveHelper.isDesktop(context);
              final double mediaHeight = MediaQuery.of(context).size.width * 0.7;
              final double sliverExpandedHeight = mediaHeight;

              return Scaffold(
                key: _globalKey,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                endDrawer: const MenuDrawer(),
                endDrawerEnableOpenDragGesture: false,
                extendBodyBehindAppBar: !isDesktop,
                appBar: isDesktop ? const CustomAppBar(title: '') : null,

                body: (item != null)
                    ? isDesktop
                          ? DetailsWebViewWidget(
                              cartModel: cartModel,
                              stock: stock,
                              priceWithAddOns: priceWithAddons,
                              cart: cart,
                              stockIndicateText: stockIndicateText,
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverAppBar(
                                        pinned: true,
                                        stretch: false,
                                        expandedHeight: sliverExpandedHeight,
                                        backgroundColor: Theme.of(context).cardColor,
                                        surfaceTintColor: Theme.of(context).cardColor,
                                        elevation: 0,
                                        scrolledUnderElevation: 1,
                                        automaticallyImplyLeading: false,
                                        centerTitle: true,
                                        leadingWidth: 56,
                                        leading: Padding(
                                          padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                          child: Center(
                                            child: _FloatingCircleButton(
                                              icon: Icons.arrow_back,
                                              onTap: _handleBackNavigation,
                                            ),
                                          ),
                                        ),
                                        title: AnimatedBuilder(
                                          animation: _scrollController,
                                          builder: (context, _) {
                                            final double offset = _scrollController.hasClients
                                                ? _scrollController.offset
                                                : 0.0;
                                            final double collapseStart = sliverExpandedHeight - kToolbarHeight - 40;
                                            final double opacity = ((offset - collapseStart) / 30).clamp(0.0, 1.0);
                                            return Opacity(
                                              opacity: opacity,
                                              child: Text(
                                                item.name ?? '',
                                                style: robotoMedium.copyWith(
                                                  fontSize: Dimensions.fontSizeLarge,
                                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          },
                                        ),
                                        actions: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: Dimensions.paddingSizeSmall,
                                            ),
                                            child: Center(
                                              child: GetBuilder<FavouriteController>(
                                                builder: (fav) {
                                                  final bool inFav = fav.wishItemIdList.contains(item.id);
                                                  return _FloatingCircleButton(
                                                    icon: inFav
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    iconColor: inFav
                                                        ? Theme.of(context).primaryColor
                                                        : null,
                                                    onTap: () => _toggleFavorite(item),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: Dimensions.paddingSizeSmall,
                                            ),
                                            child: Center(
                                              child: _FloatingCartButton(
                                                onTap: () {
                                                  ItemMediaCarouselNewWidget.stopAllVideo();
                                                  Get.to(() => const GlobalCartScreen(fromNav: false));
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                        flexibleSpace: FlexibleSpaceBar(
                                          collapseMode: CollapseMode.pin,
                                          background: Container(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            child: ItemMediaCarouselNewWidget(
                                              item: item,
                                              isCampaign: widget.isCampaign,
                                              mainHeight: mediaHeight,
                                              showThumbnails: false,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SliverToBoxAdapter(
                                        child: MediaThumbStripWidget(
                                          item: item,
                                          isCampaign: widget.isCampaign,
                                        ),
                                      ),

                                      SliverToBoxAdapter(
                                        child: Center(
                                          child: SizedBox(
                                            width: Dimensions.webMaxWidth,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  height: Dimensions.paddingSizeSmall,
                                                ),

                                                Container(
                                                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                                                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _ItemTitleSection(
                                                        item: item,
                                                        isCampaign: item.availableDateStarts != null,
                                                        isOutOfStock: Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && (stock ?? 0) <= 0,
                                                        stockIndicateText: stockIndicateText,
                                                      ),

                                                      if (item.isPrescriptionRequired!)
                                                        Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: Dimensions.paddingSizeSmall,
                                                            vertical: Dimensions.paddingSizeExtraSmall,
                                                          ),
                                                          margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                          ),
                                                          child: Text(
                                                            '* ${'prescription_required'.tr}',
                                                            style: robotoRegular.copyWith(
                                                              fontSize: Dimensions.fontSizeSmall,
                                                              color: Theme.of(context).colorScheme.error,
                                                            ),
                                                          ),
                                                        ),

                                                      if (item.choiceOptions!.isNotEmpty)
                                                        const SizedBox(height: Dimensions.paddingSizeDefault),
                                                      if (item.choiceOptions!.isNotEmpty)
                                                        _VariationSection(
                                                          item: item,
                                                          controller: itemController,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: Dimensions.paddingSizeSmall,
                                                ),

                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                                                  child: _ProductDetailsSection(item: item),
                                                ),

                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: Dimensions.paddingSizeDefault,
                                                    vertical: Dimensions.paddingSizeExtraSmall,
                                                  ),
                                                  child: _ReviewRatingSection(item: item),
                                                ),

                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: Dimensions.paddingSizeDefault,
                                                    vertical: Dimensions.paddingSizeExtraSmall,
                                                  ),
                                                  child: _StoreInfoSection(item: item),
                                                ),

                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: Dimensions.paddingSizeDefault,
                                                    vertical: Dimensions.paddingSizeExtraSmall,
                                                  ),
                                                  child: _AlsoLoveSection(item: item),
                                                ),
                                                const SizedBox(
                                                  height: Dimensions.paddingSizeDefault,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        spreadRadius: 1,
                                        blurRadius: 7,
                                        offset: const Offset(0, -3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall,
                                  ),
                                  child: GetBuilder<CartController>(
                                    builder: (cartController) {
                                      bool isAvailable = DateConverter.isAvailable(
                                            item.availableTimeStarts,
                                            item.availableTimeEnds,
                                          );

                                      return (item.availableDateStarts != null && !isAvailable)
                                          ? Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(
                                                Dimensions.paddingSizeSmall,
                                              ),
                                              margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall,),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'not_available_now'.tr,
                                                    style: robotoMedium.copyWith(
                                                      color: Theme.of(context).primaryColor,
                                                      fontSize: Dimensions.fontSizeLarge,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${'available_will_be'.tr} ${DateConverter.convertTimeToTime(item.availableTimeStarts!)} '
                                                    '- ${DateConverter.convertTimeToTime(item.availableTimeEnds!)}',
                                                    style: robotoRegular,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Column(
                                              children: [
                                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'total_amount'.tr,
                                                      style: robotoMedium.copyWith(
                                                        fontSize: Dimensions.fontSizeLarge,
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    ),

                                                    Text(
                                                      PriceConverter.convertPrice(
                                                        itemController.cartIndex != -1
                                                            ? _getItemDetailsDiscountPrice(
                                                                cart: Get.find<CartController>().cartList[itemController.cartIndex],
                                                              )
                                                            : priceWithAddons,
                                                      ),
                                                      textDirection: TextDirection.ltr,
                                                      style: robotoBold
                                                          .copyWith(
                                                            color: Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                            fontSize: Dimensions
                                                                .fontSizeLarge,
                                                          ),
                                                    ),
                                                  ],
                                                ),

                                                Row(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        InkWell(
                                                          onTap:
                                                              cartController
                                                                  .isLoading
                                                              ? null
                                                              : () {
                                                                  if (itemController
                                                                          .cartIndex !=
                                                                      -1) {
                                                                    if (cartController
                                                                            .cartList[itemController.cartIndex]
                                                                            .quantity! >
                                                                        1) {
                                                                      cartController.setQuantity(
                                                                        false,
                                                                        itemController
                                                                            .cartIndex,
                                                                        stock,
                                                                        cartController
                                                                            .cartList[itemController.cartIndex]
                                                                            .quantity,
                                                                      );
                                                                    }
                                                                  } else {
                                                                    if (itemController
                                                                            .quantity! >
                                                                        1) {
                                                                      itemController.setQuantity(
                                                                        false,
                                                                        stock,
                                                                        item.quantityLimit,
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .disabledColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: Dimensions
                                                                  .paddingSizeSmall,
                                                              vertical: Dimensions
                                                                  .paddingSizeExtraSmall,
                                                            ),
                                                            child: const Icon(
                                                              Icons.remove,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),

                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: Dimensions
                                                                .paddingSizeSmall,
                                                          ),
                                                          child: Text(
                                                            itemController
                                                                        .cartIndex !=
                                                                    -1
                                                                ? cartController
                                                                      .cartList[itemController
                                                                          .cartIndex]
                                                                      .quantity
                                                                      .toString()
                                                                : itemController
                                                                      .quantity
                                                                      .toString(),
                                                            style: robotoMedium
                                                                .copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeExtraLarge,
                                                                ),
                                                          ),
                                                        ),

                                                        InkWell(
                                                          onTap:
                                                              cartController
                                                                  .isLoading
                                                              ? null
                                                              : () =>
                                                                    itemController
                                                                            .cartIndex !=
                                                                        -1
                                                                    ? cartController.setQuantity(
                                                                        true,
                                                                        itemController
                                                                            .cartIndex,
                                                                        stock,
                                                                        cartController
                                                                            .cartList[itemController.cartIndex]
                                                                            .quantityLimit,
                                                                      )
                                                                    : itemController.setQuantity(
                                                                        true,
                                                                        stock,
                                                                        item.quantityLimit,
                                                                      ),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: Dimensions
                                                                  .paddingSizeSmall,
                                                              vertical: Dimensions
                                                                  .paddingSizeExtraSmall,
                                                            ),
                                                            child: const Icon(
                                                              Icons.add,
                                                              size: 20,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeSmall,
                                                    ),

                                                    Expanded(
                                                      child: Container(
                                                        width: 1170,
                                                        padding:
                                                            const EdgeInsets.all(
                                                              Dimensions
                                                                  .paddingSizeSmall,
                                                            ),
                                                        child: CustomButton(
                                                          isLoading:
                                                              cartController
                                                                  .isLoading,
                                                          buttonText:
                                                              (Get.find<
                                                                        SplashController
                                                                      >()
                                                                      .configModel!
                                                                      .moduleConfig!
                                                                      .module!
                                                                      .stock! &&
                                                                  stock! <= 0)
                                                              ? 'out_of_stock'
                                                                    .tr
                                                              : item.availableDateStarts !=
                                                                    null
                                                              ? 'order_now'.tr
                                                              : itemController
                                                                        .cartIndex !=
                                                                    -1
                                                              ? 'update_in_cart'
                                                                    .tr
                                                              : 'add_to_cart'
                                                                    .tr,
                                                          onPressed:
                                                              (!Get.find<
                                                                        SplashController
                                                                      >()
                                                                      .configModel!
                                                                      .moduleConfig!
                                                                      .module!
                                                                      .stock! ||
                                                                  stock! > 0)
                                                              ? () async {
                                                                  if (AddressHelper.getUserAddressFromSharedPref() ==
                                                                      null) {
                                                                    Get.find<
                                                                          LocationController
                                                                        >()
                                                                        .navigateToLocationScreen(
                                                                          'home',
                                                                          canRoute:
                                                                              true,
                                                                        );
                                                                    return;
                                                                  }

                                                                  if (!Get.find<
                                                                            SplashController
                                                                          >()
                                                                          .configModel!
                                                                          .moduleConfig!
                                                                          .module!
                                                                          .stock! ||
                                                                      stock! >
                                                                          0) {
                                                                    if (item.availableDateStarts !=
                                                                        null) {
                                                                      Get.toNamed(
                                                                        RouteHelper.getCheckoutRoute(
                                                                          'campaign',
                                                                        ),
                                                                        arguments: CheckoutScreen(
                                                                          storeId:
                                                                              null,
                                                                          fromCart:
                                                                              false,
                                                                          cartList: [
                                                                            cartModel,
                                                                          ],
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      if (itemController
                                                                              .cartIndex ==
                                                                          -1) {
                                                                        await cartController
                                                                            .addToCartOnline(
                                                                              cart!,
                                                                              storeId: item.storeId,
                                                                            )
                                                                            .then((
                                                                              success,
                                                                            ) {
                                                                              if (success) {
                                                                                itemController.setExistInCart(
                                                                                  item,
                                                                                  null,
                                                                                );
                                                                                showCartSnackBar();
                                                                              }
                                                                            });
                                                                      } else {
                                                                        await cartController
                                                                            .updateCartOnline(
                                                                              cart!,
                                                                              storeId: item.storeId,
                                                                            )
                                                                            .then((
                                                                              success,
                                                                            ) {
                                                                              if (success) {
                                                                                showCartSnackBar();
                                                                              }
                                                                            });
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                    },
                                  ),
                                ),
                              ],
                            )
                    : const Center(child: CircularProgressIndicator()),
              );
            },
          );
        },
      ),
    );
  }

  List<int?> _getSelectedAddonIds({required List<AddOn> addOnIdList}) {
    List<int?> listOfAddOnId = [];
    for (var addOn in addOnIdList) {
      listOfAddOnId.add(addOn.id);
    }
    return listOfAddOnId;
  }

  List<int?> _getSelectedAddonQtnList({required List<AddOn> addOnIdList}) {
    List<int?> listOfAddOnQty = [];
    for (var addOn in addOnIdList) {
      listOfAddOnQty.add(addOn.quantity);
    }
    return listOfAddOnQty;
  }

  double _getItemDetailsDiscountPrice({required CartModel cart}) {
    double discountedPrice = 0;

    double? discount = cart.item!.discount;
    String? discountType = cart.item!.discountType;
    String variationType = cart.variation != null && cart.variation!.isNotEmpty
        ? cart.variation![0].type!
        : '';

    if (cart.variation != null && cart.variation!.isNotEmpty) {
      for (Variation variation in cart.item!.variations!) {
        if (variation.type == variationType) {
          discountedPrice =
              (PriceConverter.convertWithDiscount(
                variation.price!,
                discount,
                discountType,
              )! *
              cart.quantity!);
          break;
        }
      }
    } else {
      discountedPrice =
          (PriceConverter.convertWithDiscount(
            cart.item!.price!,
            discount,
            discountType,
          )! *
          cart.quantity!);
    }

    return discountedPrice;
  }
}

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: iconColor ?? Colors.black87),
        ),
      ),
    );
  }
}

class _FloatingCartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingCartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.black87),

              GetBuilder<CartController>(
                builder: (cartController) {
                  final int count = cartController.allCartsItemCount;
                  if (cartController.isLoading || count == 0) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    top: 3, right: 3,
                    child: Container(
                      height: 16, width: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.error,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        count.toString(),
                        style: robotoRegular.copyWith(fontSize: 9, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTitleSection extends StatelessWidget {
  final Item item;
  final bool isCampaign;
  final bool isOutOfStock;
  final String? stockIndicateText;
  const _ItemTitleSection({
    required this.item,
    required this.isCampaign,
    required this.isOutOfStock,
    this.stockIndicateText,
  });

  @override
  Widget build(BuildContext context) {
    double? startingPrice;
    double? endingPrice;
    if (item.variations!.isNotEmpty) {
      List<double?> priceList = [];
      for (var variation in item.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if (priceList[0]! < priceList[priceList.length - 1]!) {
        endingPrice = priceList[priceList.length - 1];
      }
    } else {
      startingPrice = item.price;
    }

    double? discount = item.discount;
    String? discountType = item.discountType;
    final bool hasFreeDelivery = item.freeDelivery ?? (Get.find<StoreController>().store?.freeDelivery ?? false);
    print("=======>>> $hasFreeDelivery @@@===");

    final List<String> tags = [];
    if (item.organic == 1 && item.moduleType == 'grocery') {
      tags.add('organic');
    }
    if (item.isStoreHalalActive! && item.isHalalItem!) {
      tags.add('halal');
    }
    if ((Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && item.unitType != null) ||
        (Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! &&
            Get.find<SplashController>().configModel!.toggleVegNonVeg!)) {
      tags.add(
        Get.find<SplashController>().configModel!.moduleConfig!.module!.unit!
            ? item.unitType ?? ''
            : item.veg == 0
            ? 'non_veg'
            : 'veg',
      );
    }

    final String currencySymbol = Get.find<SplashController>().configModel!.currencySymbol ?? '';
    final String discountLabel = discount! > 0
        ? (discountType == 'percent'
              ? '-${discount.toInt()}%'
              : '-$currencySymbol${discount.toInt()}')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name ?? '',
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        if (!isCampaign && item.avgRating != null && item.ratingCount != null &&
            item.ratingCount != 0 && item.avgRating != 0)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: RatingBar(
              rating: item.avgRating,
              ratingCount: item.ratingCount,
              showRatingText: true,
            ),
          ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${PriceConverter.convertPrice(startingPrice, discount: discount, discountType: discountType)}'
              '${endingPrice != null ? ' - ${PriceConverter.convertPrice(endingPrice, discount: discount, discountType: discountType)}' : ''}',
              style: robotoBold.copyWith(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontSize: Dimensions.fontSizeExtraLarge,
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            if (discount > 0)
              Text(
                '${PriceConverter.convertPrice(startingPrice)}'
                '${endingPrice != null ? ' - ${PriceConverter.convertPrice(endingPrice)}' : ''}',
                textDirection: TextDirection.ltr,
                style: robotoRegular.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  decoration: TextDecoration.lineThrough,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeExtraSmall,
          children: [
            if (discount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Text(
                  discountLabel,
                  style: robotoMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),

            if (hasFreeDelivery)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pedal_bike_outlined, size: 14, color: Color(0xFFFF2020)),
                    const SizedBox(width: 4),
                    Text(
                      'free'.tr,
                      style: robotoMedium.copyWith(
                        color: const Color(0xFFFF2020),
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? Colors.red.withValues(alpha: 0.1)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: Text(
                isOutOfStock
                    ? 'out_of_stock'.tr
                    : (stockIndicateText ?? 'in_stock'.tr),
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isOutOfStock
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
              ),
            ),

            if (tags.isNotEmpty)
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeExtraSmall,
                children: List.generate(tags.length, (index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: 3,
                    ),
                    child: Text(
                      tags[index].tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                }),
              ),

          ],
        ),

        if (item.genericName != null && item.genericName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Wrap(
              children: List.generate(item.genericName!.length, (index) {
                return Text(
                  '${item.genericName![index]}${item.genericName!.length - 1 == index ? '.' : ', '}',
                  style: robotoRegular.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.color?.withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ),
        /*Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: InkWell(
            onTap: () => Get.offNamed(
              RouteHelper.getStoreRoute(
                id: item.storeId,
                page: 'item',
                slug: item.storeDetails?.slug ?? '',
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.storeName ?? '',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ),
                if (item.verifiedSeller == 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraSmall,
                    ),
                    child: Image.asset(
                      Images.verifiedBadge,
                      width: 14,
                      height: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),*/

      ],
    );
  }
}

class _VariationSection extends StatelessWidget {
  final Item item;
  final ItemController controller;
  const _VariationSection({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          width: 2
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: item.choiceOptions!.length,
        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final choice = item.choiceOptions![index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Row(
                  children: [
                    Text(
                      choice.title ?? '',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      '(${choice.options![controller.variationIndex![index]].trim()})',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: choice.options!.length,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  separatorBuilder: (context, i) => const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemBuilder: (context, i) {
                    final bool selected = controller.variationIndex![index] == i;
                    return InkWell(
                      onTap: () => controller.setCartVariationIndex(index, i, item),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          color: selected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          choice.options![i].trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: selected
                              ? robotoMedium.copyWith(
                            color: Theme.of(context).cardColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ) : robotoRegular.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  const _ExpandableCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: widget.initiallyExpanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              0,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
            ),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              widget.title,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Theme.of(context).textTheme.bodyLarge!.color,
                size: 20,
              ),
            ),
            children: [widget.child],
          ),
        ),
      ),
    );
  }
}

class _ProductDetailsSection extends StatelessWidget {
  final Item item;
  const _ProductDetailsSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool hasDescription = item.description != null && item.description!.isNotEmpty;
    final bool hasNutrition = item.nutritionsName != null && item.nutritionsName!.isNotEmpty;
    final bool hasAllergies = item.allergiesName != null && item.allergiesName!.isNotEmpty;

    if (!hasDescription && !hasNutrition && !hasAllergies) {
      return const SizedBox.shrink();
    }

    return _ExpandableCard(
      title: 'product_details'.tr,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDescription)
            ReadMoreText(
              item.description!,
              style: robotoRegular.copyWith(
                color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.7),
              ),
              trimMode: TrimMode.Line,
              trimLines: 3,
              colorClickableText: Theme.of(context).primaryColor,
              lessStyle: robotoBold.copyWith(color: Colors.blueAccent),
              trimCollapsedText: 'read_more'.tr,
              moreStyle: robotoBold.copyWith(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
              trimExpandedText: ' ${'show_less'.tr}',
            ),

          if (hasNutrition)
            Padding(
              padding: const EdgeInsets.only(
                top: Dimensions.paddingSizeDefault,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('nutrition_details'.tr, style: robotoMedium),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Wrap(
                    children: List.generate(item.nutritionsName!.length, (
                      index,
                    ) {
                      return Text(
                        '${item.nutritionsName![index]}${item.nutritionsName!.length - 1 == index ? '.' : ', '}',
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

          if (hasAllergies)
            Padding(
              padding: const EdgeInsets.only(
                top: Dimensions.paddingSizeDefault,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('allergic_ingredients'.tr, style: robotoMedium),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Wrap(
                    children: List.generate(item.allergiesName!.length, (
                      index,
                    ) {
                      return Text(
                        '${item.allergiesName![index]}${item.allergiesName!.length - 1 == index ? '.' : ', '}',
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewRatingSection extends StatefulWidget {
  final Item item;
  const _ReviewRatingSection({required this.item});

  @override
  State<_ReviewRatingSection> createState() => _ReviewRatingSectionState();
}

class _ReviewRatingSectionState extends State<_ReviewRatingSection> {
  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void didUpdateWidget(covariant _ReviewRatingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadReviews();
    }
  }

  void _loadReviews() {
    final int? itemId = widget.item.id;
    if (itemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.find<ItemController>().getItemReviews(
            itemId: itemId,
            reload: true,
          );
        }
      });
    }
  }

  String _breakdownLabel(String? label) {
    switch (label) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'good'.tr;
      case 'average':
        return 'average'.tr;
      case 'below':
        return 'Below';
      case 'poor':
        return 'Poor';
      default:
        return label ?? '';
    }
  }

  List<RatingBreakdown> _breakdownRows(RatingSummary? summary) {
    final List<RatingBreakdown> breakdown =
        summary?.breakdown ?? <RatingBreakdown>[];
    if (breakdown.isNotEmpty) {
      return breakdown;
    }
    return <RatingBreakdown>[
      RatingBreakdown(label: 'excellent', star: 5, count: 0),
      RatingBreakdown(label: 'good', star: 4, count: 0),
      RatingBreakdown(label: 'average', star: 3, count: 0),
      RatingBreakdown(label: 'below', star: 2, count: 0),
      RatingBreakdown(label: 'poor', star: 1, count: 0),
    ];
  }

  void _showAllReviews(BuildContext context, List<ItemReview> reviews) {
    FocusScope.of(context).unfocus();
    final DraggableScrollableController sheetController = DraggableScrollableController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: 400),
        reverseCurve: Curves.easeInCubic,
        reverseDuration: Duration(milliseconds: 280),
      ),
      builder: (_) => DraggableScrollableSheet(
        controller: sheetController,
        initialChildSize: 0.6,
        minChildSize: 0.56,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollController) => AnimatedBuilder(
          animation: sheetController,
          builder: (ctx, _) {
            final double extent = sheetController.isAttached
                ? sheetController.size
                : 0.6;
            final bool isFullScreen = extent >= 0.99;
            final double topPad = isFullScreen
                ? MediaQuery.of(context).padding.top
                : 0;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    isFullScreen ? 0 : Dimensions.radiusExtraLarge,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: topPad),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${'reviews'.tr} (${reviews.length})',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(20),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).disabledColor.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeDefault,
                      ),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => Divider(
                        height: Dimensions.paddingSizeLarge,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).disabledColor.withValues(alpha: 0.15),
                      ),
                      itemBuilder: (_, index) =>
                          _ReviewerTile(review: reviews[index]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      sheetController.dispose();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ExpandableCard(
      title: 'review_and_rating'.tr,
      child: GetBuilder<ItemController>(
        builder: (itemController) {
          final ItemReviewModel? itemReviewModel =
              itemController.itemReviewModel;
          final RatingSummary? summary = itemReviewModel?.ratingSummary;
          final List<ItemReview> reviews =
              itemReviewModel?.reviews ?? <ItemReview>[];
          final int totalReviews =
              summary?.totalReviews ??
              itemReviewModel?.totalSize ??
              widget.item.ratingCount ??
              0;
          final double avgRating =
              summary?.avgRating ?? widget.item.avgRating ?? 0;
          final bool showSeeAll =
              itemReviewModel != null &&
              (totalReviews > 3 ||
                  reviews.any((review) => (review.reply ?? '').isNotEmpty));
          final List<RatingBreakdown> breakdownRows = _breakdownRows(summary);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                        ),
                      ),
                      height: 100,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(Images.starFill, width: 18, height: 18),
                              const SizedBox(
                                width: Dimensions.paddingSizeExtraSmall,
                              ),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeOverLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            '$totalReviews ${'reviews'.tr}',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    Expanded(
                      child: Column(
                        children: List.generate(breakdownRows.length, (index) {
                          final RatingBreakdown breakdown = breakdownRows[index];
                          final int count = breakdown.count ?? 0;
                          return _RatingBreakdownRow(
                            label: _breakdownLabel(breakdown.label),
                            percent: totalReviews == 0 ? 0 : count / totalReviews,
                            count: '$count',
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              const Divider(height: 1),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${'reviews'.tr} ($totalReviews)',
                      style: robotoSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),
                  if (showSeeAll)
                    GestureDetector(
                      onTap: () => _showAllReviews(context, reviews),
                      child: Text(
                        'see_all'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              if (itemReviewModel == null)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                  child: Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (reviews.isEmpty)
                Text(
                  'no_review_found'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).disabledColor,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: reviews.length.clamp(0, 3),
                  separatorBuilder: (_, _) => Divider(
                    height: Dimensions.paddingSizeLarge,
                    thickness: 1,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                  ),
                  itemBuilder: (_, index) => _ReviewerTile(review: reviews[index]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingBreakdownRow extends StatelessWidget {
  final String label;
  final double percent;
  final String count;
  const _RatingBreakdownRow({
    required this.label,
    required this.percent,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 4,
                backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(
            count,
            style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ],
      ),
    );
  }
}

class _ReviewerTile extends StatefulWidget {
  final ItemReview review;
  const _ReviewerTile({required this.review});

  @override
  State<_ReviewerTile> createState() => _ReviewerTileState();
}

class _ReviewerTileState extends State<_ReviewerTile> {
  bool _commentExpanded = false;
  bool _replyExpanded = false;
  static const int _collapsedReviewLines = 2;

  @override
  Widget build(BuildContext context) {
    final ItemReview review = widget.review;
    final String name = (review.customer?.fullName ?? '').isNotEmpty
        ? review.customer!.fullName
        : 'unknown'.tr;
    final String date =
        (review.createdAt != null && review.createdAt!.isNotEmpty)
        ? DateConverter.stringToLocalDateOnly(review.createdAt!)
        : '';
    final String comment = review.comment ?? '';
    final String reply = review.reply ?? '';
    final double ratingValue = (review.rating ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ReviewerInitialsAvatar(name: name),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      date,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(Images.starFill, width: 14, height: 14),
                  const SizedBox(width: 2),
                  Text(
                    ratingValue.toStringAsFixed(1),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          if (comment.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final TextStyle textStyle = robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor,
                );
                final TextPainter textPainter = TextPainter(
                  text: TextSpan(text: comment, style: textStyle),
                  maxLines: _collapsedReviewLines,
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);
                final bool isOverflowing = textPainter.didExceedMaxLines;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: Text(
                          comment,
                          style: textStyle,
                          maxLines: _commentExpanded
                              ? null
                              : _collapsedReviewLines,
                          overflow: _commentExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (isOverflowing) ...[
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      InkWell(
                        onTap: () =>
                            setState(() => _commentExpanded = !_commentExpanded),
                        borderRadius: BorderRadius.circular(16),
                        child: Icon(
                          _commentExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

          if (reply.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _replyExpanded
                  ? AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: 1,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).disabledColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall,
                            ),
                            Expanded(
                              child: Text(
                                reply,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Center(
              child: InkWell(
                onTap: () => setState(() => _replyExpanded = !_replyExpanded),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _replyExpanded ? 'hide_reply'.tr : 'see_reply'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      AnimatedRotation(
                        turns: _replyExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewerInitialsAvatar extends StatelessWidget {
  final String name;
  const _ReviewerInitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        _buildInitials(name),
        style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

class _StoreInfoSection extends StatefulWidget {
  final Item item;
  const _StoreInfoSection({required this.item});

  @override
  State<_StoreInfoSection> createState() => _StoreInfoSectionState();
}

class _StoreInfoSectionState extends State<_StoreInfoSection> {
  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
  }

  @override
  void didUpdateWidget(covariant _StoreInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.storeId != widget.item.storeId) {
      _loadStoreDetails();
    }
  }

  void _loadStoreDetails() {
    final int? storeId = widget.item.storeId ?? widget.item.storeDetails?.id;
    if (storeId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final StoreController storeController = Get.find<StoreController>();
      if (storeController.store?.id != storeId) {
        storeController.getStoreDetails(Store(id: storeId), false, slug: '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ExpandableCard(
      title: 'store_info'.tr,
      child: GetBuilder<StoreController>(
        builder: (storeController) {
          final int? itemStoreId = widget.item.storeId ?? widget.item.storeDetails?.id;
          final Store? store = storeController.store?.id == itemStoreId
              ? storeController.store
              : null;
          final String storeName = store?.name ?? widget.item.storeName ?? widget.item.storeDetails?.name ?? '';
          final String storeImage = store?.logoFullUrl ?? widget.item.storeImageFullUrl ?? '';
          final String address = store?.address ?? '';
          final double rating = store?.avgRating ?? 0;
          final int ratingCount = store?.ratingCount ?? 0;
          final String deliveryTime = store?.deliveryTime ?? '';
          final String minimumOrder = store?.minimumOrder != null
              ? PriceConverter.convertPrice(store!.minimumOrder)
              : '--';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  if(store != null) {
                    Get.toNamed(
                      RouteHelper.getStoreRoute(id: store.id, page: 'item', slug: store.slug??''),
                    );
                  }
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: CustomImage(
                        image: storeImage,
                        height: 44,
                        width: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              address,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).disabledColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Container(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StoreInfoChip(
                        icon: Images.starFill,
                        label:rating.toStringAsFixed(1),
                        isImage: true, description: '($ratingCount ${'reviews'.tr})',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    ),
                    Expanded(child: _StoreInfoChip(
                      label: minimumOrder, 
                      description: 'min_order'.tr,
                    )),
                    Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _StoreInfoChip(
                        label: deliveryTime.isNotEmpty ? deliveryTime : '--',
                        description: 'delivery_time'.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoreInfoChip extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String description;
  final bool isImage;
  const _StoreInfoChip({
    this.icon,
    required this.label,
    required this.description,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isImage)
                Image.asset(icon as String, width: 14, height: 14)
              else if (icon != null)
                Icon(
                  icon as IconData,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
              if (icon != null) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
              ),
            ],
          ),
          Text(
            description,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlsoLoveSection extends StatefulWidget {
  final Item item;
  const _AlsoLoveSection({required this.item});

  @override
  State<_AlsoLoveSection> createState() => _AlsoLoveSectionState();
}

class _AlsoLoveSectionState extends State<_AlsoLoveSection> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
  }

  @override
  void didUpdateWidget(covariant _AlsoLoveSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.storeId != widget.item.storeId || oldWidget.item.id != widget.item.id) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    final int? storeId = widget.item.storeId ?? widget.item.storeDetails?.id;
    if (storeId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final StoreController storeController = Get.find<StoreController>();
      if (storeController.store?.id != storeId) {
        await storeController.getStoreDetails(Store(id: storeId), false, slug: '');
      }
      if (!mounted) return;
      storeController.getStoreItemList(storeId, 1, 'all', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Item>? all = storeController.storeItemModel?.items;
      if (all == null) {
        return const _AlsoLoveLoadingSection();
      }
      final List<Item> others = all.where((item) => item.id != widget.item.id).toList();
      if (others.isEmpty) {
        return const SizedBox();
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [
              Expanded(child: Text('items_you_will_also_love'.tr, style: robotoSemiBold.copyWith(
                fontSize: Dimensions.fontSizeLarge
              ),)),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    size: 20,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded ? const SizedBox(width: double.infinity) : SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: others.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? Dimensions.paddingSizeDefault : 0,
                    right: Dimensions.paddingSizeDefault,
                  ),
                  child: FoodItemCard(data: others[index], width: 150, index: index),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// class _AlsoLoveCard extends StatelessWidget {
//   final Item item;
//   final int index;
//   const _AlsoLoveCard({required this.item, required this.index});

//   @override
//   Widget build(BuildContext context) {
//     final bool isAvailable = DateConverter.isAvailable(item.availableTimeStarts, item.availableTimeEnds);

//     return InkWell(
//       onTap: () => Get.find<ItemController>().navigateToItemPage(item, context, inStore: true, isCampaign: false, ),
//       borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//       child: Container(
//         width: 182,
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//         ),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
//             child: Stack(children: [
//               CustomImage(
//                 image: item.imageFullUrl ?? '',
//                 height: 132,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 placeholder: Images.placeholder,
//               ),
//               Positioned(
//                 bottom: 8,
//                 right: 8,
//                 child: Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).cardColor,
//                     boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
//                     borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
//                   ),
//                   child: const Icon(Icons.add, size: 20),
//                 ),
//               ),
//               if (item.isStoreHalalActive == true && item.isHalalItem == true)
//                 Positioned(top: 8, left: 8, child: Image.asset(Images.halalTag, width: 24, height: 24)),
//               if (item.veg == 1)
//                 Positioned(top: 8, left: item.isStoreHalalActive == true && item.isHalalItem == true ? 36 : 8, child: Image.asset(Images.vegLogo, width: 24, height: 24)),
//               if (!isAvailable)
//                 Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.35), alignment: Alignment.center,
//                   child: Text('not_available_now_break'.tr, textAlign: TextAlign.center, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
//                 )),
//             ]),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Row(children: [
//                 const Icon(Icons.star, size: 15, color: Color(0xFFFFA000)),
//                 const SizedBox(width: 3),
//                 Expanded(child: Text(
//                   '${(item.avgRating ?? 0).toStringAsFixed(1)} (${item.ratingCount ?? 0}+ ${'reviews'.tr})',
//                   maxLines: 1, overflow: TextOverflow.ellipsis,
//                   style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
//                 )),
//               ]),
//               const SizedBox(height: Dimensions.paddingSizeExtraSmall),
//               Text(
//                 item.name ?? '',
//                 style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: Dimensions.paddingSizeExtraSmall),
//               Row(children: [
//                 Expanded(child: Text(
//                   PriceConverter.convertPrice(item.price, discount: item.discount, discountType: item.discountType),
//                   textDirection: TextDirection.ltr,
//                   style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 )),
//                 if ((item.discount ?? 0) > 0) Text(
//                   PriceConverter.convertPrice(item.price),
//                   textDirection: TextDirection.ltr,
//                   style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
              
//               ]),
              
//             ]),
//           ),
//         ]),
//       ),
//     );
//   }
// }

class _AlsoLoveLoadingSection extends StatelessWidget {
  const _AlsoLoveLoadingSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(children: [
            Expanded(child: Text('items_you_will_also_love'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ]),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? Dimensions.paddingSizeDefault : 0,
                right: Dimensions.paddingSizeDefault,
              ),
              child: Container(
                width: 182,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 132, decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)))),
                  const Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _AlsoLoveSkeletonLine(width: 90),
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      _AlsoLoveSkeletonLine(width: 145),
                      SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      _AlsoLoveSkeletonLine(width: 118),
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      _AlsoLoveSkeletonLine(width: 70),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _AlsoLoveSkeletonLine extends StatelessWidget {
  final double width;
  const _AlsoLoveSkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
