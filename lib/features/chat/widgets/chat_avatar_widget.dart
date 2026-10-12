import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/images.dart';

class ChatAvatarWidget extends StatelessWidget {
  final bool isAdmin;
  final String? imageUrl;
  final double size;

  const ChatAvatarWidget({super.key, required this.isAdmin, this.imageUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    // The admin is not a user, so there is no picture to fetch — the app stands for it.
    if(isAdmin) {
      return ClipOval(child: Image.asset(Images.logo, height: size, width: size, fit: BoxFit.contain));
    }

    return ClipOval(child: CustomImage(
      image: imageUrl ?? '', height: size, width: size, fit: BoxFit.cover,
      cacheWidth: ImageCacheHelper.pixels(context, size),
    ));
  }
}

// SUMMARY
// Round avatar for a chat counterpart. Shows the app logo when the other party is the
// admin and that party's own picture otherwise.
