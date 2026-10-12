import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/bundle_thumbnail_avatars.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_details_bottom_sheet.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BundleCartTile extends StatelessWidget {
  final CartModel cart;
  final int cartIndex;
  final bool isAvailable;
  final bool isStoreOpen;
  final VoidCallback? onChanged;

  const BundleCartTile({super.key,
    required this.cart, required this.cartIndex, this.isAvailable = true, this.isStoreOpen = true, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final BundleCartDetails? details = cart.bundleDetails;
    if(details == null) {
      return const SizedBox();
    }

    final ThemeData theme = Theme.of(context);

    return GetBuilder<CartController>(builder: (cartController) {
      return Stack(children: [

        Slidable(
          key: ValueKey('cart_bundle_${details.bundleGroupId}_$cartIndex'),
          enabled: !cartController.isLoading,
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (context) => cartController.removeBundle(cart).then((_) => onChanged?.call()),
                backgroundColor: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                foregroundColor: Colors.white,
                icon: CupertinoIcons.trash,
              ),
            ],
          ),
          child: CustomInkWell(
            onTap: () => BundleDetailsBottomSheet.show(context, bundleId: details.bundleId, storeId: cart.storeId),
            radius: Dimensions.radiusDefault,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

                  BundleThumbnailAvatars(
                    thumbnails: details.itemThumbnails,
                    totalCount: details.items.length,
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    decoration: BoxDecoration(
                      color: theme.disabledColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      QuantityButton(
                        isIncrement: false,
                        flat: true,
                        showRemoveIcon: cart.quantity == 1,
                        onTap: cartController.isLoading ? null : () {
                          if((cart.quantity ?? 1) > 1) {
                            cartController.updateBundleQuantity(false, cart).then((_) => onChanged?.call());
                          } else {
                            cartController.removeBundle(cart).then((_) => onChanged?.call());
                          }
                        },
                      ),
                      Text('${cart.quantity}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      QuantityButton(
                        isIncrement: true,
                        flat: true,
                        onTap: cartController.isLoading ? null : () => cartController.updateBundleQuantity(true, cart).then((_) => onChanged?.call()),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Text(
                    details.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),
                const SizedBox(height: 2),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Row(children: [
                    Text(
                      PriceConverter.convertPrice(details.totalFinalPrice),
                      textDirection: TextDirection.ltr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  
                    if(details.hasSaving)
                      Flexible(child: Text(
                        PriceConverter.convertPrice(details.totalBasePrice),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault, color: theme.hintColor,
                          decoration: TextDecoration.lineThrough, decorationColor: theme.hintColor,
                        ),
                      )),
                  ]),
                ),

                if(!isAvailable && (details.unavailableReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                    child: Text(
                      details.unavailableReason!,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),

        if(!isStoreOpen) Positioned.fill(child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: theme.disabledColor.withValues(alpha: 0.2),
          ),
        )),
      ]);
    });
  }
}
