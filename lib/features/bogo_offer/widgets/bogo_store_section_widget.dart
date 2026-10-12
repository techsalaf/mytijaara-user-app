import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_details_bottom_sheet.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// BOGO — this store's own bundles, one row per offer.
class BogoStoreSectionWidget extends StatelessWidget {
  final List<StoreBogoOfferModel> offers;
  final int? storeId;
  const BogoStoreSectionWidget({super.key, required this.offers, required this.storeId});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text('bogo'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: offers.length,
          separatorBuilder: (context, index) => const Divider(height: Dimensions.paddingSizeExtraLarge),
          itemBuilder: (context, index) => _BogoOfferRowCard(item: offers[index], storeId: storeId),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ]),
    );
  }
}

class _BogoOfferRowCard extends StatelessWidget {
  final StoreBogoOfferModel item;
  final int? storeId;
  const _BogoOfferRowCard({required this.item, required this.storeId});

  void _openBottomSheet(BuildContext context) {
    if (item.bundle.bundleId == null) return;
    BogoOfferDetailsBottomSheet.show(
      context,
      bundle: item.bundle, offerTitle: item.offer.title, offerLabel: item.offer.offerLabel, validUntil: item.offer.validUntil,
      remainingUses: item.offer.remainingUses,
    );
  }

  @override
  Widget build(BuildContext context) {
    // bundle_price is the offer's price; original_price is what the items would cost
    // separately. final_price belongs to the cart bill.
    final double price = item.bundle.bundlePrice ?? 0;
    final double? originalPrice = item.bundle.originalPrice;
    final bool hasDiscount = originalPrice != null && originalPrice > price;
    final double discountPercentage = item.bundle.discountPercentage ?? 0;
    final List<String> thumbnails = (item.bundle.itemThumbnails ?? []).whereType<String>().toList();

    return InkWell(
      onTap: () => _openBottomSheet(context),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (item.offer.offerLabel != null && item.offer.offerLabel!.isNotEmpty)
              Text(item.offer.offerLabel!, style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 2),

            Text(item.offer.title ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: 2,
              children: [
                Text(PriceConverter.convertPrice(price), textDirection: TextDirection.ltr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),

                if (hasDiscount) Text(
                  PriceConverter.convertPrice(originalPrice),
                  textDirection: TextDirection.ltr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            if (discountPercentage > 0) Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(Images.percentTag, height: 12, width: 12, color: Theme.of(context).primaryColor),
                const SizedBox(width: 2),
                Text(
                  '${discountPercentage.toStringAsFixed(discountPercentage % 1 == 0 ? 0 : 1)}% ${'off'.tr}',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                ),
              ]),
            ),

            if (item.offer.validUntil != null) ...[
              const SizedBox(height: 2),
              Text('${'valid_until'.tr} : ${item.offer.validUntil}', style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            ],
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),

        SizedBox(width: 100, height: 100, child: Stack(clipBehavior: Clip.none, children: [
          Container(
            height: 100, width: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
              border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
            ),
            child: _BogoThumbnailGrid(thumbnails: thumbnails),
          ),
          Positioned(right: 5, bottom: 5, child: _BogoStepper(item: item, storeId: storeId)),
        ])),
      ]),
    );
  }
}

/// Fills the tile whatever the bundle holds: two items split it into full height
/// columns, three keep one tall beside a stacked pair, four or more take a 2x2 with
/// the last cell counting what did not fit.
class _BogoThumbnailGrid extends StatelessWidget {
  final List<String> thumbnails;
  const _BogoThumbnailGrid({required this.thumbnails});

  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    if (thumbnails.isEmpty) {
      return const Center(child: CustomAssetImageWidget(Images.bogoOfferIcon, height: 28, width: 28));
    }
    if (thumbnails.length == 1) {
      return _image(thumbnails.first);
    }
    if (thumbnails.length == 2) {
      return Row(children: [
        Expanded(child: _image(thumbnails[0])),
        const SizedBox(width: _gap),
        Expanded(child: _image(thumbnails[1])),
      ]);
    }
    if (thumbnails.length == 3) {
      return Row(children: [
        Expanded(child: _image(thumbnails[0])),
        const SizedBox(width: _gap),
        Expanded(child: Column(children: [
          Expanded(child: _image(thumbnails[1])),
          const SizedBox(height: _gap),
          Expanded(child: _image(thumbnails[2])),
        ])),
      ]);
    }
    final int overflow = thumbnails.length - 4;
    return Column(children: [
      Expanded(child: Row(children: [
        Expanded(child: _image(thumbnails[0])),
        const SizedBox(width: _gap),
        Expanded(child: _image(thumbnails[1])),
      ])),
      const SizedBox(height: _gap),
      Expanded(child: Row(children: [
        Expanded(child: _image(thumbnails[2])),
        const SizedBox(width: _gap),
        Expanded(child: _image(thumbnails[3], overflowCount: overflow > 0 ? overflow : null)),
      ])),
    ]);
  }

  Widget _image(String url, {int? overflowCount}) {
    return Stack(fit: StackFit.expand, children: [
      CustomImage(image: url, fit: BoxFit.cover, placeholder: Images.placeholder),
      if (overflowCount != null)
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
          child: Center(child: Text('+$overflowCount',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
    ]);
  }
}

class _BogoStepper extends StatelessWidget {
  final StoreBogoOfferModel item;
  final int? storeId;
  const _BogoStepper({required this.item, required this.storeId});

  int? get _storeId => item.bundle.store?.id ?? storeId;

  // `remaining_uses` is null when the offer is unlimited for this customer.
  bool _reachedLimit(int quantity) {
    int? limit = item.offer.remainingUses;
    return limit != null && quantity >= limit;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final int? storeId = _storeId;
      final CartModel? cartItem = cartController.findBogoBundleInCart(item.bundle.bundleId, storeId: storeId);
      final int quantity = cartItem?.quantity ?? 0;
      final bool canStep = cartItem != null && storeId != null && !cartController.isLoading;

      if(!canStep) {
        return InkWell(
          onTap: () {
            if(item.bundle.bundleId == null || cartController.isLoading) {
              return;
            }
            cartController.addBogoToCartOnline(item.bundle.bundleId!, 1);
          },
          child: Container(
            height: 32, width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
            child: Icon(Icons.add, size: 18, color: Theme.of(context).cardColor),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          QuantityButton(
            isIncrement: false,
            showRemoveIcon: quantity == 1,
            onTap: () {
              if(quantity > 1) {
                cartController.updateBogoBundleQuantity(false, cartItem!, storeId: storeId!);
              } else {
                cartController.removeBogoBundle(cartItem!, storeId: storeId!);
              }
            },
          ),
          Text('$quantity', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          QuantityButton(
            isIncrement: true,
            onTap: () {
              if(_reachedLimit(quantity)) {
                showCustomSnackBar('you_can_only_use_this_offer_more_times'.trParams({'limit': '${item.offer.remainingUses}'}));
                return;
              }
              cartController.updateBogoBundleQuantity(true, cartItem!, storeId: storeId!);
            },
          ),
        ]),
      );
    });
  }
}

// SUMMARY
// BOGO section of a store page. Lists that store's bundles as rows carrying the offer
// label, title, price, discount and validity beside a thumbnail grid, with a stepper
// that adds, changes or removes the bundle in the cart, and opens the bundle sheet on tap.
