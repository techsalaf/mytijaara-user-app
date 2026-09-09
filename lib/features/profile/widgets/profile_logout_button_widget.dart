import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/widgets/logout_confirmation_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileLogoutButtonWidget extends StatelessWidget {
  const ProfileLogoutButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild on login/logout: both transitions call ProfileController.update()
    // (getUserInfo() on sign-in, clearUserInfo() on logout), so the button
    // re-reads the auth state and swaps the Sign in / Logout label + action.
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isLoggedIn = AuthHelper.isLoggedIn();

      return InkWell(
        onTap: () async {
          if (isLoggedIn) {
          showModalBottomSheet(
            context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
            builder: (con) => LogoutConfirmationBottomSheetWidget(
              onYesPressed: () async {
                Get.find<AuthController>().resetOtpView();
                Get.find<ProfileController>().clearUserInfo();
                Get.find<AuthController>().socialLogout();
                Get.find<CartController>().clearCartList();
                Get.find<FavouriteController>().removeFavourite();
                await Get.find<AuthController>().clearSharedData();
                Get.find<HomeController>().forcefullyNullCashBackOffers();
                if (Get.find<SplashController>().module != null) {
                  Get.find<TaxiCartController>().getCarCartList();
                }
                // Refresh after the token is actually cleared so the button
                // re-reads isLoggedIn() == false and shows "Sign in".
                Get.find<ProfileController>().update();
                Get.back();
                showCustomSnackBar('logout_successful'.tr, isError: false);
              },
            ),
          );
        } else {
          Get.find<FavouriteController>().removeFavourite();
          await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
          if (AuthHelper.isLoggedIn()) {
            await Get.find<FavouriteController>().getFavouriteList();
            Get.find<ProfileController>().getUserInfo();
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout, size: 18, color: Colors.red,
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Text(
              isLoggedIn ? 'logout'.tr : 'sign_in'.tr,
              style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ],
        ),
      ),
      );
    });
  }
}
