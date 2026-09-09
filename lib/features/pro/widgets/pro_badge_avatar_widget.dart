import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/images.dart';

// Overlays a gold pro crown badge on the bottom-right of an avatar.
// Shown only when the user is a pro member and the config flag is enabled.
class ProBadgeAvatarWidget extends StatelessWidget {
  final Widget child;
  final double badgeSize;
  const ProBadgeAvatarWidget({super.key, required this.child, this.badgeSize = 24});

  @override
  Widget build(BuildContext context) {
    final bool isProUser = (Get.find<ProfileController>().userInfoModel?.proStatus ?? false) && (Get.find<SplashController>().configModel?.proMemberStatus ?? false);

    if (!isProUser) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            height: badgeSize,
            width: badgeSize,
            padding: EdgeInsets.all(badgeSize * 0.2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: Image.asset(Images.proPlanCrown, color: const Color(0xFFFFC107), fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
