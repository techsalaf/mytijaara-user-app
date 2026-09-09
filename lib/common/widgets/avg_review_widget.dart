import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AvgReviewWidget extends StatelessWidget {
  final double avgRating;
  final int ratingCount;
  const AvgReviewWidget({super.key, required this.avgRating, required this.ratingCount});

  static bool showRating(double avgRating){
    if(avgRating <= 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if(!showRating(avgRating)) return const SizedBox();
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(
          '${(avgRating).toStringAsFixed(1)} ($ratingCount${(ratingCount > 5) ? '+ ${'reviews'.tr}' : ' review'.tr})',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
      ],
    );
  }
}