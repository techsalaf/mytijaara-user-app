import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class SingleDealWidget extends StatelessWidget {
  final Color beginColor;
  final Color endColor;
  final String title;
  final String subTitle;
  final Function? onTap;
  final String? image;

  const SingleDealWidget({super.key, required this.title, required this.subTitle, required this.beginColor, required this.endColor, this.onTap, this.image});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: (){
        onTap?.call();
      },
      child: Container(
        height: 70,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall,),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [beginColor, endColor,],
          ),
        ),
        child: Row(
          children: [
            CustomAssetImageWidget(image ?? Images.fireIcon, height: 32, width: 32,),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black87),
                  ),
                  Text(
                    subTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
