import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_badge_avatar_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileHeaderCardWidget extends StatelessWidget {
  const ProfileHeaderCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isLoggedIn = AuthHelper.isLoggedIn();
      final bool isLoading = isLoggedIn && profileController.userInfoModel == null;
      final String imageUrl = (isLoggedIn && profileController.userInfoModel != null)
          ? (profileController.userInfoModel!.imageFullUrl ?? '')
          : '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeLarge,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusExtraLarge)),
          // boxShadow: lightShadow,
        ),
        child: Column(
          children: [
            _AvatarWithRating(imageUrl: imageUrl, isLoggedIn: isLoggedIn),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            isLoading
                ? const _ShimmerLine(width: 150)
                : Text(
                    isLoggedIn
                        ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}'
                        : 'guest_user'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            isLoading
                ? const _ShimmerLine(width: 100)
                : isLoggedIn
                    ? Text(
                        '${'joined'.tr}: ${profileController.userInfoModel?.createdAt != null ? DateConverter.containTAndZToUTCFormat(profileController.userInfoModel!.createdAt!) : ''}',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                            child: Text(
                              'for_more_personalised_and_smooth_experience'.tr,
                              textAlign: TextAlign.center,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          _LoginButton(profileController: profileController),
                        ],
                      ),
          ],
        ),
      );
    });
  }
}

class _AvatarWithRating extends StatelessWidget {
  final String imageUrl;
  final bool isLoggedIn;
  const _AvatarWithRating({required this.imageUrl, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final String fallback = isLoggedIn ? Images.guestIcon : Images.guestIcon;

    return ProBadgeAvatarWidget(
      badgeSize: 28,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(0.3),
        child: ClipOval(
          child: CustomImage(
            image: imageUrl,
            placeholder: fallback,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final ProfileController profileController;
  const _LoginButton({required this.profileController});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!ResponsiveHelper.isDesktop(context)) {
          await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
          if (AuthHelper.isLoggedIn()) {
            profileController.getUserInfo();
          }
        } else {
          Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: true, backFromThis: true)));
        }
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Text(
          'login_signup'.tr,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  const _ShimmerLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        height: 14,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
      ),
    );
  }
}
