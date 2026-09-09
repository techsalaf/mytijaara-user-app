import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';



// void showCartSnackBar() {
//   ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
//     dismissDirection: DismissDirection.horizontal,
//     margin: EdgeInsets.only(
//       right: ResponsiveHelper.isDesktop(Get.context) ? Get.context!.width*0.7 : Dimensions.paddingSizeSmall,
//       top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
//     ),
//     duration: const Duration(seconds: 3),
//     backgroundColor: Colors.green,
//     behavior: SnackBarBehavior.floating,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
//     content: Text('item_added_to_cart'.tr, style: robotoMedium.copyWith(color: Colors.white)),
//     action: SnackBarAction(label: 'view_cart'.tr, onPressed: () => Get.toNamed(RouteHelper.getCartRoute()), textColor: Colors.white),
//   ));
//
//   Future.delayed(const Duration(seconds: 3), () {
//     ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
//   });
// }


void showCartSnackBar() {
  if (Get.isSnackbarOpen) {
    Get.closeAllSnackbars();
  }

  Get.showSnackbar(GetSnackBar(
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFF039D55),
    borderRadius: Dimensions.radiusDefault,
    margin: EdgeInsets.fromLTRB(
      Dimensions.paddingSizeDefault,
      Dimensions.paddingSizeSmall,
      ResponsiveHelper.isDesktop(Get.context) ? Get.context!.width * 0.7 : Dimensions.paddingSizeDefault,
      Dimensions.paddingSizeDefault,
    ),
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
    duration: const Duration(seconds: 3),
    animationDuration: const Duration(milliseconds: 350),
    forwardAnimationCurve: Curves.easeOutCirc,
    reverseAnimationCurve: Curves.easeInCirc,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    boxShadows: <BoxShadow>[
      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
    ],
    messageText: Row(children: <Widget>[
      const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Text(
          'item_added_to_cart'.tr,
          style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault),
        ),
      ),
    ]),
    mainButton: TextButton(
      onPressed: () {
        Get.closeAllSnackbars();
        Get.toNamed(RouteHelper.getCartRoute());
      },
      child: Text('view_cart'.tr, style: robotoMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
    ),
  ));
}
