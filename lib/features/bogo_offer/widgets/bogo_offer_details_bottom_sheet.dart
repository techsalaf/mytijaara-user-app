import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/helper/bogo_helper.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_bundle_price_text.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_full_screen_sheet.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_item_row_widget.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_quantity_button.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoOfferDetailsBottomSheet extends StatefulWidget {
  final BogoBundleModel bundle;
  final String? offerTitle;
  final String? offerLabel;
  final String? validUntil;
  final int? remainingUses;
  final int? offerModuleId;

  const BogoOfferDetailsBottomSheet({super.key,
    required this.bundle, this.offerTitle, this.offerLabel, this.validUntil, this.remainingUses,
    this.offerModuleId,
  });

  static Future<void> show(BuildContext context, {required BogoBundleModel bundle, String? offerTitle, String? offerLabel, String? validUntil, int? remainingUses,
    int? offerModuleId}) {
    return BogoFullScreenSheet.show(context, child: BogoOfferDetailsBottomSheet(
      bundle: bundle, offerTitle: offerTitle, offerLabel: offerLabel, validUntil: validUntil, remainingUses: remainingUses,
      offerModuleId: offerModuleId,
    ));
  }

  @override
  State<BogoOfferDetailsBottomSheet> createState() => _BogoOfferDetailsBottomSheetState();
}

class _BogoOfferDetailsBottomSheetState extends State<BogoOfferDetailsBottomSheet> {
  int? _pickedQuantity;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(!mounted) {
        return;
      }
      final CartController cartController = Get.find<CartController>();
      if(cartController.allCartsGroups == null || cartController.allCartsGroups!.isEmpty) {
        cartController.getAllCarts(notify: false);
      }
    });
  }

  CartModel? get _cartItem => Get.find<CartController>().findBogoBundleInCart(
    widget.bundle.bundleId, storeId: widget.bundle.store?.id,
  );

  int? get _storeModuleId => BogoHelper.storeModuleId(widget.bundle.store, widget.offerModuleId);

  int _quantityOf(CartModel? cartItem) => _pickedQuantity ?? cartItem?.quantity ?? 1;

  void _increment(CartModel? cartItem) {
    final int quantity = _quantityOf(cartItem);
    final int? limit = widget.remainingUses;
    if(limit != null && quantity >= limit) {
      showCustomSnackBar('you_can_only_use_this_offer_more_times'.trParams({'limit': '$limit'}));
      return;
    }
    setState(() => _pickedQuantity = quantity + 1);
  }

  void _decrement(CartModel? cartItem) {
    final int quantity = _quantityOf(cartItem);
    if(quantity > 1) {
      setState(() => _pickedQuantity = quantity - 1);
    }
  }

  void _openStore() {
    final Store? store = widget.bundle.store;
    if(store?.id == null) {
      return;
    }
    // Left open underneath, so leaving the store comes back to this sheet as it was.
    BogoHelper.openStore(store, offerModuleId: widget.offerModuleId);
  }

  Future<void> _addToCart(int quantity) async {
    if(widget.bundle.bundleId == null || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);

    bool isSuccess = false;
    try {
      isSuccess = await Get.find<CartController>().addBogoToCartOnline(widget.bundle.bundleId!, quantity, moduleId: _storeModuleId);
    } finally {
      if(mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    if(!mounted) {
      return;
    }
    if(isSuccess) {
      RouteHelper.openCart(storeId: widget.bundle.store?.id);
      showCustomSnackBar('item_added_to_cart'.tr, isError: false);
    }
  }

  Future<void> _updateCart(CartModel cartItem, int quantity) async {
    final int? storeId = cartItem.storeId ?? widget.bundle.store?.id;
    if(storeId == null || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);

    bool isSuccess = false;
    try {
      isSuccess = await Get.find<CartController>().setBogoBundleQuantity(cartItem, quantity, storeId: storeId, moduleId: _storeModuleId);
    } finally {
      if(mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    if(!mounted) {
      return;
    }
    if(isSuccess) {
      RouteHelper.openCart(storeId: storeId);
      showCustomSnackBar('cart_updated'.tr, isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BogoBundleModel offer = widget.bundle;
    final int buyCount = offer.buyCount ?? offer.buyItems.length;
    final int getCount = offer.getCount ?? offer.freeItems.length;
    final String offerLabel = widget.offerLabel ?? 'BUY $buyCount GET $getCount FREE';
    final String? distance = BogoHelper.distanceLabel(offer.store);
    final String sheetTitle = (widget.offerTitle?.isNotEmpty ?? false) ? widget.offerTitle! : offerLabel;

    return BogoFullScreenSheet(
      title: sheetTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(offerLabel.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge, color: Colors.blueAccent)),
                          if(widget.validUntil != null) ...[
                            const SizedBox(height: 2),
                            Text('${'valid_until'.tr} : ${widget.validUntil}', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    BogoBundlePriceText(bundlePrice: offer.bundlePrice),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Row(children: [
                  ClipOval(child: CustomImage(image: offer.store?.logoFullUrl ?? '', height: 40, width: 40, fit: BoxFit.cover)),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(offer.store?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                        const SizedBox(height: 2),

                        Row(children: [
                          if(offer.store?.deliveryTime != null && offer.store!.deliveryTime!.isNotEmpty) ...[
                            Icon(Icons.access_time, size: 16, color: Theme.of(context).disabledColor),
                            const SizedBox(width: 2),
                            Text(offer.store!.deliveryTime!, style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                            const SizedBox(width: 2),
                          ],
                          if(distance != null)
                            Text('($distance)', style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                        ]),
                      ],
                    ),
                  ),

                  InkWell(
                    onTap: _openStore,
                    borderRadius: BorderRadius.circular(30),
                    child: CircleAvatar(radius: 20, backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(Icons.arrow_forward_ios_outlined, size: 16, color: Theme.of(context).textTheme.bodyLarge!.color),
                    ),
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Divider(color: Theme.of(context).disabledColor.withValues(alpha: 1)),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text('buy_these'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                for (final BogoOfferItemModel item in offer.buyItems)
                  BogoOfferItemRowWidget(offerItem: item),

                Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text('you_will_get'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                for (final BogoOfferItemModel item in offer.freeItems)
                  BogoOfferItemRowWidget(offerItem: item),
              ],
            ),
          ),
        ),
      ],
      footer: GetBuilder<CartController>(builder: (cartController) {
        final CartModel? cartItem = _cartItem;
        final int quantity = _quantityOf(cartItem);
        final bool isInCart = cartItem != null;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.3))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('total'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      const SizedBox(width: 4),
                      Get.find<SplashController>().configModel?.systemTaxIncludeStatus == 1 ? Text(('vat_tax_inc').tr, style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)) : const SizedBox.shrink(),
                    ],
                  ),
                  BogoBundlePriceText(
                    bundlePrice: offer.bundlePrice, quantity: quantity,
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Row(children: [
                  BogoQuantityButton(icon: Icons.remove, onTap: quantity > 1 ? () => _decrement(cartItem) : null),
                  Expanded(child: Center(child: Text('$quantity', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)))),
                  BogoQuantityButton(icon: Icons.add, onTap: () => _increment(cartItem)),
                  const SizedBox(width: Dimensions.paddingSizeDefault),

                  Expanded(
                    flex: 3,
                    child: CustomButton(
                      buttonText: isInCart ? 'update_in_cart'.tr : 'add_to_cart'.tr,
                      height: 45,
                      width: double.infinity,
                      isLoading: _isSubmitting,
                      onPressed: offer.bundleId == null ? null
                          : isInCart
                              ? (quantity == cartItem.quantity ? null : () => _updateCart(cartItem, quantity))
                              : () => _addToCart(quantity),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// SUMMARY
// Full-screen sheet for one BOGO bundle. Heads with the offer's title, and holds the
// offer label, validity, bundle price, the store row, and the buy and free item lists,
// with a footer that steps the bundle quantity and adds or updates it in the cart.
