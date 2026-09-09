import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';


class CartWidget extends StatelessWidget {
  final double size;
  final bool fromStore;
  final String? moduleType;
  const CartWidget({super.key, required this.size, this.fromStore = false, this.moduleType});

  @override
  Widget build(BuildContext context) {
    final bool shouldShowCart = moduleType == null || (moduleType != AppConstants.ride && moduleType != AppConstants.taxi && moduleType != AppConstants.parcel);

    if (!shouldShowCart) {
      return const SizedBox();
    }

    return Stack(clipBehavior: Clip.none, children: [

      Image.asset(Images.shoppingCart, height: 22, width: 22, color: Theme.of(context).textTheme.bodyLarge!.color),


      GetBuilder<CartController>(builder: (cartController) {
        return cartController.isLoading
            ? const SizedBox.shrink()
            : cartController.cartList.isNotEmpty ? Positioned(
              top: -5, right: -5,
              child: Container(
                height: size < 20 ? 10 : size/1.5, width: size < 20 ? 10 : size/1.5, alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fromStore ? Theme.of(context).cardColor : Theme.of(context).colorScheme.error,
                  border: Border.all(width: size < 20 ? 0.7 : 1, color: fromStore ? Theme.of(context).primaryColor : Theme.of(context).cardColor),
                ),
                child: Text(
                  cartController.cartList.length.toString(),
                  style: robotoRegular.copyWith(
                    fontSize: size < 20 ? size/3 : size/3.2,
                    color: fromStore ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                  ),
                ),
              ),
            ) : const SizedBox();
      }),
    ]);
  }
}
