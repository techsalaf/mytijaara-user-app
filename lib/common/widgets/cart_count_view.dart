import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/common/widgets/quantity_decrement_icon.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';


class CartCountView extends StatefulWidget {
  final Item item;
  final Widget? child;
  final int? index;
  const CartCountView({super.key, required this.item, this.child, this.index = -1});

  @override
  State<CartCountView> createState() => _CartCountViewState();
}

class _CartCountViewState extends State<CartCountView> {
  // The expanded [- count +] view auto-collapses to the count chip after this idle delay.
  static const Duration _autoCollapseDelay = Duration(seconds: 3);

  // Shared height for the in-cart states (chip & [- count +]) so switching between
  // them never shifts the control vertically.
  static const double _controlHeight = 32;

  bool _isExpanded = false;
  bool _isAdding = false;
  Timer? _collapseTimer;

  // Show the [- count +] view and (re)start the idle timer that collapses it
  // back to the count chip. Called on add / +/- taps / tapping the count chip.
  void _keepExpanded() {
    _collapseTimer?.cancel();
    if(!_isExpanded) {
      setState(() => _isExpanded = true);
    }
    _collapseTimer = Timer(_autoCollapseDelay, () {
      if(mounted) {
        setState(() => _isExpanded = false);
      }
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final int cartQty = cartController.cartQuantity(widget.item.id!);
      final int cartIndex = cartController.isExistInCart(widget.item.id, cartController.cartVariant(widget.item.id!), false, null);

      // Note: _isExpanded is only consulted when cartQty > 0, so the qty-0 ("+")
      // render ignores it — no need to reset it here (resetting during the brief
      // post-tap window before the async add lands would skip the expanded view).
      final String stateKey = cartQty == 0 ? 'add' : (_isExpanded ? 'expanded' : 'chip');
      final Widget content = cartQty == 0
          ? _buildAddButton(context)
          : _isExpanded
              ? _buildExpanded(context, cartController, cartQty, cartIndex)
              : _buildCountChip(context, cartController, cartQty);

      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerRight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
          // Anchor both the outgoing and incoming child to the right so the control
          // grows/shrinks from a fixed right edge instead of drifting horizontally.
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) => Stack(
            alignment: Alignment.centerRight,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
          child: KeyedSubtree(
            key: ValueKey<String>('cart-count-$stateKey'),
            child: content,
          ),
        ),
      );
    });
  }

  // State A — only the "+" button (item not in cart).
  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: _isAdding ? null : () async {
        if(AddressHelper.getUserAddressFromSharedPref() == null) {
          Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
          return;
        }
        _keepExpanded();
        setState(() => _isAdding = true);
        await Get.find<ItemController>().itemDirectlyAddToCart(widget.item, context);
        if (mounted) setState(() => _isAdding = false);
      },
      child: widget.child ?? Container(
        height: 25, width: 25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          color: Theme.of(context).cardColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: _isAdding
            ? const Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.add, size: 20, color: Theme.of(context).primaryColor),
      ),
    );
  }

  // State C — compact chip showing just the count; tapping expands to [- count +].
  Widget _buildCountChip(BuildContext context, CartController cartController, int cartQty) {
    final bool loading = cartController.isLoading && cartController.directAddCartItemIndex == widget.index;
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: cartController.isLoading ? null : _keepExpanded,
      child: Container(
        height: _controlHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall+2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 0)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : _animatedCount(cartQty, robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
      ),
    );
  }

  // State B — full [- count +] control.
  Widget _buildExpanded(BuildContext context, CartController cartController, int cartQty, int cartIndex) {
    return Container(
      height: _controlHeight,
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        InkWell(
          onTap: cartController.isLoading ? null : () {
            if (cartController.cartList[cartIndex].quantity! > 1) {
              _keepExpanded();
              cartController.setDirectlyAddToCartIndex(widget.index);
              cartController.setQuantity(false, cartIndex, cartController.cartList[cartIndex].stock, cartController.cartList[cartIndex].item!.quantityLimit);
            }else {
              // Last one removed → returns to the "+" button; no need to stay expanded.
              _collapseTimer?.cancel();
              cartController.removeFromCart(cartIndex);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: QuantityDecrementIcon(quantity: cartQty, size: 16),
          ),
        ),

        // Keep the number visible and roll it on +/- (no spinner swap) so the
        // control never blinks during quantity changes.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: _animatedCount(cartQty, robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),

        InkWell(
          onTap: cartController.isLoading ? null : () {
            _keepExpanded();
            cartController.setDirectlyAddToCartIndex(widget.index);
            cartController.setQuantity(true, cartIndex, cartController.cartList[cartIndex].stock, cartController.cartList[cartIndex].quantityLimit);
          },
          child: const Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(Icons.add, size: 16),
          ),
        ),
      ]),
    );
  }

  // Smoothly rolls the count from the old value to the new one (slide + fade),
  // keyed on the value so each +/- change animates instead of snapping.
  Widget _animatedCount(int qty, TextStyle style) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) => ClipRect(
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
      ),
      child: Text(qty.toString(), key: ValueKey<int>(qty), style: style),
    );
  }
}
