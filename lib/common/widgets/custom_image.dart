import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';

class CustomImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;
  final Color? color;
  final int? cacheWidth;
  final int? cacheHeight;
  const CustomImage({super.key,
    required this.image, this.height, this.width, this.fit = BoxFit.cover, this.isNotification = false,
    this.placeholder = '', this.isHovered = false, this.color, this.cacheWidth, this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAxisHint = cacheWidth != null || cacheHeight != null;
    final int? decodeWidth = hasAxisHint ? cacheWidth : ImageCacheHelper.pixels(context, width ?? 100);
    final int? decodeHeight = hasAxisHint ? cacheHeight : ImageCacheHelper.pixels(context, height ?? 100);
    return AnimatedScale(
      scale: isHovered ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: CachedNetworkImage(
        color: color,
        imageUrl: kIsWeb ? '${AppConstants.baseUrl}/image-proxy?url=$image' : image, height: height, width: width, fit: fit,
        memCacheWidth: decodeWidth, memCacheHeight: decodeHeight,
        placeholder: (context, url) => Image.asset(
          placeholder.isNotEmpty ? placeholder : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
          height: height, width: width, fit: BoxFit.cover, color: color,
          cacheWidth: decodeWidth, cacheHeight: decodeHeight,
        ),
        errorWidget: (context, url, error) => Image.asset(
          placeholder.isNotEmpty ? placeholder : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
          height: height, width: width, fit: BoxFit.cover, color: color,
          cacheWidth: decodeWidth, cacheHeight: decodeHeight,
        ),
      ),
    );
  }
}
