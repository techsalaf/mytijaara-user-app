import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/screens/cart_screen.dart';
import 'package:sixam_mart/features/cart/screens/global_cart_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BottomAddToCartWidget extends StatelessWidget {
  final int? storeId;
  const BottomAddToCartWidget({super.key, this.storeId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final bool isStoreSpecific = storeId != null;
      final AllCartsModel? existingGroup = isStoreSpecific ? cartController.getCartsForStore(storeId!) : null;

      final int itemCount = (isStoreSpecific && existingGroup != null)
          ? (existingGroup.carts?.length ?? existingGroup.store?.itemCount ?? 0)
          : cartController.cartList.length;

      final double total = (isStoreSpecific && existingGroup != null)
          ? (existingGroup.carts?.fold<double>(0.0, (double sum, c) => sum + ((c.discountedPrice ?? c.price ?? 0) * (c.quantity ?? 1))) ?? 0.0)
          : cartController.calculationCart();

      return Center(
        child: SizedBox(
          height: GetPlatform.isIOS ? 100 : 70, width: Get.width,
          child: CustomButton(
            buttonText: '${'view_cart'.tr} ${'items'.tr} ($itemCount)', width: 200, height: 45, radius: 100,
            onPressed: () {
              if (isStoreSpecific) {

                Get.to(() => CartScreen(fromNav: false, storeId: storeId));
              } else {
                Get.to(() => const GlobalCartScreen(fromNav: false));
              }
            },
          ),
        ),
      );
    });
  }
}
