import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_quantity_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_details_bottom_sheet.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_thumbnail_grid_widget.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BundleCardWidget extends StatelessWidget {
  final Bundle bundle;
  final double width;

  const BundleCardWidget({super.key, required this.bundle, this.width = 168});

  static const double _storeLineHeight = 20;
  static const double _titleLineHeight = 20;
  static const int _titleLines = 2;
  static const double _priceLineHeight = 26;
  static const double _badgeLineHeight = 24;
  static const double _storeLogoSize = 18;

  /// The exact height a card of [width] needs, text scaling included — the strip
  /// sizes itself from this rather than from a guessed constant.
  static double heightOf(BuildContext context, {double width = 168}) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double textBlock = scaler.scale(_storeLineHeight)
        + scaler.scale(_titleLineHeight) * _titleLines
        + scaler.scale(_priceLineHeight)
        + scaler.scale(_badgeLineHeight);
    return width + Dimensions.paddingSizeSmall + textBlock + (Dimensions.paddingSizeExtraSmall * 3);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);

    /// TODO: the list endpoints send `items: null` (§4), so a card has no member
    /// pictures to draw and falls back to the bundle's own thumbnail. Either
    /// have `/bundle/home`, `/bundle/list` and `/bundle/store-bundles` include a
    /// thumbnail array, or accept the single-image card — the grid already
    /// renders whichever it is given, laid out by `item_count`.
    final List<String> thumbnails = bundle.items != null
        ? bundle.itemThumbnails
        : <String>[if((bundle.imageFullUrl ?? '').isNotEmpty) bundle.imageFullUrl!];

    return InkWell(
      onTap: () => BundleDetailsBottomSheet.show(context, bundleId: bundle.id, storeId: bundle.storeId),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: SizedBox(
        width: width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

          BundleThumbnailGridWidget(
            thumbnails: thumbnails,
            totalCount: bundle.memberCount,
            size: width,
            action: BundleAddButton(bundle: bundle, size: width * 0.24),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: scaler.scale(_storeLineHeight),
            child: Row(children: [
              /// TODO: the browse payload carries `store_name` but no store
              /// logo (§4), so the mark only appears if a URL ever arrives.
              /// Ask for `store_logo_full_url` on the bundle payload to match
              /// the design.
              if((bundle.storeLogoFullUrl ?? '').isNotEmpty) ...[
                ClipOval(child: CustomImage(
                  image: bundle.storeLogoFullUrl!,
                  height: _storeLogoSize, width: _storeLogoSize, fit: BoxFit.fill,
                )),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              ],

              Expanded(child: Text(
                bundle.storeName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.hintColor),
              )),
            ]),
          ),

          Text(
            bundle.name ?? '', maxLines: _titleLines, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, height: 1.25),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          SizedBox(
            height: scaler.scale(_priceLineHeight),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                PriceConverter.convertPrice(bundle.finalPrice),
                textDirection: TextDirection.ltr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              if(bundle.hasSaving)
                Flexible(child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    PriceConverter.convertPrice(bundle.basePrice),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault, color: theme.hintColor,
                      decoration: TextDecoration.lineThrough, decorationColor: theme.hintColor,
                    ),
                  ),
                )),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          SizedBox(
            height: scaler.scale(_badgeLineHeight),
            child: bundle.discountPercentage > 0
                ? Align(alignment: Alignment.centerLeft, child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    ),
                    child: Text(
                      bundle.discountLabel,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
                    ),
                  ))
                : const SizedBox(),
          ),

        ]),
      ),
    );
  }
}

/// [CartQuantityButton] wired to a bundle's cart group. Every step counts whole
/// copies of the bundle; the last `-` removes the group.
class BundleAddButton extends StatelessWidget {
  final Bundle bundle;
  final double size;
  const BundleAddButton({super.key, required this.bundle, required this.size});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final CartModel? existing = cartController.findBundleInCart(bundle.id, storeId: bundle.storeId);
      final int cartQty = existing?.quantity ?? 0;
      // One cart request at a time: the bundle endpoints refuse while another runs.
      final bool locked = cartController.isLoading;

      return CartQuantityButton(
        quantity: cartQty,
        addBuilder: _buildAdd,
        onAdd: !bundle.isAvailable || bundle.id == null || locked
            ? null : () => cartController.addBundleToCart(bundle.id!, 1),
        onIncrement: existing == null || locked
            ? null : () => cartController.setBundleQuantity(existing, cartQty + 1),
        onDecrement: existing == null || locked ? null : () async {
          if(cartQty > 1) {
            await cartController.setBundleQuantity(existing, cartQty - 1);
          } else {
            await cartController.removeBundle(existing);
          }
        },
      );
    });
  }

  Widget _buildAdd(BuildContext context, bool isAdding) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
      ),
      alignment: Alignment.center,
      child: isAdding
          ? SizedBox(height: size * 0.45, width: size * 0.45, child: const CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.add, size: size * 0.5, color: theme.textTheme.bodyLarge?.color),
    );
  }
}
