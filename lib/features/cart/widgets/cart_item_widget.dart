import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/common/widgets/item_new_bottom_sheet.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

void _confirmRemoveCartItem({required int cartIndex, required Item? item}) {
  Get.dialog(ConfirmationDialog(
    icon: Images.warning,
    description: 'are_you_sure_to_remove_this_item'.tr,
    onYesPressed: () {
      Get.back();
      Get.find<CartController>().removeFromCart(cartIndex, item: item);
    },
  ));
}

class CartItemWidget extends StatefulWidget {
  final CartModel cart;
  final int cartIndex;
  final List<AddOns> addOns;
  final bool isAvailable;
  final bool showDivider;
  const CartItemWidget({super.key, required this.cart, required this.cartIndex, required this.isAvailable, required this.addOns, required this.showDivider});

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {

  bool showAddonsVariations = false;

  @override
  Widget build(BuildContext context) {

    double? startingPrice = _calculatePrice(item: widget.cart.item);
    double? endingPrice = _calculatePrice(item: widget.cart.item, isStartingPrice: false);
    String? variationText = _setupVariationText(cart: widget.cart).$1;
    String addOnText = _setupAddonsText(cart: widget.cart) ?? '';


    double? discount = widget.cart.item!.discount;
    String? discountType = widget.cart.item!.discountType;
    String genericName = '';

    if(widget.cart.item!.genericName != null && widget.cart.item!.genericName!.isNotEmpty) {
      for (String name in widget.cart.item!.genericName!) {
        genericName += name;
      }
    }

    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Slidable(
        key: ValueKey('${widget.cart.id}_${widget.cart.item?.id}'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) {
                _confirmRemoveCartItem(cartIndex: widget.cartIndex, item: widget.cart.item);
              },
              backgroundColor: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(Get.find<LocalizationController>().isLtr ? Dimensions.radiusDefault : 0),
                left: Radius.circular(Get.find<LocalizationController>().isLtr ? 0 : Dimensions.radiusDefault),
              ),
              foregroundColor: Colors.white,
              icon: CupertinoIcons.delete,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: showAddonsVariations
                ? Theme.of(context).disabledColor.withValues(alpha: 0.05)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: CustomInkWell(
            onTap: () {
              ResponsiveHelper.isMobile(context)
                  ? showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (con) => ItemNewBottomSheet(itemId: widget.cart.item!.id!, cartIndex: widget.cartIndex, cart: widget.cart),
                    )
                  : showDialog(
                      context: context,
                      builder: (con) => Dialog(
                        child: ItemNewBottomSheet(itemId: widget.cart.item!.id!, cartIndex: widget.cartIndex, cart: widget.cart),
                      ),
                    );
            },
            radius: Dimensions.radiusDefault,
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeExtraSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (isDesktop) const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Product image
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: CustomImage(
                        image: '${widget.cart.item!.imageFullUrl}',
                        height: 44, width: 44, fit: BoxFit.cover,
                      ),
                    ),
                    if (!widget.isAvailable)
                      Positioned(
                        top: 0, left: 0, bottom: 0, right: 0,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                          child: Text(
                            'not_available_now_break'.tr,
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(color: Colors.white, fontSize: 8),
                          ),
                        ),
                      ),
                  ]),

                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  // Text content + quantity pill
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // Name row + quantity pill
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Expanded(
                                child: Text(
                                  widget.cart.item!.name!,
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                              // Unit/veg badge
                              ((Get.find<SplashController>().configModel!.moduleConfig!.module!.unit!
                                      && widget.cart.item!.unitType != null
                                      && !Get.find<SplashController>().getModuleConfig(widget.cart.item!.moduleType).newVariation!)
                                  || (Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg!
                                      && Get.find<SplashController>().configModel!.toggleVegNonVeg!))
                                  ? !Get.find<SplashController>().configModel!.moduleConfig!.module!.unit!
                                      ? CustomAssetImageWidget(
                                          widget.cart.item!.veg == 0 ? Images.nonVegImage : Images.vegImage,
                                          height: 11, width: 11,
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: Dimensions.paddingSizeExtraSmall),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          ),
                                          child: Text(
                                            widget.cart.item!.unitType ?? '',
                                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeOverSmall, color: Theme.of(context).primaryColor),
                                          ),
                                        )
                                  : const SizedBox(),

                              // Halal tag
                              if (widget.cart.item!.isStoreHalalActive! && widget.cart.item!.isHalalItem!) ...[
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                const CustomAssetImageWidget(Images.halalTag, height: 13, width: 13),
                              ],
                            ]),

                            // Generic name
                            if (genericName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  genericName,
                                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                              Text(
                                '${PriceConverter.convertPrice(startingPrice, discount: discount, discountType: discountType)}'
                                    '${endingPrice != null ? ' - ${PriceConverter.convertPrice(endingPrice, discount: discount, discountType: discountType)}' : ''}',
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                textDirection: TextDirection.ltr,
                              ),
                              if (discount! > 0) ...[
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                Text(
                                  '${PriceConverter.convertPrice(startingPrice)}'
                                      '${endingPrice != null ? ' - ${PriceConverter.convertPrice(endingPrice)}' : ''}',
                                  textDirection: TextDirection.ltr,
                                  style: robotoRegular.copyWith(
                                    color: Theme.of(context).disabledColor,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                              ],
                            ]),
                          ]),
                        ),

                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        // Quantity pill
                        GetBuilder<CartController>(
                          builder: (cartController) => _CartItemQuantityPill(
                            cart: widget.cart,
                            cartIndex: widget.cartIndex,
                            isLoading: cartController.isLoading,
                          ),
                        ),
                      ]),


                      // Price row
                      

                      // Prescription note
                      if (widget.cart.item!.isPrescriptionRequired!)
                        Padding(
                          padding: EdgeInsets.only(top: isDesktop ? Dimensions.paddingSizeExtraSmall : 2),
                          child: Text(
                            '* ${'prescription_required'.tr}',
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).colorScheme.error),
                          ),
                        ),

                    ]),
                  ),
                ]),

                // Variation / addon toggle row — full width, starts from card edge
                if (addOnText.isNotEmpty || variationText!.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => showAddonsVariations = !showAddonsVariations),
                    child: Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                      child: Row(children: [
                        if (!showAddonsVariations)
                          Expanded(
                            child: Text(
                              _buildToggleText(variationText, addOnText),
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else const Spacer(),
                        // Show button if: both addons AND variations exist, OR if either is substantial
                        if ((addOnText.isNotEmpty && variationText!.isNotEmpty) || addOnText.length > 40 || variationText!.length > 40) ...[
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                            child: Icon(
                              showAddonsVariations ? Icons.keyboard_arrow_up_outlined : Icons.keyboard_arrow_down_outlined,
                              size: 18,
                              color: showAddonsVariations ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),

                // Expanded addon/variation details — animated
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: showAddonsVariations
                      ? Padding(
                          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                          child: Column(children: [
                            if (addOnText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${'addons'.tr}: ', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                  Flexible(child: Text(addOnText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
                                ]),
                              ),
                            if (variationText!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${'variations'.tr}: ', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                  Flexible(child: Text(variationText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
                                ]),
                              ),
                          ]),
                        )
                      : const SizedBox(),
                ),

                if (widget.showDivider && !isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: Divider(height: 1, thickness: 0.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildToggleText(String? variationText, String addOnText) {
    final List<String> parts = [];
    if (variationText != null && variationText.isNotEmpty) parts.add(variationText);
    if (addOnText.isNotEmpty) parts.add('${'addons'.tr}: $addOnText');
    return parts.join(' ; ');
  }

  double? _calculatePrice({required Item? item, bool isStartingPrice = true}) {
    double? startingPrice;
    double? endingPrice;
    bool newVariation = Get.find<SplashController>().getModuleConfig(item!.moduleType).newVariation ?? false;

    if(item.variations!.isNotEmpty && !newVariation) {
      List<double?> priceList = [];
      for (var variation in item.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if(priceList[0]! < priceList[priceList.length-1]!) {
        endingPrice = priceList[priceList.length-1];
      }
    }else {
      startingPrice = item.price;
    }
    if(isStartingPrice) {
      return startingPrice;
    } else {
      return endingPrice;
    }
  }

  (String?, int) _setupVariationText({required CartModel cart}) {
    String? variationText = '';
    int count = 0;

    if(Get.find<SplashController>().getModuleConfig(cart.item!.moduleType).newVariation!) {
      if(cart.foodVariations!.isNotEmpty) {
        for(int index=0; index<cart.foodVariations!.length; index++) {
          if(cart.foodVariations![index].contains(true)) {
            variationText = '${variationText!}${variationText.isNotEmpty ? ', ' : ''}${cart.item!.foodVariations![index].name} (';
            for(int i=0; i<cart.foodVariations![index].length; i++) {
              if(cart.foodVariations![index][i]!) {
                variationText = '${variationText!}${variationText.endsWith('(') ? '' : ', '}${cart.item!.foodVariations![index].variationValues![i].level}';
                count++;
              }
            }
            variationText = '${variationText!})';
          }
        }
      }
    }else {
      if(cart.variation!.isNotEmpty) {
        List<String> variationTypes = cart.variation![0].type!.split('-');
        if(variationTypes.length == cart.item!.choiceOptions!.length) {
          int index0 = 0;
          for (var choice in cart.item!.choiceOptions!) {
            variationText = '${variationText!}${(index0 == 0) ? '' : ',  '}${choice.title} - ${variationTypes[index0]}';
            index0 = index0 + 1;
            count++;
          }
        }else {
          variationText = cart.item!.variations![0].type;
        }
      }
    }
    return (variationText, count);
  }

  String? _setupAddonsText({required CartModel cart}) {
    String addOnText = '';
    int index0 = 0;
    List<int?> ids = [];
    List<int?> qtys = [];
    for (var addOn in cart.addOnIds!) {
      ids.add(addOn.id);
      qtys.add(addOn.quantity);
    }
    for (var addOn in cart.item!.addOns!) {
      if (ids.contains(addOn.id)) {
        addOnText = '$addOnText${(index0 == 0) ? '' : ',  '}${addOn.name} (${qtys[index0]})';
        index0 = index0 + 1;
      }
    }
    return addOnText;
  }
}

class _CartItemQuantityPill extends StatelessWidget {
  final CartModel cart;
  final int cartIndex;
  final bool isLoading;
  const _CartItemQuantityPill({required this.cart, required this.cartIndex, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final Color disabledColor = Theme.of(context).disabledColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Container(
      decoration: BoxDecoration(
        color: disabledColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [

        // Decrease / delete
        InkWell(
          onTap: isLoading ? null : () {
            if (cart.quantity! > 1) {
              Get.find<CartController>().setQuantity(false, cartIndex, cart.stock, cart.quantityLimit);
            } else {
              _confirmRemoveCartItem(cartIndex: cartIndex, item: cart.item);
            }
          },
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusSmall),
            bottomLeft: Radius.circular(Dimensions.radiusSmall),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
            child: cart.quantity! == 1 ? Image.asset(Images.delete, width: 16, height: 16, 
            color: Theme.of(context).textTheme.bodyLarge?.color): Icon(Icons.remove_rounded,
              size: 16, color: isLoading ? disabledColor : textColor,
            ),
          ),
        ),

        // Quantity number+
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: Text(
            cart.quantity.toString(),
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
        ),

        // Increase
        InkWell(
          onTap: isLoading ? null : () {
            Get.find<CartController>().forcefullySetModule(Get.find<CartController>().cartList[0].item!.moduleId!);
            Get.find<CartController>().setQuantity(true, cartIndex, cart.stock, cart.quantityLimit);
          },
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(Dimensions.radiusSmall),
            bottomRight: Radius.circular(Dimensions.radiusSmall),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: isLoading ? disabledColor : textColor,
            ),
          ),
        ),

      ]),
    );
  }
}
