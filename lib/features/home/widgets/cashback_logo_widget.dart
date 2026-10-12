import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
class CashBackLogoWidget extends StatelessWidget {
  const CashBackLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const CustomAssetImageWidget(Images.cashBack, height: 60, width: 60),

        Positioned(
          top: 5, left: 7,
          child: Text('cash_back'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
        )
      ],
    );
  }
}
