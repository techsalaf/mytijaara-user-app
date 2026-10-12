import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BundleThumbnailAvatars extends StatelessWidget {
  final List<String> thumbnails;
  final int totalCount;
  static const double size = 48;

  const BundleThumbnailAvatars({super.key, required this.thumbnails, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final int cells = totalCount > 0 ? totalCount : (thumbnails.isEmpty ? 1 : thumbnails.length);
    final int shown = cells > 3 ? 3 : (cells < 1 ? 1 : cells);
    final int hidden = totalCount - shown;
    const double step = size * 0.62;

    Widget circle({required Widget child}) => Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardColor,
        border: Border.all(color: theme.cardColor, width: 2),
      ),
      child: ClipOval(child: child),
    );

    final List<Widget> circles = [
      for(int i = 0; i < shown; i++)
        Positioned(
          left: i * step,
          child: circle(child: CustomImage(image: i < thumbnails.length ? thumbnails[i] : '', fit: BoxFit.cover)),
        ),
      if(hidden > 0)
        Positioned(
          left: shown * step,
          child: circle(child: Container(
            color: theme.disabledColor.withValues(alpha: 0.12),
            alignment: Alignment.center,
            child: Text('+$hidden', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          )),
        ),
    ];

    final int circleCount = shown + (hidden > 0 ? 1 : 0);

    return SizedBox(
      width: size + (circleCount - 1) * step,
      height: size,
      child: Stack(children: circles),
    );
  }
}
