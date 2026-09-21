import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BrandItemWidget extends StatelessWidget {
  final bool showLabel;
  final bool showSubTitle;
  final String? image;
  final String? label;
  final String? subTitle;
  final Color? textColor;

  const BrandItemWidget({super.key, required this.label,  this.subTitle, this.textColor, this.image, required this.showLabel, required this.showSubTitle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Container(
          height: 72,
          width: 72,
          decoration: (showLabel || showSubTitle) ? BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).disabledColor.withAlpha(80)),
          ) : null,
          child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), child: CustomImage(image: image ?? '', fit: BoxFit.cover,)),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        if(showLabel) Text(label ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoBlack.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor),
        ),
        if(showSubTitle) Text(subTitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
      ]),
    );
  }
}
