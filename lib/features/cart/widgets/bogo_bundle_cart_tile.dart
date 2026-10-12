import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/bogo_item_group_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:sixam_mart/features/bogo_offer/controllers/bogo_offer_controller.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_bundle_price_text.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_details_bottom_sheet.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoBundleCartTile extends StatefulWidget {
  final CartModel cart;
  final int cartIndex;
  final bool isAvailable;
  final bool isStoreOpen;
  const BogoBundleCartTile({super.key, required this.cart, required this.cartIndex, this.isAvailable = true, this.isStoreOpen = true});

  @override
  State<BogoBundleCartTile> createState() => _BogoBundleCartTileState();
}

class _BogoBundleCartTileState extends State<BogoBundleCartTile> {
  Future<BogoOfferDetailsResponseModel?>? _offerDetailsFuture;

  @override
  void initState() {
    super.initState();
    final BogoCartDetails details = widget.cart.bogoDetails!;
    final String? idOrSlug = details.offerSlug ?? details.bogoOfferId?.toString();
    if(idOrSlug != null) {
      _offerDetailsFuture = Get.find<BogoOfferController>().getCachedOfferDetails(idOrSlug);
    }
  }

  Future<void> _openBogoDetails(BuildContext context, BogoCartDetails details) async {
    if(_offerDetailsFuture == null) {
      return;
    }

    final BogoOfferDetailsResponseModel? offerDetails = await _offerDetailsFuture;
    final BogoBundleModel? bundle = _resolveBundle(offerDetails?.bundles, details);
    if(bundle == null || !context.mounted) {
      return;
    }

    BogoOfferDetailsBottomSheet.show(
      context, bundle: bundle, offerTitle: offerDetails?.title, offerLabel: offerDetails?.offerLabel,
      validUntil: offerDetails?.validUntil, remainingUses: offerDetails?.remainingUses,
    );
  }

  BogoBundleModel? _resolveBundle(List<BogoBundleModel>? bundles, BogoCartDetails details) {
    if(bundles == null || bundles.isEmpty) {
      return null;
    }
    for(final BogoBundleModel bundle in bundles) {
      if(details.bundleId != null && bundle.bundleId == details.bundleId) {
        return bundle;
      }
    }
    for(final BogoBundleModel bundle in bundles) {
      if(bundle.store?.id != null && bundle.store!.id == widget.cart.storeId) {
        return bundle;
      }
    }
    return bundles.length == 1 ? bundles.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final CartModel cart = widget.cart;
    final BogoCartDetails details = cart.bogoDetails!;
    final int? storeId = cart.storeId;
    if(storeId == null) {
      return const SizedBox();
    }

    return GetBuilder<CartController>(builder: (cartController) {
      return Stack(children: [
        Slidable(
          key: ValueKey('cart_bogo_${details.bogoGroupId}_${widget.cartIndex}'),
          enabled: !cartController.isLoading,
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (context) => cartController.removeBogoBundle(cart, storeId: storeId),
                backgroundColor: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.trash,
              ),
            ],
          ),
          child: CustomInkWell(
            onTap: () => _openBogoDetails(context, details),
            radius: Dimensions.radiusDefault,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeSmall),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      BogoItemGroupWidget(label: 'buying_item'.tr, thumbnails: details.buyItemThumbnails),
                      const SizedBox(width: Dimensions.paddingSizeExtraLarge),
                      BogoItemGroupWidget(label: 'free_item'.tr, thumbnails: details.freeItemThumbnails),
                    ]),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeExtraSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      QuantityButton(
                        isIncrement: false,
                        flat: true,
                        showRemoveIcon: cart.quantity == 1,
                        onTap: cartController.isLoading ? null : () {
                          if (cart.quantity! > 1) {
                            cartController.updateBogoBundleQuantity(false, cart, storeId: storeId);
                          } else {
                            cartController.removeBogoBundle(cart, storeId: storeId);
                          }
                        },
                      ),
                      Text('${cart.quantity}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      QuantityButton(
                        isIncrement: true,
                        flat: true,
                        onTap: cartController.isLoading ? null : () => cartController.updateBogoBundleQuantity(true, cart, storeId: storeId),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                if(!widget.isAvailable && details.unavailableReason != null) ...[
                  Text(details.unavailableReason!, style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                ],

                Text(
                  details.offerTitle ?? 'bogo_offer'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                
                BogoBundlePriceText(
                  bundlePrice: details.bundlePrice,
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ]),
            ),
          ),
        ),

        widget.isStoreOpen ? const SizedBox() : Positioned.fill(child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          ),
        )),
      ]);
    });
  }
}

// SUMMARY
// Cart row for a BOGO bundle. Shows the offer title, the bundle price against its
// original, the buying and free item thumbnails and any unavailable reason, steps or
// removes the bundle, and opens the bundle sheet on tap.
