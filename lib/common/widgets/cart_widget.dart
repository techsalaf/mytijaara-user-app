import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/service_module/service_cart/controllers/service_cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
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

    // Wrapped in GetBuilder<SplashController> so the branch below is re-evaluated
    // on every module switch. CartWidget is instantiated as `const` at its call
    // sites, so its build() is not re-run on a plain parent rebuild — without this
    // the active-module decision would freeze and the badge would keep reading the
    // previous module's cart controller.
    return GetBuilder<SplashController>(builder: (splashController) {
      // On Home the active module is null; fall back to the last-active (cache)
      // module so the badge keeps showing the cart of the module the user came
      // from — e.g. Home entered from the service module still shows the service count.
      // The service module keeps its carts in its own (addon) controller, so the
      // badge reads that count when the effective module is a service module.
      final effectiveModule = splashController.module ?? splashController.cacheModule;
      final bool isServiceModule = effectiveModule?.moduleType == AppConstants.service;

      return Stack(clipBehavior: Clip.none, children: [

        Image.asset(Images.shoppingCart, height: 22, width: 22, color: Theme.of(context).textTheme.bodyLarge!.color),

        isServiceModule
            ? GetBuilder<ServiceCartController>(builder: (serviceCartController) {
                final int count = serviceCartController.serviceCartItemCount;
                return count > 0 ? _CartCountBadge(count: count, size: size, fromStore: fromStore) : const SizedBox();
              })
            : GetBuilder<CartController>(builder: (cartController) {
                final int itemCount = cartController.allCartsItemCount;
                return cartController.isLoading
                    ? const SizedBox.shrink()
                    : itemCount > 0
                        ? _CartCountBadge(count: itemCount, size: size, fromStore: fromStore)
                        : const SizedBox();
              }),
      ]);
    });
  }
}

class _CartCountBadge extends StatelessWidget {
  final int count;
  final double size;
  final bool fromStore;
  const _CartCountBadge({required this.count, required this.size, required this.fromStore});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -5, right: -5,
      child: Container(
        height: size < 20 ? 10 : size/1.5, width: size < 20 ? 10 : size/1.5, alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fromStore ? Theme.of(context).cardColor : Theme.of(context).colorScheme.error,
          border: Border.all(width: size < 20 ? 0.7 : 1, color: fromStore ? Theme.of(context).primaryColor : Theme.of(context).cardColor),
        ),
        child: Text(
          count.toString(),
          style: robotoRegular.copyWith(
            fontSize: size < 20 ? size/3 : size/3.2,
            color: fromStore ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }
}
