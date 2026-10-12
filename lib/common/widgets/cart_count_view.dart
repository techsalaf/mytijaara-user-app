import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_quantity_button.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

/// [CartQuantityButton] wired to a single product's cart row.
class CartCountView extends StatelessWidget {
  final Item item;
  final Widget? child;
  final int? index;
  final VoidCallback? onBeforeAdd;
  final int? availableStock;
  const CartCountView({super.key, required this.item, this.child, this.index = -1, this.onBeforeAdd, this.availableStock});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final int cartQty = cartController.cartQuantity(item.id!);
      final int cartIndex = cartController.isExistInCart(item.id, cartController.cartVariant(item.id!), false, null);

      return CartQuantityButton(
        quantity: cartQty,
        isLoading: cartController.isLoading && cartController.directAddCartItemIndex == index,
        onBeforeAdd: onBeforeAdd,
        addBuilder: child == null ? null : (_, _) => child!,
        onAdd: () => Get.find<ItemController>().itemDirectlyAddToCart(item, context, availableStock: availableStock),
        onIncrement: cartIndex < 0 ? null : () async {
          cartController.setDirectlyAddToCartIndex(index);
          cartController.changeQuantity(true, cartIndex, cartController.cartList[cartIndex].stock, cartController.cartList[cartIndex].quantityLimit);
        },
        onDecrement: cartIndex < 0 ? null : () async {
          if(cartController.cartList[cartIndex].quantity! > 1) {
            cartController.setDirectlyAddToCartIndex(index);
            cartController.changeQuantity(false, cartIndex, cartController.cartList[cartIndex].stock, cartController.cartList[cartIndex].item!.quantityLimit);
          } else {
            await cartController.removeFromCart(cartIndex);
          }
        },
      );
    });
  }
}

// SUMMARY
// Cart stepper for one product. Shows the add button until the item is in the cart,
// then its quantity with increment and remove, and refuses to add past the stock cap
// it is given.
