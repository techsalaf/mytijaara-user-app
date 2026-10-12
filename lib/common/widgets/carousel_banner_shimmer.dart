import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Loading state for the banner carousels on the rental and ride-share homes.
///
/// Both were a bare `Container` carrying a colour and a margin but **no height**,
/// and nothing above them constrained one — inside a `SliverToBoxAdapter` that
/// resolves to zero, so the section drew nothing at all and the banner simply
/// appeared once it loaded.
///
/// This occupies the carousel's real footprint: the same `width * 0.8 * 0.45`
/// height both screens configure, the inset that `viewportFraction: 0.8` with
/// `padEnds: false` produces, and a row of dots for the page indicator.
class CarouselBannerShimmer extends StatelessWidget {
  /// Padding around the whole block, for a screen that wraps its carousel in
  /// some (rental adds a top gap; ride-share does not).
  final EdgeInsets padding;

  const CarouselBannerShimmer({super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final Color bar = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    return Padding(
      padding: padding,
      child: Column(children: [

        Shimmer(
          duration: const Duration(seconds: 2),
          child: Container(
            height: width * 0.8 * 0.45,
            // The first slide sits flush left and the next peeks in on the right,
            // which is what `viewportFraction: 0.8` looks like mid-scroll.
            margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: 60),
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Shimmer(
          duration: const Duration(seconds: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            for (int i = 0; i < 3; i++) Container(
              height: 6, width: i == 0 ? 16 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(3)),
            ),
          ]),
        ),
      ]),
    );
  }
}
