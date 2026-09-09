import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/order/screens/my_order_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BottomNavigationWidget extends StatelessWidget {
  final double? padding;
  const BottomNavigationWidget({super.key, this.padding});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.all(padding ?? Dimensions.paddingSizeDefault),
      child: SizedBox(
        height: 62,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(
              color: Theme.of(context).hintColor.withValues(alpha: .25),
              blurRadius: 5, spreadRadius: 1, offset: const Offset(0,2),
            )],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _FoodModuleBottomNavigationItem(
                label: 'offers'.tr,
                icon: Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _iconColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.percent_rounded, size: 18, color: _iconColor),
                ),
              ),
              _FoodModuleBottomNavigationItem(
                label: 'orders'.tr,
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 24, color: _iconColor),
                onTap: () => Get.to(() => const MyOrderScreen()),
              ),
              _FoodModuleBottomNavigationItem(
                label: 'favourite'.tr,
                icon: const Icon(Icons.favorite_border_rounded, size: 24, color: _iconColor),
                onTap: () => Get.to(() => const FavouriteScreen()),
              ),
              _FoodModuleBottomNavigationItem(
                label: 'profile'.tr,
                icon: const _FoodModuleBottomNavigationProfileIcon(),
                onTap: () => Get.toNamed(RouteHelper.getRedesignProfileRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const Color _iconColor = Colors.black;

class _FoodModuleBottomNavigationItem extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  const _FoodModuleBottomNavigationItem({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 24, child: Center(child: icon)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                color: _iconColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodModuleBottomNavigationProfileIcon extends StatelessWidget {
  const _FoodModuleBottomNavigationProfileIcon();

  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<ProfileController>()) {
      return const _FoodModuleBottomNavigationGuestIcon();
    }

    return GetBuilder<ProfileController>(builder: (profileController) {
      final String image = profileController.userInfoModel != null && AuthHelper.isLoggedIn() ? profileController.userInfoModel!.imageFullUrl ?? '' : '';

      return Container(
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: image.isNotEmpty ? Border.all(color: Theme.of(context).disabledColor,): null,
        ) ,
        child: ClipOval(child: CustomImage(image: image, placeholder: Images.guestIcon, fit: BoxFit.cover,),),
      );
    });
  }
}

class _FoodModuleBottomNavigationGuestIcon extends StatelessWidget {
  const _FoodModuleBottomNavigationGuestIcon();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        Images.guestIcon,
        height: 24,
        width: 24,
        fit: BoxFit.cover,
      ),
    );
  }
}
