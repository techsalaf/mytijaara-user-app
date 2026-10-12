import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BogoOfferItemShimmerWidget extends StatelessWidget {
  const BogoOfferItemShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).shadowColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Shimmer(
          child: Container(
            height: 120, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), color: color),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Shimmer(child: Container(height: 16, width: 160, color: color)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Shimmer(child: Container(height: 12, width: 110, color: color)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Shimmer(child: Container(height: 12, width: double.infinity, color: color)),
      ],
    );
  }
}
