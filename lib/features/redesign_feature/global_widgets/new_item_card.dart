import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/food_item.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/gaps.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../../../util/dimensions.dart';

class NewItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final Item? item;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onTap;
  final double width;

  const NewItemCard({super.key,
    required this.foodItem, this.item, this.onFavouriteTap, this.onAddTap, this.onTap, this.width = 210,
  });

  @override
  Widget build(BuildContext context) {
    if (width.isInfinite) {
      return _HorizontalNewItemCard(
        foodItem: foodItem, item: item,
        onFavouriteTap: onFavouriteTap, onAddTap: onAddTap, onTap: onTap,
      );
    }

    final bool hasDiscount = foodItem.hasDiscount;

    return GestureDetector(onTap: onTap,
      child: Container(width: width,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
          _FoodItemImageSection(foodItem: foodItem, item: item, onFavouriteTap: onFavouriteTap, onAddTap: onAddTap),
          Padding(padding: const EdgeInsets.only(right: 10, top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall, left: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
              _RestaurantInfoRow(foodItem: foodItem),
              const SizedBox(height: 4),
              Text(foodItem.itemName, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: 2),
              _PriceRow(foodItem: foodItem),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
                if (hasDiscount)
                  _DiscountBadge(
                    discountPercent: foodItem.discountPercent!,
                  ),
                if (foodItem.isFreeDelivery) const _FreeDeliveryBadge(),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HorizontalNewItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final Item? item;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onTap;

  const _HorizontalNewItemCard({required this.foodItem, this.item, this.onFavouriteTap, this.onAddTap, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = foodItem.hasDiscount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusMedium)),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
              _RestaurantInfoRow(foodItem: foodItem),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(foodItem.itemName, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  Text(" ${foodItem.rating.toStringAsFixed(1)} (${0} ${"reviews".tr})",
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _PriceRow(foodItem: foodItem),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
                if (hasDiscount) _DiscountBadge(discountPercent: foodItem.discountPercent!),
                if (foodItem.isFreeDelivery) const _FreeDeliveryBadge(),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(children: <Widget>[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImage(image: foodItem.imageUrl, fit: BoxFit.cover, placeholder: Images.placeholder),
                ),
              ),
              Positioned(top: 6, left: 6,
                child: Row(children: <Widget>[
                  if (foodItem.isHalal) const _ImageBadge(assetPath: Images.halalTag),
                  if (foodItem.isHalal && foodItem.isVeg) const SizedBox(width: Dimensions.paddingSizeSmall),
                  if (foodItem.isVeg) const _ImageBadge(assetPath: Images.vegLogo),
                ]),
              ),
              Positioned(top: 6, right: 6,
                child: item != null
                  ? _ItemFavouriteButton(item: item!, containerSize: 28, iconSize: 16)
                  : GestureDetector(
                      onTap: onFavouriteTap,
                      child: Container(width: 28, height: 28,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: Icon(foodItem.isFavourited ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFFE53935), size: 16),
                      ),
                    ),
              ),
              Positioned(right: 6, bottom: 6,
                child: GestureDetector(
                  onTap: () {
                    if (AuthHelper.isLoggedIn()) {
                      onAddTap?.call();
                    } else {
                      showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
                    }
                  },
                  child: Container(width: 34, height: 34,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                      boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.black),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FoodItemImageSection extends StatelessWidget {
  final FoodItem foodItem;
  final Item? item;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onAddTap;

  const _FoodItemImageSection({required this.foodItem, this.item, this.onFavouriteTap, this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 1,
      child: Stack(children: <Widget>[
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CustomImage(image: foodItem.imageUrl, fit: BoxFit.cover, placeholder: Images.placeholder),
          ),
        ),
        Positioned(top: 10, left: 10,
          child: Row(children: <Widget>[
            if (foodItem.isHalal) const _ImageBadge(assetPath: Images.halalTag),
            if (foodItem.isHalal && foodItem.isVeg) Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
            if (foodItem.isVeg) const _ImageBadge(assetPath: Images.vegLogo),
          ]),
        ),
        Positioned(top: 10, right: 10,
          child: item != null
            ? _ItemFavouriteButton(item: item!, containerSize: 36, iconSize: 22)
            : GestureDetector(
                onTap: onFavouriteTap,
                child: Container(width: 36, height: 36,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Icon(foodItem.isFavourited ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFE53935), size: 22),
                ),
              ),
        ),
        Positioned(right: 10, bottom: 10,
          child: GestureDetector(
            onTap: () {
              if (AuthHelper.isLoggedIn()) {
                onAddTap?.call();
              } else {
                showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
              }
            },
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.add, size: 20, color: Colors.black),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ItemFavouriteButton extends StatefulWidget {
  final Item item;
  final double containerSize;
  final double iconSize;

  const _ItemFavouriteButton({required this.item, required this.containerSize, required this.iconSize});

  @override
  _ItemFavouriteButtonState createState() => _ItemFavouriteButtonState();
}

class _ItemFavouriteButtonState extends State<_ItemFavouriteButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FavouriteController>(builder: (favController) {
      final bool isWished = favController.wishItemIdList.contains(widget.item.id);
      return GestureDetector(
        onTap: favController.isRemoving ? null : () {
          if (AuthHelper.isLoggedIn()) {
            if (isWished) {
              favController.removeFromFavouriteList(widget.item.id, false);
            } else {
              favController.addToFavouriteList(widget.item, null, false);
            }
            _animController.reverse().then((_) => _animController.forward());
          } else {
            showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
          }
        },
        child: Container(
          width: widget.containerSize, height: widget.containerSize,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
            boxShadow: <BoxShadow>[BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
            child: Icon(isWished ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFE53935), size: widget.iconSize),
          ),
        ),
      );
    });
  }
}

class _RestaurantInfoRow extends StatelessWidget {
  final FoodItem foodItem;

  const _RestaurantInfoRow({required this.foodItem});

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      _RestaurantLogo(logoUrl: foodItem.restaurantLogoUrl),
      if (foodItem.restaurantLogoUrl.isNotEmpty) const SizedBox(width: Dimensions.paddingSizeSmall),
      Text(foodItem.restaurantName, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
      ),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      const Icon(Icons.star, color: Colors.amber, size: 14),
      Text(foodItem.rating.toStringAsFixed(1),
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
      ),
    ]);
  }
}

class _RestaurantLogo extends StatelessWidget {
  final String logoUrl;

  const _RestaurantLogo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return  ClipOval(
      child: logoUrl.isEmpty ? Container(color: const Color(0xFFF44336))
        : CustomImage(image: logoUrl, fit: BoxFit.cover, placeholder: Images.placeholder, height: 24, width: 24),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final FoodItem foodItem;

  const _PriceRow({required this.foodItem});

  String _formatPrice(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!foodItem.hasDiscount) {
      return Text(
        _formatPrice(foodItem.price),
        style: robotoBold.copyWith(fontSize: 16, color: const Color(0xFF1F1F1F)),
      );
    }

    return Row(children: <Widget>[
      Text(
        _formatPrice(foodItem.price),
        style: robotoBold.copyWith(fontSize: 16, color: const Color(0xFF1F1F1F)),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          _formatPrice(foodItem.originalPrice!), maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(fontSize: 13, color: const Color(0xFF8D8D8D), decoration: TextDecoration.lineThrough),
        ),
      ),
    ]);
  }
}

class _DiscountBadge extends StatelessWidget {
  final double discountPercent;

  const _DiscountBadge({required this.discountPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(99)),
      child: Text(
        '-${discountPercent.toStringAsFixed(discountPercent % 1 == 0 ? 0 : 1)}%',
        style: robotoSemiBold.copyWith(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

class _FreeDeliveryBadge extends StatelessWidget {
  const _FreeDeliveryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Icon(Icons.directions_bike, size: 14, color: Color(0xFFE53935)),
        const SizedBox(width: 4),
        Text('Free',
          style: robotoMedium.copyWith(fontSize: 12, color: const Color(0xFFE53935)),
        ),
      ]),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String assetPath;

  const _ImageBadge({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(width: 28, height: 28,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),],
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: CustomAssetImageWidget(assetPath, height: 24, width: 24, fit: BoxFit.contain),
      ),
    );
  }
}
