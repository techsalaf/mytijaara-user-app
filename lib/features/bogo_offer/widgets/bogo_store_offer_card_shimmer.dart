import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BogoStoreOfferCardShimmer extends StatelessWidget {
  const BogoStoreOfferCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).shadowColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Shimmer(
                  child: Container(
                    width: 190, height: 90,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: color),
                  ),
                ),
                const Spacer(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Shimmer(child: Container(height: 12, width: 60, color: color)),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Shimmer(child: Container(height: 20, width: 80, color: color)),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(children: [
              Shimmer(child: ClipOval(child: Container(width: 40, height: 40, color: color))),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Shimmer(child: Container(height: 16, width: 140, color: color)),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Shimmer(child: Container(height: 12, width: 120, color: color)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
