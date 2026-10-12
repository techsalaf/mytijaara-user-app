import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/screens/cart_screen.dart';
import 'package:sixam_mart/features/cart/screens/global_cart_screen.dart';

class BottomAddToCartWidget extends StatelessWidget {
  final int? storeId;
  const BottomAddToCartWidget({super.key, this.storeId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final bool isStoreSpecific = storeId != null;
      final AllCartsModel? existingGroup = isStoreSpecific ? cartController.getCartsForStore(storeId!) : null;

      // localCartsOfGroup folds a bundle into one row; group.carts and store.itemCount
      // both come from get-all, which still counts every member separately.
      final int itemCount = (isStoreSpecific && existingGroup != null)
          ? cartController.localCartsOfGroup(existingGroup).length
          : cartController.cartList.length;

      return Center(
        child: SizedBox(
          height: GetPlatform.isIOS ? 100 : 70, width: Get.width,
          child: CustomButton(
            buttonText: '${'view_cart'.tr} ${'items'.tr} ($itemCount)', width: 200, height: 45, radius: 100,
            onPressed: () {
              if (isStoreSpecific) {
                CartScreen.openAsBottomSheet(context, storeId: storeId!);
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
